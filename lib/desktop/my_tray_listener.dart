import 'dart:io' show Platform, exit;

import 'package:flutter_music_player/common.dart';
import 'package:flutter_music_player/desktop/extensions/window_controller_extension.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class MyTrayListener extends TrayListener {
  void _restoreWindow() {
    print('托盘: 执行窗口恢复操作');
    windowManager.show();
    windowManager.focus();
    print('托盘: 窗口恢复完成');
  }

  void _showContextMenu() {
    print('托盘: 显示右键菜单');
    // ignore: deprecated_member_use
    trayManager.popUpContextMenu(bringAppToFront: true);
    print('托盘: 右键菜单显示完成');
  }

  @override
  void onTrayIconMouseDown() {
    print('托盘事件: 左键按下 (MouseDown)');
    _restoreWindow();
  }

  @override
  void onTrayIconMouseUp() {
    print('托盘事件: 左键释放 (MouseUp)');
    _restoreWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    print('托盘事件: 右键按下 (RightMouseDown)');
    _showContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    print('托盘事件: 右键释放 (RightMouseUp)');
    _showContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    print('托盘事件: 菜单项点击 - ${menuItem.key}');
    if (menuItem.key == 'show') {
      print('托盘菜单: 显示窗口');
      windowManager.show();
    } else if (menuItem.key == 'exit') {
      print('托盘菜单: 退出应用');
      // 退出应用
      if (Platform.isWindows) {
        windowManager.setPreventClose(false);
        windowManager.close();
      } else {
        exit(0);
      }
    } else if (menuItem.key == 'skipToPrevious') {
      print('托盘菜单: 上一首');
      _controlPlayer('skipToPrevious');
    } else if (menuItem.key == 'togglePlay') {
      print('托盘菜单: 播放/暂停');
      _controlPlayer('togglePlay');
    } else if (menuItem.key == 'skipToNext') {
      print('托盘菜单: 下一首');
      _controlPlayer('skipToNext');
    }
  }

  /// 通过窗口间通信控制播放器
  void _controlPlayer(String action) async {
    try {
      // 尝试使用全局主窗口控制器
      WindowController? controller = mainWindowController;
      
      // 如果全局主窗口控制器为null，尝试通过desktop_multi_window获取
      if (controller == null) {
        print('全局mainWindowController为null，尝试通过desktop_multi_window获取主窗口控制器');
        final controllers = await WindowController.getAll();
        print('获取到${controllers.length}个窗口控制器');
        
        // 主窗口通常是第一个窗口
        if (controllers.isNotEmpty) {
          controller = controllers.first;
          print('使用第一个窗口控制器作为主窗口控制器');
        }
      }

      if (controller == null) {
        print('错误: 无法获取主窗口控制器');
        return;
      }

      print('准备向主窗口发送$action指令');
      
      switch (action) {
        case 'skipToPrevious':
          await controller.skipToPrevious();
          break;
        case 'togglePlay':
          await controller.togglePlay();
          break;
        case 'skipToNext':
          await controller.skipToNext();
          break;
      }
      
      print('向主窗口发送$action指令成功');
    } catch (e) {
      print('控制播放器失败: $e');
    }
  }
}
