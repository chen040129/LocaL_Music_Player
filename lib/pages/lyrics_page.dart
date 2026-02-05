
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_icons.dart';

class LyricsPage extends StatefulWidget {
  const LyricsPage({Key? key}) : super(key: key);

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  bool _isHoveringPin = false;
  bool _isHoveringMinimize = false;
  bool _isHoveringMaximize = false;
  bool _isHoveringClose = false;
  bool _isAlwaysOnTop = false;

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
  void initState() {
    super.initState();
    _checkAlwaysOnTop();
  }

  Future<void> _checkAlwaysOnTop() async {
    final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    if (mounted) {
      setState(() {
        _isAlwaysOnTop = isAlwaysOnTop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentMusic = playerProvider.currentMusic;
        final isPlaying = playerProvider.isPlaying;

        return Scaffold(
          body: Stack(
            children: [
              // 主内容区域
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // 顶部导航栏（留出标题栏空间）
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // 回退按钮
                              IconButton(
                                icon: const Icon(CupertinoIcons.back),
                                color: Theme.of(context).iconTheme.color,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentMusic?.title ?? '未播放',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentMusic?.artist ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  // 歌词区域
                  Expanded(
                    child: Center(
                      child: Text(
                        '歌词功能开发中...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  // 底部播放控制
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(settings.windowOpacity),
                          boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.backward_end_fill),
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          onPressed: () => playerProvider.playPrevious(),
                          iconSize: 32,
                        ),
                        const SizedBox(width: 32),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            iconSize: 36,
                            onPressed: () => playerProvider.togglePlayPause(),
                          ),
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          icon: const Icon(CupertinoIcons.forward_end_fill),
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          onPressed: () => playerProvider.playNext(),
                          iconSize: 32,
                        ),
                      ],
                    ),
                  );
                    },
                  ),
                ],
              ),
            ),
              ),
              // 透明标题栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 32,
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // 拖动区域
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (Platform.isWindows || Platform.isLinux || Platform.isMacOS) 
                              ? (_) => windowManager.startDragging() 
                              : null,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // 窗口控制按钮
                      Row(
                        children: [
                          _buildPinButton(),
                          _buildMinimizeButton(),
                          _buildMaximizeButton(),
                          _buildCloseButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final hoverBackgroundColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

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
              _isAlwaysOnTop ? AppIcons.pinFill : AppIcons.pin,
              size: _iconSize,
              color: _isAlwaysOnTop ? Colors.blue : iconColor,
            ),
          ),
          onPressed: () async {
            final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
            await windowManager.setAlwaysOnTop(!isAlwaysOnTop);
            setState(() {
              _isAlwaysOnTop = !isAlwaysOnTop;
            });
          },
          padding: EdgeInsets.zero,
          constraints: _iconButtonConstraints,
        ),
      ),
    );
  }

  Widget _buildMinimizeButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final hoverBackgroundColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

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
          onPressed: () => windowManager.minimize(),
          padding: EdgeInsets.zero,
          constraints: _iconButtonConstraints,
        ),
      ),
    );
  }

  Widget _buildMaximizeButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return IconButton(
      icon: Icon(
        CupertinoIcons.fullscreen,
        size: _iconSize,
        color: iconColor,
      ),
      onPressed: () => windowManager.maximize(),
      padding: EdgeInsets.zero,
      constraints: _iconButtonConstraints,
    );
  }

  Widget _buildCloseButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return IconButton(
      icon: Icon(
        CupertinoIcons.xmark,
        size: _iconSize,
        color: iconColor,
      ),
      onPressed: () => windowManager.close(),
      padding: EdgeInsets.zero,
      constraints: _iconButtonConstraints,
    );
  }
}
