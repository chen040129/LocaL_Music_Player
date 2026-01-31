
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/music_scanner_service.dart';

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

  // 播放状态
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // 播放列表
  List<MusicInfo> _playlist = [];
  int _currentIndex = 0;
  PlayMode _playMode = PlayMode.sequence;
  PlaylistSource _playlistSource = PlaylistSource.all;
  String? _sourceIdentifier; // 专辑名或艺术家名

  // 当前播放的音乐
  MusicInfo? _currentMusic;

  // 订阅
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  PlayerProvider() {
    _initializePlayer();
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
      notifyListeners();
    } catch (e) {
      debugPrint('=== 播放失败 ===');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('错误信息: $e');
      debugPrint('错误堆栈: ${StackTrace.current}');
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
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  /// 下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    int nextIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机选择下一首，但不能是当前这首
        if (_playlist.length > 1) {
          do {
            nextIndex = (DateTime.now().millisecondsSinceEpoch) % _playlist.length;
          } while (nextIndex == _currentIndex);
        } else {
          nextIndex = 0;
        }
        break;
      case PlayMode.loop:
        // 单曲循环，不切换
        return;
      default:
        // 顺序播放或列表循环
        nextIndex = (_currentIndex + 1) % _playlist.length;
        if (_playMode == PlayMode.sequence && nextIndex == 0) {
          // 顺序播放模式下，到最后一首就停止
          return;
        }
    }

    await playAtIndex(nextIndex);
  }

  /// 上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    int prevIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        // 随机选择上一首
        if (_playlist.length > 1) {
          do {
            prevIndex = (DateTime.now().millisecondsSinceEpoch) % _playlist.length;
          } while (prevIndex == _currentIndex);
        } else {
          prevIndex = 0;
        }
        break;
      case PlayMode.loop:
        // 单曲循环，不切换
        return;
      default:
        // 顺序播放或列表循环
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        if (_playMode == PlayMode.sequence && prevIndex == _playlist.length - 1) {
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
    notifyListeners();
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    notifyListeners();
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
    notifyListeners();
  }

  /// 从播放列表移除音乐
  void removeFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
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
}
