
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';

/// 热键处理器类
class HotkeyHandler {
  final BuildContext context;
  final PlayerProvider playerProvider;
  final SettingsProvider settingsProvider;

  // 当前音量（0-100）
  double _currentVolume = 70.0;

  // 当前缩放比例
  double _currentScale = 1.0;

  HotkeyHandler({
    required this.context,
    required this.playerProvider,
    required this.settingsProvider,
  }) {
    _currentVolume = settingsProvider.defaultVolume.toDouble();
  }

  /// 切换全屏模式
  Future<void> _toggleFullScreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    if (isFullScreen) {
      await windowManager.setFullScreen(false);
    } else {
      await windowManager.setFullScreen(true);
    }
  }

  /// 处理键盘事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isControlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                            HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
    final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.altLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.altRight);

    switch (event.logicalKey) {
      // 空格键：播放/暂停切换
      case LogicalKeyboardKey.space:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          playerProvider.togglePlayPause();
          return true;
        }
        break;

      // Enter键：确认选择/播放选中项目
      case LogicalKeyboardKey.enter:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          // 如果有选中的歌曲，播放它
          if (playerProvider.playlist.isNotEmpty) {
            playerProvider.playAtIndex(playerProvider.currentIndex);
          }
          return true;
        }
        break;

      // Esc键：退出全屏模式
      case LogicalKeyboardKey.escape:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          Navigator.of(context).pop();
          return true;
        }
        break;

      // 左箭头键：上一曲
      case LogicalKeyboardKey.arrowLeft:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          playerProvider.playPrevious();
          return true;
        }
        // Ctrl+左箭头键：快退15秒
        else if (isControlPressed && !isShiftPressed && !isAltPressed) {
          final newPosition = playerProvider.position - const Duration(seconds: 15);
          playerProvider.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          return true;
        }
        break;

      // 右箭头键：下一曲
      case LogicalKeyboardKey.arrowRight:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          playerProvider.playNext();
          return true;
        }
        // Ctrl+右箭头键：快进15秒
        else if (isControlPressed && !isShiftPressed && !isAltPressed) {
          final newPosition = playerProvider.position + const Duration(seconds: 15);
          playerProvider.seekTo(newPosition > playerProvider.duration ? playerProvider.duration : newPosition);
          return true;
        }
        break;

      // 上箭头键：音量增加
      case LogicalKeyboardKey.arrowUp:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentVolume = (_currentVolume + 5).clamp(0.0, 100.0);
          playerProvider.setVolume(_currentVolume / 100);
          settingsProvider.setDefaultVolume(_currentVolume.toInt());
          return true;
        }
        break;

      // 下箭头键：音量减少
      case LogicalKeyboardKey.arrowDown:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentVolume = (_currentVolume - 5).clamp(0.0, 100.0);
          playerProvider.setVolume(_currentVolume / 100);
          settingsProvider.setDefaultVolume(_currentVolume.toInt());
          return true;
        }
        break;

      // F11键：切换全屏模式
      case LogicalKeyboardKey.f11:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _toggleFullScreen();
          return true;
        }
        break;

      // Ctrl+F键：全局搜索歌曲
      case LogicalKeyboardKey.keyF:
        if (isControlPressed && !isShiftPressed && !isAltPressed) {
          // 这里需要实现搜索功能
          // 可以通过导航到搜索页面或显示搜索对话框
          return true;
        }
        break;

      // Ctrl+W键：关闭当前窗口
      case LogicalKeyboardKey.keyW:
        if (isControlPressed && !isShiftPressed && !isAltPressed) {
          Navigator.of(context).pop();
          return true;
        }
        break;

      // Ctrl++键：增大界面缩放
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.numpadAdd:
        if (isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentScale = (_currentScale + 0.1).clamp(0.5, 2.0);
          // 这里需要实现缩放逻辑
          return true;
        }
        break;

      // Ctrl+-键：减小界面缩放
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        if (isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentScale = (_currentScale - 0.1).clamp(0.5, 2.0);
          // 这里需要实现缩放逻辑
          return true;
        }
        break;

      // Ctrl+0键：恢复默认缩放
      case LogicalKeyboardKey.digit0:
      case LogicalKeyboardKey.numpad0:
        if (isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentScale = 1.0;
          // 这里需要实现缩放逻辑
          return true;
        }
        break;

      // Ctrl+Shift+Q键：强制终止进程
      case LogicalKeyboardKey.keyQ:
        if (isControlPressed && isShiftPressed && !isAltPressed) {
          // 这里需要实现强制终止进程逻辑
          return true;
        }
        break;

      // Ctrl+Shift+R键：刷新播放列表
      case LogicalKeyboardKey.keyR:
        if (isControlPressed && isShiftPressed && !isAltPressed) {
          // 这里需要实现刷新播放列表逻辑
          return true;
        }
        break;

      // Alt+Enter键：切换详情页
      case LogicalKeyboardKey.enter:
        if (!isControlPressed && !isShiftPressed && isAltPressed) {
          // 这里需要实现切换详情页逻辑
          return true;
        }
        break;
    }

    return false;
  }
}
