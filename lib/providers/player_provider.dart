
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/music_scanner_service.dart';
import '../services/lyrics_service.dart';
import 'package:path/path.dart' as path;
import 'music_provider.dart';

/// 播放模式枚举
enum PlayMode {
  sequence,  // 顺序播放
  shuffle,   // 随机播放
  loop,      // 单曲循环
  listLoop,  // 列表循环
}

/// 播放列表来源枚举
enum PlaylistSource {
  all,       // 所有歌曲
  album,     // 专辑
  artist,    // 艺术家
  custom,    // 自定义播放列表
}

/// 播放器状态管理Provider
class PlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  MusicProvider? _musicProvider; // 添加MusicProvider引用

  // 播放状态
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _lastRecordedPosition = Duration.zero; // 上次记录的播放位置
  DateTime? _lastRecordTime; // 上次记录的时间

  // 播放列表
  List<MusicInfo> _playlist = [];
  List<MusicInfo> _originalPlaylist = []; // 保存原始播放列表
  int _currentIndex = 0;
  PlayMode _playMode = PlayMode.sequence;
  PlaylistSource _playlistSource = PlaylistSource.all;
  String? _sourceIdentifier; // 专辑名或艺术家名

  // 当前播放的音乐
  MusicInfo? _currentMusic;

  // 当前歌词
  String? _currentLyrics;

  // 倒计时相关
  int? _timerMinutes; // 用户设置的定时分钟数
  int? _originalTimerMinutes; // 保存原始设置的分钟数，用于恢复
  Timer? _timer; // 倒计时定时器
  DateTime? _timerStartTime; // 定时开始时间
  int? _pausedRemainingSeconds; // 暂停时保存的剩余秒数
  DateTime? _pausedStartTime; // 暂停时的开始时间

  // 订阅
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  PlayerProvider() {
    _initializePlayer();
  }

  /// 设置MusicProvider引用
  void setMusicProvider(MusicProvider musicProvider) {
    _musicProvider = musicProvider;
  }

  /// 初始化播放器
  Future<void> _initializePlayer() async {
    try {
      // 监听播放状态
      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
        notifyListeners();
      });

      // 监听播放位置
      _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
        // 计算自上次记录以来的播放时长
        if (_isPlaying && _lastRecordTime != null) {
          final now = DateTime.now();
          final timeDiff = now.difference(_lastRecordTime!).inSeconds;

          // 计算位置差，确保是正向播放（不是拖动进度条）
          final positionDiff = position.inSeconds - _lastRecordedPosition.inSeconds;

          // 只记录正向播放的时间，且不超过歌曲总时长
          if (positionDiff > 0 && positionDiff <= timeDiff) {
            // 计算实际播放时长（取位置差和时间差中较小的值，避免暂停时计入时间）
            final actualPlayedSeconds = positionDiff;

            // 更新当前歌曲的实际播放时长
            if (_currentMusic != null) {
              _currentMusic!.actualPlayDuration += actualPlayedSeconds;

              // 更新音乐列表中的记录
              final index = _playlist.indexWhere((m) => m.id == _currentMusic!.id);
              if (index != -1) {
                _playlist[index].actualPlayDuration = _currentMusic!.actualPlayDuration;
              }

              // 更新音乐提供者中的记录
              _musicProvider?.updateMusicActualPlayDuration(_currentMusic!.id, _currentMusic!.actualPlayDuration);
            }
          }

          _lastRecordTime = now;
          _lastRecordedPosition = position;
        }

        _position = position;
        notifyListeners();
      });

      // 监听音频时长
      _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
        _duration = duration;
        notifyListeners();
      });

      // 监听播放完成
      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        _onPlayerComplete();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _timer?.cancel(); // 取消倒计时定时器
    _audioPlayer.dispose();
    super.dispose();
  }

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  Duration get duration => _duration;
  Duration get position => _position;
  List<MusicInfo> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  PlaylistSource get playlistSource => _playlistSource;
  String? get sourceIdentifier => _sourceIdentifier;
  MusicInfo? get currentMusic => _currentMusic;
  String? get currentLyrics => _currentLyrics;
  
  // 倒计时相关getter
  int? get timerMinutes => _timerMinutes;
  set timerMinutes(int? value) {
    _timerMinutes = value;
    notifyListeners();
  }
  int? get originalTimerMinutes => _originalTimerMinutes;
  DateTime? get timerStartTime => _timerStartTime;
  int? get pausedRemainingSeconds => _pausedRemainingSeconds;

  /// 获取播放进度百分比
  double get progressPercent {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// 设置播放列表
  void setPlaylist({
    required List<MusicInfo> musicList,
    required PlaylistSource source,
    String? identifier,
    int startIndex = 0,
  }) {
    _playlist = List.from(musicList);
    _originalPlaylist = List.from(musicList); // 保存原始播放列表
    _playlistSource = source;
    _sourceIdentifier = identifier;
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    notifyListeners();
  }

  /// 播放指定索引的音乐
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) {
      debugPrint('播放索引超出范围: $index, 播放列表长度: ${_playlist.length}');
      return;
    }

    _currentIndex = index;
    final music = _playlist[index];
    _currentMusic = music;

    debugPrint('=== 开始播放 ===');
    debugPrint('索引: $index');
    debugPrint('标题: ${music.title}');
    debugPrint('艺术家: ${music.artist}');
    debugPrint('专辑: ${music.album}');
    debugPrint('文件路径: ${music.filePath}');
    debugPrint('时长: ${music.duration.inSeconds}秒');

    try {
      debugPrint('创建音频源...');
      final source = DeviceFileSource(music.filePath);
      debugPrint('音频源类型: ${source.runtimeType}');

      debugPrint('发送播放命令...');
      await _audioPlayer.play(source);

      debugPrint('播放命令已发送');
      _isPlaying = true;

      // 初始化记录时间和位置
      _lastRecordTime = DateTime.now();
      _lastRecordedPosition = Duration.zero;

      // 记录播放统计
      _musicProvider?.recordPlay(music);

      // 加载歌词
      _loadLyrics(music.filePath);

      notifyListeners();
    } catch (e) {
      debugPrint('=== 播放失败 ===');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('错误信息: $e');
      debugPrint('错误堆栈: ${StackTrace.current}');
    }
  }

  /// 播放指定音乐（通过音乐对象）
  Future<void> playMusic(MusicInfo music) async {
    // 在当前播放列表中查找该音乐
    final index = _playlist.indexWhere((m) => m.id == music.id);

    if (index != -1) {
      // 如果在播放列表中找到，直接播放
      await playAtIndex(index);
    } else {
      // 如果不在播放列表中，添加到列表并播放
      _playlist.add(music);
      _currentIndex = _playlist.length - 1;
      _currentMusic = music;

      debugPrint('=== 开始播放（新添加） ===');
      debugPrint('标题: ${music.title}');
      debugPrint('艺术家: ${music.artist}');
      debugPrint('专辑: ${music.album}');
      debugPrint('文件路径: ${music.filePath}');
      debugPrint('时长: ${music.duration.inSeconds}秒');

      try {
        final source = DeviceFileSource(music.filePath);
        await _audioPlayer.play(source);
        _isPlaying = true;

        // 初始化记录时间和位置
        _lastRecordTime = DateTime.now();
        _lastRecordedPosition = Duration.zero;

        // 记录播放统计
        _musicProvider?.recordPlay(music);

        // 加载歌词
        _loadLyrics(music.filePath);

        notifyListeners();
      } catch (e) {
        debugPrint('播放失败: $e');
      }
    }
  }

  /// 播放或暂停
  Future<void> togglePlayPause() async {
    if (_currentMusic == null) {
      if (_playlist.isNotEmpty) {
        await playAtIndex(0);
      }
      return;
    }

    if (_isPlaying) {
      // 暂停播放时，暂停倒计时（如果有倒计时）
      if (_timer != null) {
        pauseTimer();
      }
      await _audioPlayer.pause();
      // 暂停时清空记录时间，避免暂停时间被计入
      _lastRecordTime = null;
    } else {
      // 恢复播放时，恢复倒计时（如果有倒计时）
      await _audioPlayer.resume();
      if (_timer != null) {
        resumeTimer();
      }
      // 恢复播放时，重新初始化记录时间和位置
      _lastRecordTime = DateTime.now();
      _lastRecordedPosition = _position;
    }
  }

  /// 停止播放
  Future<void> stop({bool resetPosition = true}) async {
    await _audioPlayer.pause(); // 改为暂停而不是停止，以保留播放位置
    if (resetPosition) {
      _position = Duration.zero;
    }
    // 停止播放时，取消倒计时
    cancelTimer();
    notifyListeners();
  }

  /// 下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    int nextIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机播放模式：按照随机排序后的列表顺序播放
        nextIndex = (_currentIndex + 1) % _playlist.length;
        break;
      case PlayMode.loop:
        // 单曲循环模式：播放下一首后重新排序，使新歌曲置顶
        nextIndex = (_currentIndex + 1) % _playlist.length;
        await playAtIndex(nextIndex);
        _reorderPlaylistByMode();
        return;
      case PlayMode.listLoop:
        // 列表循环模式：播放下一首后重新排序，使新歌曲置顶
        nextIndex = (_currentIndex + 1) % _playlist.length;
        await playAtIndex(nextIndex);
        _reorderPlaylistByMode();
        return;
      default:
        // 顺序播放
        nextIndex = (_currentIndex + 1) % _playlist.length;
        // 顺序播放模式下，最后一首歌播放完后回到第一首
        break;
    }

    await playAtIndex(nextIndex);
  }

  /// 上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    int prevIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机播放模式：按照随机排序后的列表顺序播放
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        break;
      case PlayMode.loop:
        // 单曲循环模式：播放上一首后重新排序，使新歌曲置顶
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        await playAtIndex(prevIndex);
        _reorderPlaylistByMode();
        return;
      case PlayMode.listLoop:
        // 列表循环模式：播放上一首后重新排序，使新歌曲置顶
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        await playAtIndex(prevIndex);
        _reorderPlaylistByMode();
        return;
      default:
        // 顺序播放
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        if (prevIndex == _playlist.length - 1) {
          // 顺序播放模式下，到第一首就停止
          return;
        }
    }

    await playAtIndex(prevIndex);
  }

  /// 播放完成后的处理
  void _onPlayerComplete() {
    if (_playMode == PlayMode.loop) {
      // 单曲循环，重新播放当前歌曲
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.resume();
    } else {
      // 其他模式，播放下一首
      playNext();
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    // 跳转后更新记录位置，避免跳转的时间差被计入
    _lastRecordedPosition = position;
    _lastRecordTime = DateTime.now();
  }

  /// 跳转到指定百分比位置
  Future<void> seekToPercent(double percent) async {
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * percent).round(),
    );
    await seekTo(position);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// 切换播放模式
  void togglePlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(_playMode);
    _playMode = modes[(currentIndex + 1) % modes.length];
    _reorderPlaylistByMode();
    notifyListeners();
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    _reorderPlaylistByMode();
    notifyListeners();
  }

  /// 根据播放模式重新排序播放列表
  void _reorderPlaylistByMode() {
    if (_playlist.isEmpty || _currentMusic == null) return;

    // 保存当前播放的音乐
    final currentMusic = _currentMusic;

    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机打乱播放列表，但将当前播放的歌曲放在第一位
        final current = _playlist[_currentIndex];
        _playlist.removeAt(_currentIndex);
        _playlist.shuffle();
        _playlist.insert(0, current);
        _currentIndex = 0;
        break;
      case PlayMode.sequence:
        // 恢复原始顺序
        if (_originalPlaylist.isNotEmpty && currentMusic != null) {
          // 找到当前播放的音乐在原始列表中的位置
          final currentMusicIndex = _originalPlaylist.indexWhere((m) => m.id == currentMusic!.id);
          if (currentMusicIndex != -1) {
            _playlist = List.from(_originalPlaylist);
            _currentIndex = currentMusicIndex;
          }
        }
        break;
      case PlayMode.loop:
        // 单曲循环模式：将当前歌曲放在第一位，形成一个环
        if (_originalPlaylist.isNotEmpty && currentMusic != null) {
          // 找到当前播放的音乐在原始列表中的位置
          final currentMusicIndex = _originalPlaylist.indexWhere((m) => m.id == currentMusic!.id);
          if (currentMusicIndex != -1) {
            _playlist = List.from(_originalPlaylist);
            // 将当前歌曲及其之后的歌曲移到前面
            final beforeCurrent = _playlist.sublist(0, currentMusicIndex);
            final fromCurrent = _playlist.sublist(currentMusicIndex);
            _playlist = [...fromCurrent, ...beforeCurrent];
            _currentIndex = 0;
          }
        }
        break;
      case PlayMode.listLoop:
        // 列表循环模式：将当前歌曲放在第一位，形成一个环
        if (_originalPlaylist.isNotEmpty && currentMusic != null) {
          // 找到当前播放的音乐在原始列表中的位置
          final currentMusicIndex = _originalPlaylist.indexWhere((m) => m.id == currentMusic!.id);
          if (currentMusicIndex != -1) {
            _playlist = List.from(_originalPlaylist);
            // 将当前歌曲及其之后的歌曲移到前面
            final beforeCurrent = _playlist.sublist(0, currentMusicIndex);
            final fromCurrent = _playlist.sublist(currentMusicIndex);
            _playlist = [...fromCurrent, ...beforeCurrent];
            _currentIndex = 0;
          }
        }
        break;
    }

    // 重新设置当前播放的音乐
    _currentMusic = currentMusic;
  }

  /// 清空播放列表
  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = 0;
    _currentMusic = null;
    notifyListeners();
  }

  /// 添加音乐到播放列表
  void addToPlaylist(List<MusicInfo> musicList) {
    _playlist.addAll(musicList);
    _originalPlaylist.addAll(musicList); // 同步更新原始播放列表
    notifyListeners();
  }

  /// 从播放列表移除音乐
  void removeFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      final removedMusic = _playlist[index];
      _playlist.removeAt(index);
      // 从原始播放列表中也移除该音乐
      _originalPlaylist.removeWhere((m) => m.id == removedMusic.id);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        if (_currentIndex >= _playlist.length) {
          _currentIndex = _playlist.length - 1;
        }
        _currentMusic = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
      }
      notifyListeners();
    }
  }

  /// 移动播放列表中的歌曲
  void moveInPlaylist(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _playlist.length ||
        toIndex < 0 || toIndex >= _playlist.length ||
        fromIndex == toIndex) {
      return;
    }

    final music = _playlist.removeAt(fromIndex);
    _playlist.insert(toIndex, music);

    // 更新当前播放索引
    if (fromIndex == _currentIndex) {
      _currentIndex = toIndex;
    } else if (fromIndex < _currentIndex && toIndex >= _currentIndex) {
      _currentIndex--;
    } else if (fromIndex > _currentIndex && toIndex <= _currentIndex) {
      _currentIndex++;
    }

    notifyListeners();
  }

  /// 获取播放模式名称
  String getPlayModeName() {
    switch (_playMode) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.loop:
        return '单曲循环';
      case PlayMode.listLoop:
        return '列表循环';
    }
  }

  /// 加载歌词
  Future<void> _loadLyrics(String musicFilePath) async {
    try {
      final lyrics = await LyricsService.loadLyricsForMusic(musicFilePath);
      if (lyrics != null && lyrics.hasLyrics) {
        _currentLyrics = LyricsService.lyricsToLrc(lyrics);
        debugPrint('歌词加载成功，共 ${lyrics.lines.length} 行');
      } else {
        _currentLyrics = LyricsService.getDefaultLyrics();
        debugPrint('未找到歌词文件，使用默认歌词');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载歌词失败: $e');
      _currentLyrics = LyricsService.getDefaultLyrics();
      notifyListeners();
    }
  }

  /// 手动设置歌词
  void setLyrics(String lyrics) {
    _currentLyrics = lyrics;
    notifyListeners();
  }

  /// 清除歌词
  void clearLyrics() {
    _currentLyrics = null;
    notifyListeners();
  }

  /// 设置倒计时
  void setTimer(int minutes) {
    // 取消之前的定时器
    _timer?.cancel();
    
    _timerMinutes = minutes;
    _originalTimerMinutes = minutes;
    _timerStartTime = DateTime.now();
    _pausedRemainingSeconds = null;
    
    // 创建新的定时器
    _timer = Timer(Duration(minutes: minutes), () {
      // 定时时间到，停止播放但不重置位置
      stop(resetPosition: false);
      // 清除定时时间和开始时间
      _timerMinutes = null;
      _originalTimerMinutes = null;
      _timerStartTime = null;
      notifyListeners();
    });
    
    notifyListeners();
  }

  /// 取消倒计时
  void cancelTimer() {
    _timer?.cancel();
    _timerMinutes = null;
    _originalTimerMinutes = null;
    _timerStartTime = null;
    _pausedRemainingSeconds = null;
    _pausedStartTime = null;
    notifyListeners();
  }

  /// 暂停倒计时
  void pauseTimer() {
    if (_timerStartTime != null && _originalTimerMinutes != null) {
      final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      final totalSeconds = _originalTimerMinutes! * 60;
      _pausedRemainingSeconds = totalSeconds - elapsed;
      _pausedStartTime = _timerStartTime; // 保存暂停时的开始时间
      _timerStartTime = null;
      _timer?.cancel();
      notifyListeners();
    }
  }

  /// 恢复倒计时
  void resumeTimer() {
    if (_pausedRemainingSeconds != null && _pausedRemainingSeconds! > 0) {
      // 取消之前的定时器
      _timer?.cancel();

      // 保存剩余的秒数
      final remainingSeconds = _pausedRemainingSeconds!;

      // 使用暂停时的开始时间来计算新的开始时间
      _timerStartTime = _pausedStartTime;
      _pausedRemainingSeconds = null;
      _pausedStartTime = null;

      // 创建新的定时器，使用剩余的秒数而不是分钟
      _timer = Timer(Duration(seconds: remainingSeconds), () {
        // 定时时间到，停止播放但不重置位置
        stop(resetPosition: false);
        // 清除定时时间和开始时间
        _timerMinutes = null;
        _originalTimerMinutes = null;
        _timerStartTime = null;
        notifyListeners();
      });

      notifyListeners();
    }
  }
}
