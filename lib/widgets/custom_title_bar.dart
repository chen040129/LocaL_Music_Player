import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../constants/app_icons.dart';

class CustomTitleBar extends StatefulWidget {
  final String title;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  final VoidCallback onAlwaysOnTop;
  final bool isAlwaysOnTop;

  const CustomTitleBar({
    Key? key,
    required this.title,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    required this.onAlwaysOnTop,
    this.isAlwaysOnTop = false,
  }) : super(key: key);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isHoveringPin = false;
  bool _isHoveringMinimize = false;
  bool _isHoveringMaximize = false;
  bool _isHoveringClose = false;

  // 缓存平台检查结果，避免每次build都检查
  static final bool _isDesktopPlatform = 
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  // 提取常量，避免重复创建
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const BoxConstraints _iconButtonConstraints = BoxConstraints(
    minWidth: 32,
    minHeight: 32,
  );
  static const double _iconSize = 16.0;
  static const double _hoverScale = 1.2;
  static const double _normalScale = 1.0;
  static const double _borderRadius = 4.0;

  @override
  Widget build(BuildContext context) {
    // 提取Theme相关数据，避免重复调用Theme.of(context)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = theme.iconTheme.color;
    final hoverBackgroundColor = colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return Container(
      height: 32,
      color: colorScheme.surface,
      child: Row(
        children: [
          // 拖动区域
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _isDesktopPlatform ? (_) => windowManager.startDragging() : null,
              child: Container(
                color: colorScheme.surface,
              ),
            ),
          ),
          // 窗口控制按钮
          Row(
            children: [
              _buildPinButton(hoverBackgroundColor),
              _buildMinimizeButton(hoverBackgroundColor, iconColor),
              _buildMaximizeButton(iconColor),
              _buildCloseButton(iconColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(Color hoverBackgroundColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringPin = true),
      onExit: (_) => setState(() => _isHoveringPin = false),
      child: AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color: _isHoveringPin ? hoverBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: IconButton(
          icon: AnimatedScale(
            scale: _isHoveringPin ? _hoverScale : _normalScale,
            duration: _animationDuration,
            child: Icon(
              widget.isAlwaysOnTop ? AppIcons.pinFill : AppIcons.pin,
              size: _iconSize,
              color: widget.isAlwaysOnTop ? Colors.blue : null,
            ),
          ),
          onPressed: widget.onAlwaysOnTop,
          padding: EdgeInsets.zero,
          constraints: _iconButtonConstraints,
        ),
      ),
    );
  }

  Widget _buildMinimizeButton(Color hoverBackgroundColor, Color? iconColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMinimize = true),
      onExit: (_) => setState(() => _isHoveringMinimize = false),
      child: AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color: _isHoveringMinimize ? hoverBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: IconButton(
          icon: Icon(
            CupertinoIcons.minus,
            size: _iconSize,
            color: iconColor,
          ),
          onPressed: widget.onMinimize,
          padding: EdgeInsets.zero,
          constraints: _iconButtonConstraints,
        ),
      ),
    );
  }

  Widget _buildMaximizeButton(Color? iconColor) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.fullscreen,
        size: _iconSize,
        color: iconColor,
      ),
      onPressed: widget.onMaximize,
      padding: EdgeInsets.zero,
      constraints: _iconButtonConstraints,
    );
  }

  Widget _buildCloseButton(Color? iconColor) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.xmark,
        size: _iconSize,
        color: iconColor,
      ),
      onPressed: widget.onClose,
      padding: EdgeInsets.zero,
      constraints: _iconButtonConstraints,
    );
  }
}
