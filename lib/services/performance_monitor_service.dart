import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

/// 性能监控服务 - 用于监控应用的内存使用和性能指标
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  // 性能指标
  int _currentMemoryUsage = 0;
  int _peakMemoryUsage = 0;
  final List<int> _memoryUsageHistory = [];
  final int _maxHistorySize = 100;

  // 内存警告阈值（MB）
  static const int memoryWarningThreshold = 300; // 300MB
  static const int memoryCriticalThreshold = 500; // 500MB

  // 流控制器
  final _memoryUsageController = StreamController<int>.broadcast();
  final _performanceWarningController = StreamController<String>.broadcast();

  // 获取流
  Stream<int> get memoryUsageStream => _memoryUsageController.stream;
  Stream<String> get performanceWarningStream => _performanceWarningController.stream;

  // 定时器
  Timer? _monitorTimer;

  /// 启动性能监控
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) {
      _updateMemoryUsage();
    });
  }

  /// 停止性能监控
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// 更新内存使用情况
  void _updateMemoryUsage() {
    try {
      // 注意：在实际应用中，这里应该使用更可靠的方法获取内存使用情况
      // 这里使用模拟值，实际部署时应该替换为真实的内存监控
      _currentMemoryUsage = _currentMemoryUsage > 0 ? _currentMemoryUsage : 100 * 1024 * 1024;

      // 更新峰值内存使用
      if (_currentMemoryUsage > _peakMemoryUsage) {
        _peakMemoryUsage = _currentMemoryUsage;
      }

      // 添加到历史记录
      _memoryUsageHistory.add(_currentMemoryUsage);
      if (_memoryUsageHistory.length > _maxHistorySize) {
        _memoryUsageHistory.removeAt(0);
      }

      // 发送内存使用更新
      _memoryUsageController.add(_currentMemoryUsage);

      // 检查内存使用是否超过阈值
      _checkMemoryThresholds();
    } catch (e) {
      developer.log('Error updating memory usage: $e');
    }
  }

  /// 检查内存使用是否超过阈值
  void _checkMemoryThresholds() {
    final currentUsageMB = _currentMemoryUsage ~/ (1024 * 1024);

    if (currentUsageMB >= memoryCriticalThreshold) {
      _performanceWarningController.add(
        '内存使用严重警告: 当前使用 ${currentUsageMB}MB，超过临界值 ${memoryCriticalThreshold}MB',
      );
      _clearCacheIfNeeded();
    } else if (currentUsageMB >= memoryWarningThreshold) {
      _performanceWarningController.add(
        '内存使用警告: 当前使用 ${currentUsageMB}MB，超过警告值 ${memoryWarningThreshold}MB',
      );
    }
  }

  /// 如果需要，清除缓存
  void _clearCacheIfNeeded() {
    final currentUsageMB = _currentMemoryUsage ~/ (1024 * 1024);
    if (currentUsageMB >= memoryCriticalThreshold) {
      // 发送清除缓存的请求
      _performanceWarningController.add('建议清除缓存以释放内存');
    }
  }

  /// 获取当前内存使用情况（MB）
  int getCurrentMemoryUsageMB() {
    return _currentMemoryUsage ~/ (1024 * 1024);
  }

  /// 获取峰值内存使用情况（MB）
  int getPeakMemoryUsageMB() {
    return _peakMemoryUsage ~/ (1024 * 1024);
  }

  /// 获取平均内存使用情况（MB）
  double getAverageMemoryUsageMB() {
    if (_memoryUsageHistory.isEmpty) return 0.0;
    final total = _memoryUsageHistory.reduce((a, b) => a + b);
    return (total / _memoryUsageHistory.length) / (1024 * 1024);
  }

  /// 获取内存使用历史
  List<int> getMemoryUsageHistory() {
    return List.from(_memoryUsageHistory);
  }

  /// 清除历史记录
  void clearHistory() {
    _memoryUsageHistory.clear();
    _peakMemoryUsage = 0;
  }

  /// 释放资源
  void dispose() {
    stopMonitoring();
    _memoryUsageController.close();
    _performanceWarningController.close();
  }
}
