
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' as io;

/// 播放器调试辅助类
class PlayerDebugHelper {
  static AudioPlayer? _debugPlayer;

  /// 初始化调试播放器
  static Future<void> init() async {
    if (_debugPlayer == null) {
      _debugPlayer = AudioPlayer();
      debugPrint('=== 播放器调试初始化 ===');

      // 监听播放状态
      _debugPlayer!.onPlayerStateChanged.listen((state) {
        debugPrint('播放状态变化: $state');
      });

      // 监听播放位置
      _debugPlayer!.onPositionChanged.listen((position) {
        debugPrint('播放位置: ${position.inSeconds}s');
      });

      // 监听音频时长
      _debugPlayer!.onDurationChanged.listen((duration) {
        debugPrint('音频时长: ${duration.inSeconds}s');
      });

      // 监听播放完成
      _debugPlayer!.onPlayerComplete.listen((_) {
        debugPrint('播放完成');
      });

      // 监听错误
      _debugPlayer!.onLog.listen((log) {
        debugPrint('播放器日志: $log');
      });
    }
  }

  /// 测试播放本地文件
  static Future<void> testPlayLocalFile(String filePath) async {
    try {
      await init();

      debugPrint('=== 开始测试播放文件 ===');
      debugPrint('文件路径: $filePath');

      // 检查文件是否存在
      final file = io.File(filePath);
      if (!await file.exists()) {
        debugPrint('错误: 文件不存在');
        return;
      }

      // 获取文件大小
      final fileSize = await file.length();
      debugPrint('文件大小: $fileSize bytes');

      // 设置音源
      debugPrint('设置音源...');
      final source = DeviceFileSource(filePath);
      await _debugPlayer!.setSource(source);
      debugPrint('音源设置成功');

      // 获取时长
      final duration = await _debugPlayer!.getDuration();
      debugPrint('音频时长: ${duration?.inSeconds ?? 0}秒');

      // 播放
      debugPrint('开始播放...');
      await _debugPlayer!.play(source);
      debugPrint('播放命令已发送');

    } catch (e, stackTrace) {
      debugPrint('=== 播放测试失败 ===');
      debugPrint('错误: $e');
      debugPrint('堆栈: $stackTrace');
    }
  }

  /// 获取播放器状态
  static String getPlayerState() {
    if (_debugPlayer == null) return '未初始化';

    final state = _debugPlayer!.state;
    switch (state) {
      case PlayerState.stopped:
        return '已停止';
      case PlayerState.playing:
        return '正在播放';
      case PlayerState.paused:
        return '已暂停';
      case PlayerState.completed:
        return '播放完成';
      case PlayerState.disposed:
        return '已释放';
      default:
        return '未知状态: $state';
    }
  }

  /// 停止播放
  static Future<void> stop() async {
    if (_debugPlayer != null) {
      await _debugPlayer!.stop();
      debugPrint('已停止播放');
    }
  }

  /// 释放播放器
  static Future<void> dispose() async {
    if (_debugPlayer != null) {
      await _debugPlayer!.release();
      _debugPlayer!.dispose();
      _debugPlayer = null;
      debugPrint('播放器已释放');
    }
  }
}
