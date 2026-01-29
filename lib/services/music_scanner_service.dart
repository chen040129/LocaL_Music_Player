
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// 音乐信息模型
class MusicInfo {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final Uint8List? coverArt;
  final Duration duration;
  final String? quality;

  MusicInfo({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    this.coverArt,
    required this.duration,
    this.quality,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'coverArt': coverArt != null ? _bytesToBase64(coverArt!) : null,
      'duration': duration.inMilliseconds,
      'quality': quality,
    };
  }

  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  factory MusicInfo.fromJson(Map<String, dynamic> json) {
    return MusicInfo(
      id: json['id'],
      filePath: json['filePath'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      coverArt: json['coverArt'] != null ? _base64ToBytes(json['coverArt']) : null,
      duration: Duration(milliseconds: json['duration']),
      quality: json['quality'],
    );
  }

  static Uint8List _base64ToBytes(String base64) {
    return base64Decode(base64);
  }
}

/// 音乐扫描服务
class MusicScannerService {
  final List<MusicInfo> _scannedMusic = [];
  bool _isScanning = false;

  /// 获取已扫描的音乐列表
  List<MusicInfo> get scannedMusic => List.unmodifiable(_scannedMusic);

  /// 是否正在扫描
  bool get isScanning => _isScanning;

  /// 扫描指定目录中的音乐文件
  Future<List<MusicInfo>> scanDirectory(String directoryPath) async {
    if (_isScanning) {
      debugPrint('正在扫描中，请勿重复操作');
      return _scannedMusic;
    }

    try {
      _isScanning = true;
      debugPrint('开始扫描目录: $directoryPath');

      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        debugPrint('目录不存在: $directoryPath');
        _isScanning = false;
        return [];
      }

      // 清空之前的扫描结果
      _scannedMusic.clear();

      // 递归扫描所有音乐文件
      await _scanMusicFiles(dir);

      debugPrint('扫描完成，共找到 ${_scannedMusic.length} 首音乐');
      return _scannedMusic;
    } catch (e) {
      debugPrint('扫描音乐文件失败: $e');
      return [];
    } finally {
      _isScanning = false;
    }
  }

  /// 递归扫描音乐文件
  Future<void> _scanMusicFiles(Directory dir) async {
    try {
      final entities = await dir.list().toList();

      for (final entity in entities) {
        if (entity is File) {
          final filePath = entity.path;
          final extension = path.extension(filePath).toLowerCase();

          // 支持的音乐格式
          if (['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'].contains(extension)) {
            await _processMusicFile(filePath);
          }
        } else if (entity is Directory) {
          // 递归扫描子目录
          await _scanMusicFiles(entity);
        }
      }
    } catch (e) {
      debugPrint('扫描目录失败: ${dir.path}, 错误: $e');
    }
  }

  /// 处理单个音乐文件
  Future<void> _processMusicFile(String filePath) async {
    try {
      debugPrint('处理音乐文件: $filePath');

      // 使用audio_metadata_reader包提取音乐元数据和封面
      final file = File(filePath);
      final metadata = readMetadata(file, getImage: true);

      // 提取封面
      Uint8List? coverArt;
      if (metadata.pictures != null && metadata.pictures!.isNotEmpty) {
        coverArt = metadata.pictures!.first.bytes;
      }

      // 获取音乐时长
      final duration = metadata.duration ?? Duration.zero;

      // 判断音质
      final quality = _determineQuality(filePath, duration);

      // 创建音乐信息对象
      final musicInfo = MusicInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString() + filePath.hashCode.toString(),
        filePath: filePath,
        title: metadata.title ?? path.basenameWithoutExtension(filePath),
        artist: metadata.artist ?? '未知艺术家',
        album: metadata.album ?? '未知专辑',
        coverArt: coverArt,
        duration: duration,
        quality: quality,
      );

      _scannedMusic.add(musicInfo);
      debugPrint('成功添加音乐: ${musicInfo.title}');
    } catch (e) {
      debugPrint('处理音乐文件失败: $filePath, 错误: $e');
    }
  }

  /// 判断音乐音质
  String? _determineQuality(String filePath, Duration duration) {
    try {
      final file = File(filePath);
      final fileSize = file.lengthSync();

      // 简单判断音质：根据文件大小和时长计算比特率
      if (duration.inSeconds > 0) {
        final bitrate = (fileSize * 8) / (duration.inSeconds * 1000); // kbps

        if (bitrate > 320) {
          return 'HR'; // 高解析度
        } else if (bitrate > 192) {
          return 'HQ'; // 高质量
        } else if (bitrate > 128) {
          return 'SQ'; // 标准质量
        }
      }

      return null;
    } catch (e) {
      debugPrint('判断音质失败: $e');
      return null;
    }
  }
}
