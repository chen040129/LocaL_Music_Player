import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:palette_generator/palette_generator.dart';


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
  final int trackNumber;
  final int year;
  final int fileSize;
  int playCount;
  Map<String, int> playHistory; // 记录每天的播放次数，格式：{'2024-01-15': 3}
  final int? coverColor; // 封面主要颜色，使用 ARGB 格式存储
  final int? secondaryColor; // 封面次要颜色，使用 ARGB 格式存储
  final int? tertiaryColor; // 封面更次要颜色，使用 ARGB 格式存储
  int actualPlayDuration; // 实际播放时长（秒），用于统计总播放时长

  MusicInfo({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    this.coverArt,
    required this.duration,
    this.quality,
    this.trackNumber = 0,
    this.year = 0,
    this.fileSize = 0,
    this.playCount = 0,
    this.coverColor,
    this.secondaryColor,
    this.tertiaryColor,
    Map<String, int>? playHistory,
    this.actualPlayDuration = 0,
  }) : playHistory = playHistory ?? {};

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
      'trackNumber': trackNumber,
      'year': year,
      'fileSize': fileSize,
      'playCount': playCount,
      'playHistory': playHistory,
      'coverColor': coverColor,
      'secondaryColor': secondaryColor,
      'tertiaryColor': tertiaryColor,
      'actualPlayDuration': actualPlayDuration,
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
      trackNumber: json['trackNumber'] ?? 0,
      year: json['year'] ?? 0,
      fileSize: json['fileSize'] ?? 0,
      playCount: json['playCount'] ?? 0,
      playHistory: json['playHistory'] != null
          ? Map<String, int>.from(json['playHistory'])
          : null,
      coverColor: json['coverColor'],
      secondaryColor: json['secondaryColor'],
      tertiaryColor: json['tertiaryColor'],
      actualPlayDuration: json['actualPlayDuration'] ?? 0,
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
  int _totalFiles = 0;
  int _processedFiles = 0;
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  final StreamController<String> _logController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _coverColorController = StreamController<Map<String, dynamic>>.broadcast();

  /// 获取已扫描的音乐列表
  List<MusicInfo> get scannedMusic => List.unmodifiable(_scannedMusic);

  /// 是否正在扫描
  bool get isScanning => _isScanning;

  /// 获取进度流
  Stream<double> get progressStream => _progressController.stream;

  /// 获取日志流
  Stream<String> get logStream => _logController.stream;

  /// 获取封面颜色更新流
  Stream<Map<String, dynamic>> get coverColorStream => _coverColorController.stream;

  /// 添加日志
  void _addLog(String log) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logController.add('[$timestamp] $log');
  }

  /// 异步提取封面颜色
  Future<Map<String, int?>> _extractCoverColor(Uint8List coverArt) async {
    try {
      // 解码图片并缩小尺寸以提高性能
      final codec = await ui.instantiateImageCodec(
        coverArt,
        targetWidth: 100, // 缩小到100px宽度
        targetHeight: 100, // 缩小到100px高度
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 将图像转换为字节数组
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return {
        'coverColor': null,
        'secondaryColor': null,
        'tertiaryColor': null,
      };

      final pixels = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // 采样图片多个区域的颜色
      final colorCounts = <int, int>{};
      
      // 定义采样点：中心、四角、四边中点
      final samplePoints = [
        // 中心点
        (width ~/ 2, height ~/ 2),
        // 四个角
        (width ~/ 4, height ~/ 4),
        (width * 3 ~/ 4, height ~/ 4),
        (width ~/ 4, height * 3 ~/ 4),
        (width * 3 ~/ 4, height * 3 ~/ 4),
        // 四边中点
        (width ~/ 2, height ~/ 4),
        (width ~/ 2, height * 3 ~/ 4),
        (width ~/ 4, height ~/ 2),
        (width * 3 ~/ 4, height ~/ 2),
      ];
      
      // 在每个采样点周围采样
      const sampleRadius = 10; // 采样半径
      for (final (centerX, centerY) in samplePoints) {
        for (int y = centerY - sampleRadius; y <= centerY + sampleRadius; y++) {
          for (int x = centerX - sampleRadius; x <= centerX + sampleRadius; x++) {
            if (x >= 0 && x < width && y >= 0 && y < height) {
              final index = (y * width + x) * 4;
              final r = pixels[index];
              final g = pixels[index + 1];
              final b = pixels[index + 2];
              final a = pixels[index + 3];

              // 只采样不透明的像素
              if (a > 128) {
                // 将颜色转换为 ARGB 格式的整数
                final argb = (a << 24) | (r << 16) | (g << 8) | b;
                colorCounts[argb] = (colorCounts[argb] ?? 0) + 1;
              }
            }
          }
        }
      }

      // 找出出现次数最多的三个颜色
      if (colorCounts.isNotEmpty) {
        final sortedColors = colorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // 提取三个不同的颜色，确保颜色之间有足够的差异
        final List<int> distinctColors = [];
        final minColorDistance = 30; // 颜色差异阈值

        for (final entry in sortedColors) {
          if (distinctColors.length >= 3) break;

          final color = entry.key;
          final r = (color >> 16) & 0xFF;
          final g = (color >> 8) & 0xFF;
          final b = color & 0xFF;

          // 检查颜色是否与已有颜色有足够差异
          bool isDistinct = true;
          for (final existingColor in distinctColors) {
            final er = (existingColor >> 16) & 0xFF;
            final eg = (existingColor >> 8) & 0xFF;
            final eb = existingColor & 0xFF;

            final distance = ((r - er).abs() + (g - eg).abs() + (b - eb).abs()) / 3;
            if (distance < minColorDistance) {
              isDistinct = false;
              break;
            }
          }

          if (isDistinct) {
            distinctColors.add(color);
          }
        }

        final coverColor = distinctColors.isNotEmpty ? distinctColors[0] : null;
        final secondaryColor = distinctColors.length > 1 ? distinctColors[1] : null;
        final tertiaryColor = distinctColors.length > 2 ? distinctColors[2] : null;

        return {
          'coverColor': coverColor,
          'secondaryColor': secondaryColor,
          'tertiaryColor': tertiaryColor,
        };
      }

      return {
        'coverColor': null,
        'secondaryColor': null,
        'tertiaryColor': null,
      };
    } catch (e) {
      debugPrint('提取封面颜色失败: $e');
      return {
        'coverColor': null,
        'secondaryColor': null,
        'tertiaryColor': null,
      };
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

/// 后台处理音乐文件的函数
Future<MusicInfo> _processMusicFileAsync(String filePath) async {
  try {
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

    // 获取文件大小
    final fileSize = file.lengthSync();

    return MusicInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString() + filePath.hashCode.toString(),
      filePath: filePath,
      title: metadata.title ?? path.basenameWithoutExtension(filePath),
      artist: metadata.artist ?? '未知艺术家',
      album: metadata.album ?? '未知专辑',
      coverArt: coverArt,
      duration: duration,
      quality: quality,
      trackNumber: metadata.trackNumber != null ? int.tryParse(metadata.trackNumber.toString()) ?? 0 : 0,
      year: metadata.year != null ? int.tryParse(metadata.year.toString()) ?? 0 : 0,
      fileSize: fileSize,
      playCount: 0,
    );
  } catch (e) {
    debugPrint('处理音乐文件失败: $filePath, 错误: $e');
    rethrow;
  }
}

  /// 异步提取封面颜色并更新音乐信息
  Future<void> _extractCoverColorAsync(String musicId, Uint8List coverArt) async {
    try {
      final colors = await _extractCoverColor(coverArt);
      if (colors['coverColor'] != null) {
        // 查找并更新音乐信息
        final index = _scannedMusic.indexWhere((m) => m.id == musicId);
        if (index != -1) {
          final updatedMusic = MusicInfo(
            id: _scannedMusic[index].id,
            filePath: _scannedMusic[index].filePath,
            title: _scannedMusic[index].title,
            artist: _scannedMusic[index].artist,
            album: _scannedMusic[index].album,
            coverArt: _scannedMusic[index].coverArt,
            duration: _scannedMusic[index].duration,
            quality: _scannedMusic[index].quality,
            trackNumber: _scannedMusic[index].trackNumber,
            year: _scannedMusic[index].year,
            fileSize: _scannedMusic[index].fileSize,
            playCount: _scannedMusic[index].playCount,
            playHistory: _scannedMusic[index].playHistory,
            coverColor: colors['coverColor'],
            secondaryColor: colors['secondaryColor'],
            tertiaryColor: colors['tertiaryColor'],
          );
          _scannedMusic[index] = updatedMusic;
          debugPrint('成功提取封面颜色: ${updatedMusic.title}');
          
          // 通过流通知 MusicProvider 更新音乐封面颜色
          if (!_coverColorController.isClosed) {
            _coverColorController.add({
              'musicId': musicId,
              'coverColor': colors['coverColor'],
              'secondaryColor': colors['secondaryColor'],
              'tertiaryColor': colors['tertiaryColor'],
            });
          }
        }
      }
    } catch (e) {
      debugPrint('提取封面颜色失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _progressController.close();
    _logController.close();
    _coverColorController.close();
  }

  /// 扫描指定目录中的音乐文件
  Future<List<MusicInfo>> scanDirectory(String directoryPath) async {
    if (_isScanning) {
      debugPrint('正在扫描中，请勿重复操作');
      return _scannedMusic;
    }

    try {
      _isScanning = true;
      _totalFiles = 0;
      _processedFiles = 0;
      debugPrint('开始扫描目录: $directoryPath');

      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        debugPrint('目录不存在: $directoryPath');
        _isScanning = false;
        return [];
      }

      // 清空之前的扫描结果
      _scannedMusic.clear();

      // 先统计所有音乐文件数量
      await _countMusicFiles(dir);
      _addLog('共找到 $_totalFiles 个音乐文件');
      debugPrint('共找到 $_totalFiles 个音乐文件');

      // 递归扫描所有音乐文件
      await _scanMusicFiles(dir);

      debugPrint('扫描完成，共找到 ${_scannedMusic.length} 首音乐');

      // 确保进度达到100%
      if (!_progressController.isClosed) {
        _progressController.add(1.0);
      }

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
      final musicFiles = <File>[];
      final directories = <Directory>[];
      
      // 先分类文件和目录
      for (final entity in entities) {
        if (entity is File) {
          final filePath = entity.path;
          final extension = path.extension(filePath).toLowerCase();
          // 支持的音乐格式
          if (['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'].contains(extension)) {
            musicFiles.add(entity);
          }
        } else if (entity is Directory) {
          directories.add(entity);
        }
      }
      
      // 批量处理音乐文件
      await _processMusicFilesBatch(musicFiles);
      
      // 递归处理子目录
      for (final subDir in directories) {
        await _scanMusicFiles(subDir);
      }
    } catch (e) {
      debugPrint('扫描目录失败: ${dir.path}, 错误: $e');
    }
  }
  
  /// 批量处理音乐文件
  Future<void> _processMusicFilesBatch(List<File> musicFiles) async {
    const batchSize = 10; // 每批处理10个文件，提高导入速度
    for (int i = 0; i < musicFiles.length; i += batchSize) {
      final batch = musicFiles.skip(i).take(batchSize).toList();
      
      // 并行处理当前批次
      await Future.wait(
        batch.map((file) => _processMusicFile(file.path)),
        eagerError: false, // 一个文件失败不影响其他文件
      );
      
      _processedFiles += batch.length;
      
      // 更新进度
      if (_totalFiles > 0) {
        final progress = _processedFiles / _totalFiles;
        debugPrint('扫描进度: ${(progress * 100).toStringAsFixed(1)}%, 已处理: $_processedFiles/$_totalFiles');
        if (!_progressController.isClosed) {
          _progressController.add(progress);
        }
      }
    }
  }

  /// 处理单个音乐文件
  Future<void> _processMusicFile(String filePath) async {
    try {
      _addLog('处理文件: ${path.basename(filePath)}');
      debugPrint('处理音乐文件: $filePath');

      // 直接处理音乐文件
      final musicInfo = await _processMusicFileAsync(filePath);




      
      // 同步提取封面颜色
      Map<String, int?> colors = {
        'coverColor': null,
        'secondaryColor': null,
        'tertiaryColor': null,
      };
      if (musicInfo.coverArt != null) {
        colors = await _extractCoverColor(musicInfo.coverArt!);
      }

      // 创建带有封面颜色的 MusicInfo
      final musicInfoWithColor = MusicInfo(
        id: musicInfo.id,
        filePath: musicInfo.filePath,
        title: musicInfo.title,
        artist: musicInfo.artist,
        album: musicInfo.album,
        coverArt: musicInfo.coverArt,
        duration: musicInfo.duration,
        quality: musicInfo.quality,
        trackNumber: musicInfo.trackNumber,
        year: musicInfo.year,
        fileSize: musicInfo.fileSize,
        playCount: musicInfo.playCount,
        playHistory: musicInfo.playHistory,
        coverColor: colors['coverColor'],
        secondaryColor: colors['secondaryColor'],
        tertiaryColor: colors['tertiaryColor'],
      );

      _scannedMusic.add(musicInfoWithColor);
      debugPrint('成功添加音乐: ${musicInfo.title} ${colors['coverColor'] != null ? '(封面颜色: ${colors['coverColor']})' : ''}');
    } catch (e) {
      debugPrint('处理音乐文件失败: $filePath, 错误: $e');
    }
  }

  /// 统计音乐文件数量
  Future<void> _countMusicFiles(Directory dir) async {
    try {
      final entities = await dir.list().toList();

      for (final entity in entities) {
        if (entity is File) {
          final filePath = entity.path;
          final extension = path.extension(filePath).toLowerCase();

          // 支持的音乐格式
          if (['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'].contains(extension)) {
            _totalFiles++;
          }
        } else if (entity is Directory) {
          // 递归统计子目录
          await _countMusicFiles(entity);
        }
      }
    } catch (e) {
      debugPrint('统计音乐文件失败: ${dir.path}, 错误: $e');
    }
  }
}

