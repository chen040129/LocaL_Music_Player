import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 图片缓存服务 - 用于优化专辑封面的加载和缓存
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // 缓存管理器
  final BaseCacheManager _cacheManager = CacheManager(
    Config(
      'albumCovers',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  // 内存缓存
  final Map<String, Uint8List> _memoryCache = {};
  final int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentMemoryCacheSize = 0;

  /// 从缓存或网络加载图片
  Future<Uint8List?> loadImage(String key, Uint8List? originalBytes) async {
    // 如果原始数据已存在且在内存缓存中，直接返回
    if (originalBytes != null && _memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // 如果有原始数据，处理并缓存
    if (originalBytes != null) {
      return await _processAndCacheImage(key, originalBytes);
    }

    // 尝试从磁盘缓存加载
    try {
      final fileInfo = await _cacheManager.getFileFromCache(key);
      if (fileInfo != null) {
        final bytes = await fileInfo.file.readAsBytes();
        _addToMemoryCache(key, bytes);
        return bytes;
      }
    } catch (e) {
      debugPrint('Error loading image from cache: $e');
    }

    return null;
  }

  /// 处理并缓存图片
  Future<Uint8List> _processAndCacheImage(String key, Uint8List bytes) async {
    // 检查内存缓存
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    // 压缩图片
    final compressedBytes = await _compressImage(bytes);

    // 添加到内存缓存
    _addToMemoryCache(key, compressedBytes);

    // 保存到磁盘缓存
    await _cacheManager.putFile(key, compressedBytes);

    return compressedBytes;
  }

  /// 压缩图片
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 创建压缩后的图片
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final compressedBytes = byteData!.buffer.asUint8List();

      // 释放资源
      image.dispose();

      return compressedBytes;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return bytes; // 如果压缩失败，返回原始数据
    }
  }

  /// 添加到内存缓存
  void _addToMemoryCache(String key, Uint8List bytes) {
    // 检查缓存大小限制
    if (_currentMemoryCacheSize + bytes.length > _maxMemoryCacheSize) {
      _evictOldestEntries();
    }

    _memoryCache[key] = bytes;
    _currentMemoryCacheSize += bytes.length;
  }

  /// 清除最旧的缓存条目
  void _evictOldestEntries() {
    // 简单实现：清除一半的缓存
    final keysToRemove = _memoryCache.keys.take(_memoryCache.length ~/ 2).toList();
    for (final key in keysToRemove) {
      _currentMemoryCacheSize -= _memoryCache[key]!.length;
      _memoryCache.remove(key);
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;
    await _cacheManager.emptyCache();
  }

  /// 清除过期的缓存
  Future<void> cleanExpiredCache() async {
    await _cacheManager.emptyCache();
  }
}
