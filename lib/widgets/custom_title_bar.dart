import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../constants/app_icons.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class CustomTitleBar extends StatefulWidget {
  final String title;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  final VoidCallback onAlwaysOnTop;
  final bool isAlwaysOnTop;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onMinimizeToTray;

  const CustomTitleBar({
    Key? key,
    required this.title,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    required this.onAlwaysOnTop,
    this.isAlwaysOnTop = false,
    this.onToggleSidebar,
    this.onMinimizeToTray,
  }) : super(key: key);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isHoveringPin = false;
  bool _isHoveringMinimize = false;
  bool _isHoveringMaximize = false;
  bool _isHoveringClose = false;
  bool _isHoveringTray = false;
  Size? _windowSize;

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

  @override
  void initState() {
    super.initState();
    _updateWindowSize();
  }

  Future<void> _updateWindowSize() async {
    _windowSize = await windowManager.getSize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 提取Theme相关数据，避免重复调用Theme.of(context)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = theme.iconTheme.color;
    final hoverBackgroundColor = colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return Stack(
      children: [

        // 标题栏
        Container(
          height: 32,
          color: Colors.transparent,
          child: Row(
            children: [
              // 拖动区域
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: _isDesktopPlatform ? (_) => windowManager.startDragging() : null,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // 窗口控制按钮
              Row(
                children: [
                  _buildPinButton(hoverBackgroundColor),
                  if (widget.onMinimizeToTray != null) _buildTrayButton(hoverBackgroundColor, iconColor),
                  _buildMinimizeButton(hoverBackgroundColor, iconColor),
                  _buildMaximizeButton(iconColor),
                  _buildCloseButton(iconColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinButton(Color hoverBackgroundColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringPin = true),
      onExit: (_) => setState(() => _isHoveringPin = false),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(settings.borderRadius),
            child: InkWell(
              onTap: widget.onAlwaysOnTop,
              borderRadius: BorderRadius.circular(settings.borderRadius),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                constraints: _iconButtonConstraints,
                child: AnimatedScale(
                  scale: _isHoveringPin ? _hoverScale : _normalScale,
                  duration: _animationDuration,
                  child: Icon(
                    widget.isAlwaysOnTop ? AppIcons.pinFill : AppIcons.pin,
                    size: _iconSize,
                    color: widget.isAlwaysOnTop ? Colors.blue : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrayButton(Color hoverBackgroundColor, Color? iconColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringTray = true),
      onExit: (_) => setState(() => _isHoveringTray = false),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(settings.borderRadius),
            child: InkWell(
              onTap: widget.onMinimizeToTray,
              borderRadius: BorderRadius.circular(settings.borderRadius),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                constraints: _iconButtonConstraints,
                child: AnimatedScale(
                  scale: _isHoveringTray ? _hoverScale : _normalScale,
                  duration: _animationDuration,
                  child: Icon(
                    AppIcons.tray,
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinimizeButton(Color hoverBackgroundColor, Color? iconColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMinimize = true),
      onExit: (_) => setState(() => _isHoveringMinimize = false),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(settings.borderRadius),
            child: InkWell(
              onTap: widget.onMinimize,
              borderRadius: BorderRadius.circular(settings.borderRadius),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                constraints: _iconButtonConstraints,
                child: AnimatedScale(
                  scale: _isHoveringMinimize ? _hoverScale : _normalScale,
                  duration: _animationDuration,
                  child: Icon(
                    CupertinoIcons.minus,
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaximizeButton(Color? iconColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMaximize = true),
      onExit: (_) => setState(() => _isHoveringMaximize = false),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(settings.borderRadius),
            child: InkWell(
              onTap: widget.onMaximize,
              borderRadius: BorderRadius.circular(settings.borderRadius),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                constraints: _iconButtonConstraints,
                child: AnimatedScale(
                  scale: _isHoveringMaximize ? _hoverScale : _normalScale,
                  duration: _animationDuration,
                  child: Icon(
                    CupertinoIcons.fullscreen,
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseButton(Color? iconColor) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringClose = true),
      onExit: (_) => setState(() => _isHoveringClose = false),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(settings.borderRadius),
            child: InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(settings.borderRadius),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                constraints: _iconButtonConstraints,
                child: AnimatedScale(
                  scale: _isHoveringClose ? _hoverScale : _normalScale,
                  duration: _animationDuration,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
