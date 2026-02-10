import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'music_scanner_service.dart';

/// 本地存储服务，用于保存和加载音乐数据
class StorageService {
  static const String _musicDataFileName = 'music_data.json';
  static const String _foldersFileName = 'scanned_folders.json';
  static const String _playProgressFileName = 'play_progress.json';

  /// 保存音乐列表到本地
  Future<void> saveMusicList(List<MusicInfo> musicList) async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_musicDataFileName');

      // 使用compute在后台线程进行JSON序列化，避免阻塞UI
      final jsonData = await compute(_encodeMusicList, musicList);
      
      // 使用缓冲写入提高性能
      final sink = file.openWrite();
      sink.write(jsonData);
      await sink.flush();
      await sink.close();

      debugPrint('音乐列表已保存到本地');
    } catch (e) {
      debugPrint('保存音乐列表失败: $e');
    }
  }

  /// 在后台线程编码音乐列表为JSON字符串
  static String _encodeMusicList(List<MusicInfo> musicList) {
    return jsonEncode(
      musicList.map((music) => music.toJson()).toList(),
    );
  }

  /// 从本地加载音乐列表
  Future<List<MusicInfo>> loadMusicList() async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_musicDataFileName');

      if (!await file.exists()) {
        debugPrint('未找到本地音乐数据文件');
        return [];
      }

      // 读取并解析JSON
      final jsonData = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonData);

      // 使用compute在后台线程解析JSON，避免阻塞UI
      final musicList = await compute(_parseMusicList, jsonList);

      debugPrint('已从本地加载 ${musicList.length} 首音乐');
      return musicList;
    } catch (e) {
      debugPrint('加载音乐列表失败: $e');
      return [];
    }
  }
  
  /// 在后台线程解析音乐列表
  static List<MusicInfo> _parseMusicList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => MusicInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 保存已扫描的文件夹列表
  Future<void> saveScannedFolders(List<String> folders) async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_foldersFileName');

      final jsonData = jsonEncode(folders);
      await file.writeAsString(jsonData);

      debugPrint('已扫描文件夹列表已保存到本地');
    } catch (e) {
      debugPrint('保存已扫描文件夹列表失败: $e');
    }
  }

  /// 从本地加载已扫描的文件夹列表
  Future<List<String>> loadScannedFolders() async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_foldersFileName');

      if (!await file.exists()) {
        debugPrint('未找到本地已扫描文件夹数据文件');
        return [];
      }

      final jsonData = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonData);

      final folders = jsonList.cast<String>();
      debugPrint('已从本地加载 ${folders.length} 个已扫描文件夹');
      return folders;
    } catch (e) {
      debugPrint('加载已扫描文件夹列表失败: $e');
      return [];
    }
  }

  /// 清除所有本地数据
  Future<void> clearAllData() async {
    try {
      final directory = await _getAppDirectory();
      final musicFile = File('${directory.path}/$_musicDataFileName');
      final foldersFile = File('${directory.path}/$_foldersFileName');

      if (await musicFile.exists()) {
        await musicFile.delete();
      }
      if (await foldersFile.exists()) {
        await foldersFile.delete();
      }

      debugPrint('已清除所有本地数据');
    } catch (e) {
      debugPrint('清除本地数据失败: $e');
    }
  }

  /// 获取应用数据目录
  Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      // Web平台使用临时目录
      return Directory.systemTemp;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await getApplicationSupportDirectory();
    }

    // 移动平台使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 保存播放进度
  Future<void> savePlayProgress({
    required String musicId,
    required Duration position,
    required String filePath,
  }) async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_playProgressFileName');

      final progressData = {
        'musicId': musicId,
        'position': position.inMilliseconds,
        'filePath': filePath,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(progressData);
      await file.writeAsString(jsonData);

      debugPrint('播放进度已保存');
    } catch (e) {
      debugPrint('保存播放进度失败: $e');
    }
  }

  /// 加载播放进度
  Future<Map<String, dynamic>?> loadPlayProgress() async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_playProgressFileName');

      if (!await file.exists()) {
        debugPrint('未找到播放进度文件');
        return null;
      }

      final jsonData = await file.readAsString();
      final progressData = jsonDecode(jsonData) as Map<String, dynamic>;

      debugPrint('已加载播放进度');
      return progressData;
    } catch (e) {
      debugPrint('加载播放进度失败: $e');
      return null;
    }
  }

  /// 清除播放进度
  Future<void> clearPlayProgress() async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_playProgressFileName');

      if (await file.exists()) {
        await file.delete();
        debugPrint('已清除播放进度');
      }
    } catch (e) {
      debugPrint('清除播放进度失败: $e');
    }
  }
}
