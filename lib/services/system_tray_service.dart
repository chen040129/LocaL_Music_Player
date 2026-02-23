import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';

/// 系统托盘服务
/// 负责管理应用系统托盘图标和菜单
class SystemTrayService with TrayListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _isInitialized = false;
  bool _isMinimizedToTray = false;

  /// 初始化系统托盘
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    // 添加监听器
    trayManager.addListener(this);

    // 设置托盘图标
    try {
      if (Platform.isWindows) {
        // 直接使用指定的图标路径
        String iconPath = 'E:\\Desktop\\WATCH\\LocaL_Music_Player\\windows\\runner\\resources\\app_icon.ico';
        print('尝试设置托盘图标: $iconPath');

        // 检查文件是否存在
        File iconFile = File(iconPath);
        bool fileExists = await iconFile.exists();
        print('文件存在: $fileExists');

        if (fileExists) {
          try {
            await trayManager.setIcon(iconPath);
            print('托盘图标设置成功: $iconPath');
          } catch (e) {
            print('设置托盘图标失败: $e');
            // 尝试使用相对路径
            try {
              await trayManager.setIcon('windows/runner/resources/app_icon.ico');
              print('使用相对路径设置托盘图标成功');
            } catch (e2) {
              print('使用相对路径设置失败: $e2');
              // 使用系统默认图标
              try {
                await trayManager.setIcon('C:\\Windows\\System32\\shell32.dll, 40');
                print('使用系统默认图标作为备选');
              } catch (e3) {
                print('设置系统默认图标也失败: $e3');
              }
            }
          }
        } else {
          print('错误: 托盘图标文件不存在: $iconPath');
          // 尝试使用相对路径
          try {
            await trayManager.setIcon('windows/runner/resources/app_icon.ico');
            print('使用相对路径设置托盘图标成功');
          } catch (e) {
            print('使用相对路径设置失败: $e');
            // 使用系统默认图标
            try {
              await trayManager.setIcon('C:\\Windows\\System32\\shell32.dll, 40');
              print('使用系统默认图标作为备选');
            } catch (e2) {
              print('设置系统默认图标也失败: $e2');
            }
          }
        }
      } else {
        // 其他平台使用资源路径
        await trayManager.setIcon('assets/icons/app_icon.png');
      }
    } catch (e) {
      print('设置托盘图标失败: $e');
    }

    // 设置托盘提示
    await trayManager.setToolTip('音乐播放器');

    // 创建托盘菜单
    await _setupTrayMenu(context);

    _isInitialized = true;
  }

  /// 设置托盘菜单
  Future<void> _setupTrayMenu(BuildContext context) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    Menu menu = Menu(items: [
      MenuItem(
        key: 'show_window',
        label: '显示窗口',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'play_pause',
        label: playerProvider.isPlaying ? '暂停' : '播放',
      ),
      MenuItem(
        key: 'previous',
        label: '上一曲',
      ),
      MenuItem(
        key: 'next',
        label: '下一曲',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit',
        label: '退出',
      ),
    ]);

    await trayManager.setContextMenu(menu);
  }

  /// 销毁系统托盘
  Future<void> destroy() async {
    if (!_isInitialized) return;

    trayManager.removeListener(this);
    await trayManager.destroy();
    _isInitialized = false;
  }

  /// 最小化到托盘
  Future<void> minimizeToTray() async {
    await windowManager.hide();
    _isMinimizedToTray = true;
  }

  /// 从托盘恢复窗口
  Future<void> restoreFromTray() async {
    await windowManager.show();
    await windowManager.focus();
    _isMinimizedToTray = false;
  }

  /// 更新托盘菜单
  Future<void> updateTrayMenu(BuildContext context) async {
    if (!_isInitialized) return;
    await _setupTrayMenu(context);
  }

  // 获取是否已最小化到托盘
  bool get isMinimizedToTray => _isMinimizedToTray;

  // 托盘事件回调
  @override
  void onTrayIconMouseDown() {
    // 左键点击托盘图标，显示/隐藏窗口
    if (_isMinimizedToTray) {
      restoreFromTray();
    } else {
      minimizeToTray();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    // 右键点击托盘图标，显示上下文菜单
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await restoreFromTray();
        break;
      case 'play_pause':
        // 这里需要获取当前播放状态并切换
        // 由于在静态方法中无法直接访问Provider，需要通过全局变量或其他方式
        break;
      case 'previous':
        // 播放上一曲
        break;
      case 'next':
        // 播放下一曲
        break;
      case 'exit':
        await windowManager.close();
        break;
    }
  }
}
