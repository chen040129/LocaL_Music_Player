
import 'package:flutter/foundation.dart';
import 'package:lpinyin/lpinyin.dart';
import '../services/music_scanner_service.dart';
import '../services/storage_service.dart';

/// 音乐状态管理Provider
class MusicProvider with ChangeNotifier {
  final MusicScannerService _scannerService = MusicScannerService();
  final StorageService _storageService = StorageService();
  List<MusicInfo> _musicList = [];
  bool _isScanning = false;
  String _scanStatus = '未开始扫描';
  int _scannedCount = 0;
  List<String> _scannedFolders = [];
  bool _hasInitialized = false;

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
    albumList.sort((a, b) {
      final aPinyin = PinyinHelper.getPinyinE(a, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
      final bPinyin = PinyinHelper.getPinyinE(b, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
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
    artistList.sort((a, b) {
      final aPinyin = PinyinHelper.getPinyinE(a, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
      final bPinyin = PinyinHelper.getPinyinE(b, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
      return aPinyin.compareTo(bPinyin);
    });
    return artistList;
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

  /// 已扫描的文件夹列表
  List<String> get scannedFolders => List.unmodifiable(_scannedFolders);

  /// 扫描指定目录中的音乐文件
  Future<void> scanDirectory(String directoryPath) async {
    if (_isScanning) {
      debugPrint('正在扫描中，请勿重复操作');
      return;
    }

    try {
      _isScanning = true;
      _scanStatus = '正在扫描...';
      notifyListeners();

      final scannedMusic = await _scannerService.scanDirectory(directoryPath);

      _musicList.addAll(scannedMusic);
      _isScanning = false;
      _scanStatus = '扫描完成';
      _scannedCount = scannedMusic.length;
      _scannedFolders.add(directoryPath);

      // 自动保存到本地
      await saveData();

      notifyListeners();

      debugPrint('扫描完成，共找到 ${scannedMusic.length} 首音乐');
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

  /// 初始化，从本地加载数据
  Future<void> initialize() async {
    if (_hasInitialized) return;

    try {
      // 加载已扫描的文件夹列表
      final folders = await _storageService.loadScannedFolders();
      _scannedFolders.clear();
      _scannedFolders.addAll(folders);

      // 加载音乐列表
      final musicList = await _storageService.loadMusicList();
      _musicList.clear();
      _musicList.addAll(musicList);

      _hasInitialized = true;
      notifyListeners();

      debugPrint('已从本地加载 ${_musicList.length} 首音乐');
    } catch (e) {
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
}
