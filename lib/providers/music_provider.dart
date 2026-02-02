
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lpinyin/lpinyin.dart';
import '../services/music_scanner_service.dart';
import '../services/storage_service.dart';

/// 音乐状态管理Provider
class MusicProvider with ChangeNotifier {
  static final MusicScannerService _scannerService = MusicScannerService();
  final StorageService _storageService = StorageService();
  List<MusicInfo> _musicList = [];
  
  // 拼音缓存映射
  final Map<String, String> _pinyinCache = {};
  bool _isScanning = false;
  String _scanStatus = '未开始扫描';
  int _scannedCount = 0;
  List<String> _scannedFolders = [];
  bool _hasInitialized = false;
  double _scanProgress = 0.0;
  StreamSubscription<double>? _progressSubscription;
  final StreamController<String> _scanLogController = StreamController<String>.broadcast();
  String _currentScanLog = '';
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  StreamSubscription<Map<String, dynamic>>? _coverColorSubscription;
  Timer? _saveTimer; // 用于防抖保存数据的定时器

  MusicProvider() {
    debugPrint('MusicProvider初始化');
    // 监听扫描进度流
    _progressSubscription = _scannerService.progressStream.listen((progress) {
      debugPrint('MusicProvider收到进度更新: ${(progress * 100).toStringAsFixed(1)}%');
      _scanProgress = progress;
      notifyListeners();
    });

    // 监听扫描日志流
    _scannerService.logStream.listen((log) {
      _addScanLog(log);
    });

    // 监听封面颜色更新流
    _coverColorSubscription = _scannerService.coverColorStream.listen((data) {
      final musicId = data['musicId'] as String;
      final coverColor = data['coverColor'] as int?;
      updateMusicCoverColor(musicId, coverColor);
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _coverColorSubscription?.cancel();
    _saveTimer?.cancel();
    _pinyinCache.clear();
    super.dispose();
  }
  
  /// 获取拼音（带缓存）
  String _getPinyin(String text) {
    if (_pinyinCache.containsKey(text)) {
      return _pinyinCache[text]!;
    }
    final pinyin = PinyinHelper.getPinyinE(text, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
    _pinyinCache[text] = pinyin;
    return pinyin;
  }

  /// 获取音乐列表
  List<MusicInfo> get musicList => List.unmodifiable(_musicList);

  /// 获取专辑列表
  List<String> get albums {
    final albumSet = <String>{};
    for (final music in _musicList) {
      if (music.album.isNotEmpty && music.album != '未知专辑') {
        albumSet.add(music.album);
      }
    }
    final albumList = albumSet.toList();
    // 使用缓存的拼音映射进行排序
    albumList.sort((a, b) {
      final aPinyin = _getPinyin(a);
      final bPinyin = _getPinyin(b);
      return aPinyin.compareTo(bPinyin);
    });
    return albumList;
  }

  /// 获取艺术家列表
  List<String> get artists {
    final artistSet = <String>{};
    for (final music in _musicList) {
      if (music.artist.isNotEmpty && music.artist != '未知艺术家') {
        artistSet.add(music.artist);
      }
    }
    final artistList = artistSet.toList();
    // 使用缓存的拼音映射进行排序
    artistList.sort((a, b) {
      final aPinyin = _getPinyin(a);
      final bPinyin = _getPinyin(b);
      return aPinyin.compareTo(bPinyin);
    });
    return artistList;
  }

  /// 获取音质统计
  Map<String, Map<String, int>> get qualityStats {
    final stats = <String, Map<String, int>>{};
    for (final music in _musicList) {
      final quality = music.quality ?? '未知';
      if (!stats.containsKey(quality)) {
        stats[quality] = {'count': 0, 'size': 0};
      }
      stats[quality]!['count'] = (stats[quality]!['count'] ?? 0) + 1;
      stats[quality]!['size'] = (stats[quality]!['size'] ?? 0) + music.fileSize;
    }
    return stats;
  }

  /// 获取总播放时长（秒）- 基于实际播放次数
  int get totalDuration {
    return _musicList.fold<int>(0, (sum, music) => sum + music.duration.inSeconds * music.playCount);
  }

  /// 获取总播放次数
  int get totalPlayCount {
    return _musicList.fold<int>(0, (sum, music) => sum + music.playCount);
  }

  /// 获取所有歌曲总时长（秒）
  int get allSongsDuration {
    return _musicList.fold<int>(0, (sum, music) => sum + music.duration.inSeconds);
  }

  /// 获取总文件大小
  int get totalFileSize {
    return _musicList.fold<int>(0, (sum, music) => sum + music.fileSize);
  }

  /// 获取年份统计
  Map<int, int> get yearStats {
    final stats = <int, int>{};
    for (final music in _musicList) {
      final year = music.year > 0 ? music.year : 0;
      stats[year] = (stats[year] ?? 0) + 1;
    }
    return stats;
  }

  /// 获取格式统计
  Map<String, int> get formatStats {
    final stats = <String, int>{};
    for (final music in _musicList) {
      final extension = music.filePath.split('.').last.toLowerCase();
      stats[extension] = (stats[extension] ?? 0) + 1;
    }
    return stats;
  }

  /// 根据专辑获取音乐列表
  List<MusicInfo> getMusicByAlbum(String album) {
    return _musicList.where((music) => music.album == album).toList();
  }

  /// 根据艺术家获取音乐列表
  List<MusicInfo> getMusicByArtist(String artist) {
    return _musicList.where((music) => music.artist == artist).toList();
  }

  /// 是否正在扫描
  bool get isScanning => _isScanning;

  /// 扫描状态
  String get scanStatus => _scanStatus;

  /// 已扫描的歌曲数量
  int get scannedCount => _scannedCount;

  /// 扫描进度
  double get scanProgress => _scanProgress;

  /// 已扫描的文件夹列表
  List<String> get scannedFolders => List.unmodifiable(_scannedFolders);

  /// 扫描日志流
  Stream<String> get scanLogStream => _scanLogController.stream;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 加载进度
  double get loadingProgress => _loadingProgress;

  /// 添加扫描日志
  void _addScanLog(String log) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _currentScanLog = '[$timestamp] $log\n$_currentScanLog';
    if (!_scanLogController.isClosed) {
      _scanLogController.add(_currentScanLog);
    }
  }

  /// 扫描指定目录中的音乐文件
  Future<void> scanDirectory(String directoryPath) async {
    if (_isScanning) {
      debugPrint('正在扫描中，请勿重复操作');
      return;
    }

    try {
      _isScanning = true;
      _scanStatus = '正在扫描...';
      _scanProgress = 0.0;
      _addScanLog('开始扫描目录: $directoryPath');
      notifyListeners();
      
      // 开始扫描
      debugPrint('开始扫描目录: $directoryPath');
      final scannedMusic = await _scannerService.scanDirectory(directoryPath);

      // 检查并添加不重复的音乐
      int addedCount = 0;
      for (final music in scannedMusic) {
        if (!_musicList.any((m) => m.filePath == music.filePath)) {
          _musicList.add(music);
          addedCount++;
          _addScanLog('添加音乐: ${music.title} - ${music.artist}');
        }
      }

      _isScanning = false;
      _scanStatus = '扫描完成';
      _scannedCount = addedCount;
      _addScanLog('扫描完成，共找到 ${scannedMusic.length} 首音乐，新增 $addedCount 首');
      // 检查文件夹是否已存在，避免重复添加
      if (!_scannedFolders.contains(directoryPath)) {
        _scannedFolders.add(directoryPath);
      }

      // 自动保存到本地
      await saveData();

      notifyListeners();

      debugPrint('扫描完成，共找到 ${scannedMusic.length} 首音乐，新增 $addedCount 首');
    } catch (e) {
      _isScanning = false;
      _scanStatus = '扫描失败';
      notifyListeners();
      debugPrint('扫描音乐文件失败: $e');
      rethrow;
    }
  }

  /// 移除文件夹
  Future<void> removeFolder(int index) async {
    final folder = _scannedFolders[index];
    _scannedFolders.removeAt(index);

    // 移除该文件夹中的所有音乐
    _musicList.removeWhere((music) => music.filePath.startsWith(folder));

    // 自动保存到本地
    await saveData();

    notifyListeners();
  }

  /// 清空所有音乐
  Future<void> clearAll() async {
    _musicList.clear();
    _scannedFolders.clear();
    _scannedCount = 0;
    _scanStatus = '未开始扫描';

    // 清除本地数据
    await clearLocalData();

    notifyListeners();
  }

  /// 根据ID获取音乐
  MusicInfo? getMusicById(String id) {
    try {
      return _musicList.firstWhere((music) => music.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新音乐封面颜色
  void updateMusicCoverColor(String musicId, int? coverColor) {
    try {
      final index = _musicList.indexWhere((music) => music.id == musicId);
      if (index != -1) {
        final updatedMusic = MusicInfo(
          id: _musicList[index].id,
          filePath: _musicList[index].filePath,
          title: _musicList[index].title,
          artist: _musicList[index].artist,
          album: _musicList[index].album,
          coverArt: _musicList[index].coverArt,
          duration: _musicList[index].duration,
          quality: _musicList[index].quality,
          trackNumber: _musicList[index].trackNumber,
          year: _musicList[index].year,
          fileSize: _musicList[index].fileSize,
          playCount: _musicList[index].playCount,
          playHistory: _musicList[index].playHistory,
          coverColor: coverColor,
        );
        _musicList[index] = updatedMusic;
        notifyListeners();
        debugPrint('成功更新音乐封面颜色: ${updatedMusic.title}');
      }
    } catch (e) {
      debugPrint('更新音乐封面颜色失败: $e');
    }
  }

  /// 初始化，从本地加载数据
  Future<void> initialize() async {
    if (_hasInitialized) return;

    try {
      _isLoading = true;
      _loadingProgress = 0.0;
      notifyListeners();

      // 使用Future.wait并行加载多个数据
      _loadingProgress = 0.2;
      notifyListeners();
      
      final results = await Future.wait([
        _storageService.loadScannedFolders(),
        _storageService.loadMusicList(),
      ]);

      _loadingProgress = 0.8;
      notifyListeners();
      
      // 处理加载结果
      final folders = results[0] as List<String>;
      final musicList = results[1] as List<MusicInfo>;
      
      _scannedFolders.clear();
      _scannedFolders.addAll(folders);
      
      _musicList.clear();
      _musicList.addAll(musicList);

      _loadingProgress = 1.0;
      _isLoading = false;
      _hasInitialized = true;
      notifyListeners();

      debugPrint('已从本地加载 ${_musicList.length} 首音乐');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('初始化失败: $e');
    }
  }

  /// 保存数据到本地
  Future<void> saveData() async {
    try {
      await _storageService.saveMusicList(_musicList);
      await _storageService.saveScannedFolders(_scannedFolders);
      debugPrint('数据已保存到本地');
    } catch (e) {
      debugPrint('保存数据失败: $e');
    }
  }

  /// 清除所有本地数据
  Future<void> clearLocalData() async {
    try {
      await _storageService.clearAllData();
      debugPrint('已清除所有本地数据');
    } catch (e) {
      debugPrint('清除本地数据失败: $e');
    }
  }

  /// 重置所有歌曲的播放时长（将duration设为0）
  Future<void> resetTotalDuration() async {
    // 使用compute在后台线程执行重置操作
    await compute(_resetMusicListData, _musicList);
    await saveData();
    notifyListeners();
    debugPrint('已重置所有歌曲的播放时长');
  }

  /// 静态方法，用于在后台线程重置音乐数据
  static void _resetMusicListData(List<MusicInfo> musicList) {
    for (final music in musicList) {
      music.playCount = 0;
      music.playHistory.clear();
    }
  }

  /// 记录歌曲播放
  void recordPlay(MusicInfo music) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    music.playCount++;
    music.playHistory[dateKey] = (music.playHistory[dateKey] ?? 0) + 1;

    notifyListeners();
  }

  /// 获取指定时间段的排行榜
  List<MusicInfo> getTopList({
    required Duration period,
    int limit = 10,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(period);

    final entries = _musicList
        .map((music) {
          int count = 0;
          music.playHistory.forEach((date, playCount) {
            final parts = date.split('-');
            if (parts.length == 3) {
              final playDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              if (playDate.isAfter(startDate) || playDate.isAtSameMomentAs(startDate)) {
                count += playCount;
              }
            }
          });
          return MapEntry(music, count);
        })
        .where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).map((e) => e.key).toList();
  }

  /// 获取今日排行榜
  List<MusicInfo> getTodayTopList({int limit = 10}) {
    return getTopList(period: const Duration(days: 1), limit: limit);
  }

  /// 获取本周排行榜
  List<MusicInfo> getWeekTopList({int limit = 10}) {
    return getTopList(period: const Duration(days: 7), limit: limit);
  }

  /// 获取本月排行榜
  List<MusicInfo> getMonthTopList({int limit = 10}) {
    return getTopList(period: const Duration(days: 30), limit: limit);
  }

  /// 获取本年排行榜
  List<MusicInfo> getYearTopList({int limit = 10}) {
    return getTopList(period: const Duration(days: 365), limit: limit);
  }

  /// 获取按作曲家分组的排行榜
  List<MapEntry<String, int>> getArtistTopList({
    required Duration period,
    int limit = 10,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(period);
    final artistStats = <String, int>{};

    for (final music in _musicList) {
      music.playHistory.forEach((date, playCount) {
        final parts = date.split('-');
        if (parts.length == 3) {
          final playDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (playDate.isAfter(startDate) || playDate.isAtSameMomentAs(startDate)) {
            artistStats[music.artist] = (artistStats[music.artist] ?? 0) + playCount;
          }
        }
      });
    }

    return artistStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit);
  }

  /// 获取按专辑分组的排行榜
  List<MapEntry<String, int>> getAlbumTopList({
    required Duration period,
    int limit = 10,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(period);
    final albumStats = <String, int>{};

    for (final music in _musicList) {
      music.playHistory.forEach((date, playCount) {
        final parts = date.split('-');
        if (parts.length == 3) {
          final playDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (playDate.isAtSameMomentAs(startDate) || playDate.isAfter(startDate)) {
            albumStats[music.album] = (albumStats[music.album] ?? 0) + playCount;
          }
        }
      });
    }

    return albumStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit);
  }
}
