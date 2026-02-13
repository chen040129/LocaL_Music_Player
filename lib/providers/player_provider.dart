
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/music_scanner_service.dart';
import '../services/lyrics_service.dart';
import '../services/storage_service.dart';
import 'package:path/path.dart' as path;
import 'music_provider.dart';
import 'settings_provider.dart';

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
  SettingsProvider? _settingsProvider; // 添加SettingsProvider引用
  final StorageService _storageService = StorageService(); // 添加StorageService实例

  // 播放状态
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _lastRecordedPosition = Duration.zero; // 上次记录的播放位置
  DateTime? _lastRecordTime; // 上次记录的时间
  int _totalPlayDuration = 0; // 总播放时长（秒）

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

  /// 设置SettingsProvider引用
  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  /// 恢复播放进度
  /// [autoPlay] 是否自动播放，默认为false（暂停状态）
  Future<void> restorePlayProgress({bool autoPlay = false}) async {
    if (!(_settingsProvider?.savePlayProgress ?? true)) {
      debugPrint('未启用播放进度保存功能');
      return;
    }

    final progressData = await _storageService.loadPlayProgress();
    if (progressData == null) {
      debugPrint('未找到播放进度');
      return;
    }

    final musicId = progressData['musicId'] as String;
    final positionMs = progressData['position'] as int;
    final filePath = progressData['filePath'] as String;

    // 恢复播放列表
    if (progressData.containsKey('playlistMusicIds') &&
        progressData.containsKey('currentIndex')) {
      final playlistMusicIds = progressData['playlistMusicIds'] as List<dynamic>;
      final currentIndex = progressData['currentIndex'] as int;

      // 恢复播放模式
      if (progressData.containsKey('playMode')) {
        final playModeIndex = progressData['playMode'] as int;
        _playMode = PlayMode.values[playModeIndex];
      }

      // 恢复播放来源
      if (progressData.containsKey('playlistSource')) {
        final playlistSourceName = progressData['playlistSource'] as String;
        _playlistSource = PlaylistSource.values.firstWhere(
          (source) => source.name == playlistSourceName,
          orElse: () => PlaylistSource.custom,
        );
        _sourceIdentifier = progressData['sourceIdentifier'] as String?;
      }

      // 重建播放列表
      final allMusic = _musicProvider?.musicList ?? [];
      final restoredPlaylist = <MusicInfo>[];

      for (final musicId in playlistMusicIds) {
        try {
          final music = allMusic.firstWhere((m) => m.id == musicId);
          restoredPlaylist.add(music);
        } catch (e) {
          // 如果找不到某首歌曲，跳过它
          debugPrint('未找到歌曲ID: $musicId');
        }
      }

      if (restoredPlaylist.isNotEmpty) {
        _playlist = restoredPlaylist;
        _originalPlaylist = List.from(restoredPlaylist);

        // 确保当前索引在有效范围内
        _currentIndex = currentIndex.clamp(0, _playlist.length - 1);

        // 恢复播放位置
        final position = Duration(milliseconds: positionMs);
        await playAtIndex(_currentIndex, startPosition: position, autoPlay: autoPlay);
        debugPrint('已恢复播放进度: ${_playlist[_currentIndex].title} - ${position.inSeconds}秒');
        debugPrint('已恢复播放列表，共 ${_playlist.length} 首歌曲');
        return;
      }
    }

    // 如果没有保存的播放列表，或者恢复失败，使用旧的逻辑
    // 在音乐列表中查找该音乐
    final allMusic = _musicProvider?.musicList ?? [];
    MusicInfo? music;
    
    try {
      music = allMusic.firstWhere(
        (m) => m.id == musicId || m.filePath == filePath,
      );
    } catch (e) {
      // 如果找不到，尝试通过文件名匹配
      try {
        music = allMusic.firstWhere(
          (m) => path.basename(m.filePath) == path.basename(filePath),
        );
      } catch (e) {
        debugPrint('未找到上次播放的音乐');
        return;
      }
    }

    // 在当前播放列表中查找该音乐
    if (music == null) {
      debugPrint('未找到上次播放的音乐');
      return;
    }
    
    final index = _playlist.indexWhere((m) => m.id == music!.id);
    if (index != -1) {
      // 如果在播放列表中，直接恢复播放
      final position = Duration(milliseconds: positionMs);
      await playAtIndex(index, startPosition: position, autoPlay: autoPlay);
      debugPrint('已恢复播放进度: ${music!.title} - ${position.inSeconds}秒');
    } else {
      // 如果不在播放列表中，添加到列表并恢复播放
      _playlist.add(music!);
      _currentIndex = _playlist.length - 1;
      final position = Duration(milliseconds: positionMs);
      await playAtIndex(_currentIndex, startPosition: position, autoPlay: autoPlay);
      debugPrint('已恢复播放进度(新添加): ${music!.title} - ${position.inSeconds}秒');
    }
  }

  /// 初始化播放器
  Future<void> _initializePlayer() async {
    try {
      // 设置默认音量
      await _audioPlayer.setVolume(0.7);

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
          final timeDiff = now.difference(_lastRecordTime!).inMilliseconds;

          // 计算位置差，确保是正向播放（不是拖动进度条）
          final positionDiff = position.inMilliseconds - _lastRecordedPosition.inMilliseconds;

          // 只记录正向播放的时间，且不超过歌曲总时长
          if (positionDiff > 0 && positionDiff <= timeDiff) {
            // 计算实际播放时长（取位置差和时间差中较小的值，避免暂停时计入时间）
            final actualPlayedSeconds = (positionDiff / 1000).round();

            // 更新总播放时长
            _totalPlayDuration += actualPlayedSeconds;

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

          // 每秒更新一次记录时间和位置，而不是每次位置变化都更新
          if (timeDiff >= 1000) {
            _lastRecordTime = now;
            _lastRecordedPosition = position;
          }
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
    _savePlayProgressOnExit(); // 保存播放进度
    super.dispose();
  }

  /// 保存播放进度
  Future<void> savePlayProgress() async {
    if (_settingsProvider?.savePlayProgress ?? true && _currentMusic != null) {
      try {
        await _storageService.savePlayProgress(
          musicId: _currentMusic!.id,
          position: _position,
          filePath: _currentMusic!.filePath,
          playlistMusicIds: _playlist.map((m) => m.id).toList(),
          currentIndex: _currentIndex,
          playlistSource: _playlistSource.name,
          sourceIdentifier: _sourceIdentifier,
          playMode: _playMode.index,
        );
      } catch (e) {
        debugPrint('保存播放进度失败: $e');
      }
    }
  }

  /// 退出时保存播放进度
  Future<void> _savePlayProgressOnExit() async {
    if (_settingsProvider?.savePlayProgress ?? true && _currentMusic != null) {
      await _storageService.savePlayProgress(
        musicId: _currentMusic!.id,
        position: _position,
        filePath: _currentMusic!.filePath,
        playlistMusicIds: _playlist.map((m) => m.id).toList(),
        currentIndex: _currentIndex,
        playlistSource: _playlistSource.name,
        sourceIdentifier: _sourceIdentifier,
        playMode: _playMode.index,
      );
    }
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
  int get totalPlayDuration => _totalPlayDuration;
  
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
    bool moveToTop = false, // 是否将选中的歌曲移到顶部
  }) {
    _originalPlaylist = List.from(musicList); // 保存原始播放列表
    _playlistSource = source;
    _sourceIdentifier = identifier;

    // 根据播放模式生成播放列表
    _generatePlaylistByMode(startIndex: startIndex, moveToTop: moveToTop);

    notifyListeners();
  }

  /// 根据播放模式生成播放列表
  void _generatePlaylistByMode({int startIndex = 0, bool moveToTop = false}) {
    if (_originalPlaylist.isEmpty) return;

    debugPrint('=== _generatePlaylistByMode ===');
    debugPrint('播放模式: $_playMode');
    debugPrint('startIndex: $startIndex');
    debugPrint('moveToTop: $moveToTop');
    debugPrint('原始播放列表: ${_originalPlaylist.map((m) => m.title).toList()}');

    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机播放模式：将选中的歌曲移到顶部，其余随机排序
        _playlist = List.from(_originalPlaylist);
        _currentIndex = startIndex.clamp(0, _playlist.length - 1);

        // 确保选中的歌曲被正确移到顶部
        if (_currentIndex >= 0) {
          final current = _playlist[_currentIndex];
          _playlist.removeAt(_currentIndex);
          _playlist.shuffle();
          _playlist.insert(0, current);
          _currentIndex = 0;
        }
        break;

      case PlayMode.sequence:
        // 顺序播放模式：将当前歌曲及其之后的歌曲移到前面，形成一个环
        // 注意：顺序播放模式下忽略 moveToTop 参数，始终按照原始顺序播放
        _playlist = List.from(_originalPlaylist);
        _currentIndex = startIndex.clamp(0, _playlist.length - 1);

        debugPrint('当前索引: $_currentIndex');
        debugPrint('当前歌曲: ${_playlist[_currentIndex].title}');

        // 将当前歌曲及其之后的歌曲移到前面
        final beforeCurrent = _playlist.sublist(0, _currentIndex);
        final fromCurrent = _playlist.sublist(_currentIndex);
        _playlist = [...fromCurrent, ...beforeCurrent];
        _currentIndex = 0;

        debugPrint('beforeCurrent: ${beforeCurrent.map((m) => m.title).toList()}');
        debugPrint('fromCurrent: ${fromCurrent.map((m) => m.title).toList()}');
        debugPrint('最终播放列表: ${_playlist.map((m) => m.title).toList()}');
        break;

      case PlayMode.listLoop:
        // 列表循环模式：将当前歌曲及其之后的歌曲移到前面，形成一个环
        _playlist = List.from(_originalPlaylist);
        _currentIndex = startIndex.clamp(0, _playlist.length - 1);

        debugPrint('列表循环模式 - 当前索引: $_currentIndex');
        debugPrint('列表循环模式 - 当前歌曲: ${_playlist[_currentIndex].title}');

        // 将当前歌曲及其之后的歌曲移到前面
        final beforeCurrent = _playlist.sublist(0, _currentIndex);
        final fromCurrent = _playlist.sublist(_currentIndex);
        _playlist = [...fromCurrent, ...beforeCurrent];
        _currentIndex = 0;

        debugPrint('列表循环模式 - beforeCurrent: ${beforeCurrent.map((m) => m.title).toList()}');
        debugPrint('列表循环模式 - fromCurrent: ${fromCurrent.map((m) => m.title).toList()}');
        debugPrint('列表循环模式 - 最终播放列表: ${_playlist.map((m) => m.title).toList()}');
        break;

      case PlayMode.loop:
        // 单曲循环模式：将选中的歌曲移到顶部，保持原始顺序
        _playlist = List.from(_originalPlaylist);
        _currentIndex = startIndex.clamp(0, _playlist.length - 1);

        if (_currentIndex > 0) {
          final current = _playlist[_currentIndex];
          _playlist.removeAt(_currentIndex);
          _playlist.insert(0, current);
          _currentIndex = 0;
        }
        break;
    }

    debugPrint('最终播放列表: ${_playlist.map((m) => m.title).toList()}');
    debugPrint('=== _generatePlaylistByMode 结束 ===');
  }

  /// 播放指定索引的音乐
  /// [autoPlay] 是否自动播放，默认为true
  Future<void> playAtIndex(int index, {Duration? startPosition, bool autoPlay = true}) async {
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
    if (startPosition != null) {
      debugPrint('起始位置: ${startPosition.inSeconds}秒');
    }

    try {
      debugPrint('创建音频源...');

      // 检查文件是否存在
      final file = File(music.filePath);
      if (!await file.exists()) {
        debugPrint('=== 播放失败 ===');
        debugPrint('错误: 文件不存在');
        debugPrint('文件路径: ${music.filePath}');
        return;
      }

      // 检查文件是否可读
      try {
        await file.openRead().first;
      } catch (e) {
        debugPrint('=== 播放失败 ===');
        debugPrint('错误: 文件无法读取');
        debugPrint('文件路径: ${music.filePath}');
        debugPrint('读取错误: $e');
        return;
      }

      final source = DeviceFileSource(music.filePath);
      debugPrint('音频源类型: ${source.runtimeType}');

      debugPrint('发送播放命令...');

      // 初始化记录时间和位置（在播放前设置）
      _lastRecordTime = DateTime.now();
      _lastRecordedPosition = startPosition ?? Duration.zero;

      // 应用淡入淡出效果
      if (_settingsProvider?.enableFadeEffect ?? true) {
        final fadeDuration = _settingsProvider?.fadeDuration ?? 2.0;
        await _audioPlayer.setVolume(0);
        if (autoPlay) {
          await _audioPlayer.play(source);
        } else {
          await _audioPlayer.setSource(source);
        }
        if (startPosition != null) {
          await _audioPlayer.seek(startPosition);
        }
        await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
            ? (_settingsProvider!.defaultVolume / 100) 
            : 0.7);
      } else {
        if (autoPlay) {
          await _audioPlayer.play(source);
        } else {
          await _audioPlayer.setSource(source);
        }
        await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
            ? (_settingsProvider!.defaultVolume / 100) 
            : 0.7);
      }

      debugPrint('播放命令已发送');
      _isPlaying = autoPlay;

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
  /// [autoPlay] 是否自动播放，默认为true
  Future<void> playMusic(MusicInfo music, {Duration? startPosition, bool autoPlay = true}) async {
    // 在当前播放列表中查找该音乐
    final index = _playlist.indexWhere((m) => m.id == music.id);

    if (index != -1) {
      // 如果在播放列表中找到，直接播放
      await playAtIndex(index, startPosition: startPosition, autoPlay: autoPlay);
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
      if (startPosition != null) {
        debugPrint('起始位置: ${startPosition.inSeconds}秒');
      }

      try {
        final source = DeviceFileSource(music.filePath);

        // 初始化记录时间和位置（在播放前设置）
        _lastRecordTime = DateTime.now();
        _lastRecordedPosition = startPosition ?? Duration.zero;

        // 应用淡入淡出效果
        if (_settingsProvider?.enableFadeEffect ?? true) {
          final fadeDuration = _settingsProvider?.fadeDuration ?? 2.0;
          await _audioPlayer.setVolume(0);
          await _audioPlayer.play(source);
          await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
              ? (_settingsProvider!.defaultVolume / 100) 
              : 0.7);
        } else {
          await _audioPlayer.play(source);
          if (startPosition != null) {
            await _audioPlayer.seek(startPosition);
          }
          await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
              ? (_settingsProvider!.defaultVolume / 100) 
              : 0.7);
        }

        _isPlaying = autoPlay;

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

      // 应用淡出效果
      if (_settingsProvider?.enableFadeEffect ?? true) {
        final fadeDuration = _settingsProvider?.fadeDuration ?? 2.0;
        await _audioPlayer.setVolume(0);
        await _audioPlayer.pause();
        await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
            ? (_settingsProvider!.defaultVolume / 100) 
            : 0.7);
      } else {
        await _audioPlayer.pause();
      }

      // 暂停时清空记录时间，避免暂停时间被计入
      _lastRecordTime = null;
    } else {
      // 恢复播放时，恢复倒计时（如果有倒计时）

      // 应用淡入效果
      if (_settingsProvider?.enableFadeEffect ?? true) {
        final fadeDuration = _settingsProvider?.fadeDuration ?? 2.0;
        await _audioPlayer.setVolume(0);
        await _audioPlayer.resume();
        await _audioPlayer.setVolume(_settingsProvider?.defaultVolume != null 
            ? (_settingsProvider!.defaultVolume / 100) 
            : 0.7);
      } else {
        await _audioPlayer.resume();
      }

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
      case PlayMode.sequence:
      case PlayMode.listLoop:
        // 随机、顺序、列表循环模式：按照当前播放列表顺序播放下一首
        nextIndex = (_currentIndex + 1) % _playlist.length;
        break;
      case PlayMode.loop:
        // 单曲循环模式：重新播放当前歌曲
        nextIndex = _currentIndex;
        break;
    }

    await playAtIndex(nextIndex);
  }

  /// 将指定歌曲插入到下一首播放
  void playNextAsNext(MusicInfo music) {
    if (_playlist.isEmpty) {
      // 如果播放列表为空，直接播放这首歌
      setPlaylist(
        musicList: [music],
        source: PlaylistSource.custom,
        identifier: 'next',
        startIndex: 0,
      );
      return;
    }

    // 将歌曲插入到当前播放歌曲的下一位置
    final insertIndex = _currentIndex + 1;
    _playlist.insert(insertIndex, music);
    notifyListeners();

    // 显示提示
    debugPrint('已将 "${music.title}" 添加到下一首播放');
  }

  /// 上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    int prevIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
      case PlayMode.sequence:
      case PlayMode.listLoop:
        // 随机、顺序、列表循环模式：按照当前播放列表顺序播放上一首
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        break;
      case PlayMode.loop:
        // 单曲循环模式：重新播放当前歌曲
        prevIndex = _currentIndex;
        break;
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
      // 检查是否启用自动播放下一首
      if (_settingsProvider?.autoPlayNext ?? true) {
        // 其他模式，播放下一首
        playNext();
      } else {
        // 不自动播放下一首，停止播放
        _isPlaying = false;
        notifyListeners();
      }
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
        // 随机播放模式：将当前播放的歌曲放在第一位，其余随机排序
        final current = _playlist[_currentIndex];
        _playlist.removeAt(_currentIndex);
        _playlist.shuffle();
        _playlist.insert(0, current);
        _currentIndex = 0;
        break;

      case PlayMode.sequence:
        // 顺序播放模式：将当前歌曲及其之后的歌曲移到前面，形成一个环
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
      case PlayMode.loop:
        // 列表循环、单曲循环模式：从原始列表重新生成，当前歌曲置顶
        if (_originalPlaylist.isNotEmpty && currentMusic != null) {
          // 找到当前播放的音乐在原始列表中的位置
          final currentMusicIndex = _originalPlaylist.indexWhere((m) => m.id == currentMusic!.id);
          if (currentMusicIndex != -1) {
            _playlist = List.from(_originalPlaylist);
            // 将当前歌曲移到顶部
            final current = _playlist[currentMusicIndex];
            _playlist.removeAt(currentMusicIndex);
            _playlist.insert(0, current);
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

  /// 重置总播放时长
  void resetTotalPlayDuration() {
    _totalPlayDuration = 0;
    notifyListeners();
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
