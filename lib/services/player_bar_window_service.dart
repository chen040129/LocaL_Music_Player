
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 独立音乐栏窗口服务
/// 用于创建和管理独立于主窗口的音乐栏窗口
class PlayerBarWindowService {
  static PlayerBarWindowService? _instance;
  bool _isInitialized = false;
  bool _isVisible = false;

  // 私有构造函数
  PlayerBarWindowService._();

  // 获取单例实例
  static PlayerBarWindowService get instance {
    _instance ??= PlayerBarWindowService._();
    return _instance!;
  }

  // 初始化独立窗口
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 窗口配置
      const windowOptions = WindowOptions(
        size: Size(600, 80),
        minimumSize: Size(500, 70),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
        alwaysOnTop: true, // 始终置顶
        center: false,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setAsFrameless();
        await windowManager.setSkipTaskbar(false);
        await windowManager.show();
        await windowManager.focus();
        _isVisible = true;
      });

      _isInitialized = true;
    }
  }

  // 显示窗口
  Future<void> show() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.show();
      await windowManager.focus();
      _isVisible = true;
    }
  }

  // 隐藏窗口
  Future<void> hide() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.hide();
      _isVisible = false;
    }
  }

  // 切换窗口显示状态
  Future<void> toggleVisibility() async {
    if (_isVisible) {
      await hide();
    } else {
      await show();
    }
  }

  // 设置窗口位置
  Future<void> setPosition(Offset position) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setPosition(position);
    }
  }

  // 获取窗口位置
  Future<Offset> getPosition() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final position = await windowManager.getPosition();
      return Offset(position.dx, position.dy);
    }
    return Offset.zero;
  }

  // 设置窗口大小
  Future<void> setSize(Size size) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setSize(size);
    }
  }

  // 销毁窗口
  Future<void> destroy() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.destroy();
      _isInitialized = false;
      _isVisible = false;
    }
  }

  // 设置是否始终置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    }
  }
}
