
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';

/// 全局热键服务类
class GlobalHotkeyService {
  static final GlobalHotkeyService _instance = GlobalHotkeyService._internal();
  factory GlobalHotkeyService() => _instance;
  GlobalHotkeyService._internal();

  PlayerProvider? _playerProvider;
  SettingsProvider? _settingsProvider;
  BuildContext? _context;

  // 当前音量（0-100）
  double _currentVolume = 70.0;

  bool _isInitialized = false;

  /// 初始化全局热键服务
  Future<void> initialize({
    required BuildContext context,
    required PlayerProvider playerProvider,
    required SettingsProvider settingsProvider,
  }) async {
    if (_isInitialized) return;

    _context = context;
    _playerProvider = playerProvider;
    _settingsProvider = settingsProvider;
    _currentVolume = settingsProvider.defaultVolume.toDouble();

    // 注册全局热键监听
    RawKeyboard.instance.addListener(_handleGlobalKeyEvent);

    _isInitialized = true;
  }

  /// 处理全局键盘事件
  void _handleGlobalKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    // 过滤重复按键事件（按住不放时）
    if (event.repeat) return;

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
          // 检查当前焦点是否在文本输入控件上
          final focusNode = FocusManager.instance.primaryFocus;
          bool isTextFieldFocused = false;

          // 检查焦点节点本身是否是文本输入控件
          if (focusNode != null && focusNode.context != null) {
            final widget = focusNode.context!.widget;
            final widgetType = widget.runtimeType.toString();
            // 检查是否是文本输入控件
            if (widgetType.contains('TextField') || 
                widgetType.contains('TextFormField') ||
                widgetType.contains('EditableText')) {
              isTextFieldFocused = true;
            }
          }

          // 如果不在文本输入控件上，直接触发播放/暂停
          // 不再检查是否在歌曲列表中，确保全局有效
          if (!isTextFieldFocused) {
            _playerProvider?.togglePlayPause();
          }
        }
        break;

      // Enter键：确认选择/播放选中项目
      case LogicalKeyboardKey.enter:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          // 如果有选中的歌曲，播放它
          if (_playerProvider != null && _playerProvider!.playlist.isNotEmpty) {
            _playerProvider!.playAtIndex(_playerProvider!.currentIndex);
          }
        }
        break;

      // 左箭头键：上一曲
      case LogicalKeyboardKey.arrowLeft:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _playerProvider?.playPrevious();
        }
        // Ctrl+左箭头键：快退15秒
        else if (isControlPressed && !isShiftPressed && !isAltPressed) {
          if (_playerProvider != null) {
            final newPosition = _playerProvider!.position - const Duration(seconds: 15);
            _playerProvider!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          }
        }
        break;

      // 右箭头键：下一曲
      case LogicalKeyboardKey.arrowRight:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _playerProvider?.playNext();
        }
        // Ctrl+右箭头键：快进15秒
        else if (isControlPressed && !isShiftPressed && !isAltPressed) {
          if (_playerProvider != null) {
            final newPosition = _playerProvider!.position + const Duration(seconds: 15);
            _playerProvider!.seekTo(newPosition > _playerProvider!.duration ? _playerProvider!.duration : newPosition);
          }
        }
        break;

      // 上箭头键：音量增加
      case LogicalKeyboardKey.arrowUp:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentVolume = (_currentVolume + 5).clamp(0.0, 100.0);
          _playerProvider?.setVolume(_currentVolume / 100);
          _settingsProvider?.setDefaultVolume(_currentVolume.toInt());
        }
        break;

      // 下箭头键：音量减少
      case LogicalKeyboardKey.arrowDown:
        if (!isControlPressed && !isShiftPressed && !isAltPressed) {
          _currentVolume = (_currentVolume - 5).clamp(0.0, 100.0);
          _playerProvider?.setVolume(_currentVolume / 100);
          _settingsProvider?.setDefaultVolume(_currentVolume.toInt());
        }
        break;
    }
  }

  /// 释放资源
  void dispose() {
    RawKeyboard.instance.removeListener(_handleGlobalKeyEvent);
    _isInitialized = false;
  }
}
