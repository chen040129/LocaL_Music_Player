
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

/// 播放器栏窗口状态提供者
/// 管理播放器栏是否在独立窗口中，以及独立窗口的显示/隐藏
class PlayerBarProvider extends ChangeNotifier {
  bool _isDetached = false; // 是否已分离到独立窗口
  bool _isWindowVisible = false; // 独立窗口是否可见
  bool _isInitialized = false; // 是否已初始化
  Offset _position = const Offset(16, 0); // 播放器栏在主窗口中的位置

  // 获取状态
  bool get isDetached => _isDetached;
  bool get isWindowVisible => _isWindowVisible;
  bool get isInitialized => _isInitialized;
  Offset get position => _position;

  // 初始化播放器栏窗口
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 加载保存的分离状态
    final prefs = await SharedPreferences.getInstance();
    _isDetached = prefs.getBool('player_bar_detached') ?? false;

    if (_isDetached && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // 如果之前是分离状态，启动独立窗口
      await _initializeWindow();
      _isWindowVisible = true;
    }

    _isInitialized = true;
    notifyListeners();
  }

  // 初始化独立窗口
  Future<void> _initializeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 加载保存的窗口位置
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble('player_bar_window_x') ?? 100.0;
      final savedY = prefs.getDouble('player_bar_window_y') ?? 100.0;

      // 窗口配置 - 设置为无边框窗口
      final windowOptions = WindowOptions(
        size: const Size(600, 80),
        minimumSize: const Size(500, 70),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
        alwaysOnTop: true,
        center: false,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setAsFrameless();
        await windowManager.setSkipTaskbar(false);
        await windowManager.setPosition(Offset(savedX, savedY));
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setIgnoreMouseEvents(false);
      });
    }
  }

  // 分离播放器栏到独立窗口
  Future<void> detach() async {
    if (_isDetached) return;

    // 在分离前保存主窗口大小
    Size? mainWindowSize;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      mainWindowSize = await windowManager.getSize();
    }

    // 启动独立窗口进程
    await _launchPlayerBarWindow();

    _isDetached = true;
    _isWindowVisible = true;

    // 保存分离状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('player_bar_detached', true);

    notifyListeners();

    // 确保主窗口大小不变
    if (mainWindowSize != null && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.setSize(mainWindowSize);
    }
  }

  // 分离播放器栏到独立窗口，并设置窗口位置
  Future<void> detachWithPosition(Offset position) async {
    if (_isDetached) return;

    // 在分离前保存主窗口大小
    Size? mainWindowSize;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      mainWindowSize = await windowManager.getSize();
    }

    // 保存窗口位置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('player_bar_window_x', position.dx);
    await prefs.setDouble('player_bar_window_y', position.dy);

    // 启动独立窗口进程
    await _launchPlayerBarWindow();

    _isDetached = true;
    _isWindowVisible = true;

    // 保存分离状态
    await prefs.setBool('player_bar_detached', true);

    notifyListeners();

    // 确保主窗口大小不变
    if (mainWindowSize != null && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.setSize(mainWindowSize);
    }
  }

  // 将播放器栏吸附回主窗口
  Future<void> attach() async {
    if (!_isDetached) return;

    // 关闭独立窗口进程
    await _terminatePlayerBarWindow();

    _isDetached = false;
    _isWindowVisible = false;

    // 保存分离状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('player_bar_detached', false);

    notifyListeners();
  }

  // 切换播放器栏的分离/吸附状态
  Future<void> toggleDetach() async {
    if (_isDetached) {
      await attach();
    } else {
      await detach();
    }
  }

  // 保存独立窗口位置
  Future<void> saveWindowPosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('player_bar_window_x', position.dx);
    await prefs.setDouble('player_bar_window_y', position.dy);
  }

  // 更新播放器栏位置
  void updatePosition(Offset position) {
    _position = position;
    notifyListeners();
  }

  // 保存播放器栏位置
  Future<void> savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('player_bar_x', _position.dx);
    await prefs.setDouble('player_bar_y', _position.dy);
  }

  // 加载播放器栏位置
  Future<void> loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('player_bar_x');
    final savedY = prefs.getDouble('player_bar_y');

    if (savedX != null && savedY != null) {
      _position = Offset(savedX, savedY);
      notifyListeners();
    }
  }

  // 启动独立播放器栏窗口进程
  Future<void> _launchPlayerBarWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // 获取当前可执行文件的路径
        final executable = Platform.resolvedExecutable;
        final directory = path.dirname(executable);

        // 构建命令
        late List<String> command;
        if (Platform.isWindows) {
          command = [
            'cmd',
            '/c',
            'start',
            '/B',
            executable,
            '-d',
            'windows',
            '-t',
            'lib/player_bar_window.dart',
          ];
        } else if (Platform.isLinux) {
          command = [
            executable,
            '-d',
            'linux',
            '-t',
            'lib/player_bar_window.dart',
          ];
        } else if (Platform.isMacOS) {
          command = [
            executable,
            '-d',
            'macos',
            '-t',
            'lib/player_bar_window.dart',
          ];
        }

        // 启动进程
        await Process.start(
          command[0],
          command.sublist(1),
          workingDirectory: directory,
        );
      } catch (e) {
        print('启动独立播放器栏窗口失败: $e');
      }
    }
  }

  // 终止独立播放器栏窗口进程
  Future<void> _terminatePlayerBarWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // 通过保存的进程ID终止进程
        // 注意：这里需要实现进程管理，例如保存进程ID
        // 简化实现：通过窗口管理器关闭窗口
        // 由于独立窗口是独立进程，我们需要通过其他方式关闭它
        // 这里可以使用进程间通信或保存进程ID的方式
        // 为简化实现，我们暂时不实现终止进程的逻辑
        // 实际应用中，应该保存进程ID并在需要时终止它
      } catch (e) {
        print('终止独立播放器栏窗口失败: $e');
      }
    }
  }
}
