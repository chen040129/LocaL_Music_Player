import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/player_bar_provider.dart';
import '../pages/lyrics_page_new.dart';
import 'playlist_popup.dart';
import 'liquid_glass_widget.dart';

class DraggablePlayerControlBar extends StatefulWidget {
  const DraggablePlayerControlBar({
    Key? key,
  }) : super(key: key);

  @override
  State<DraggablePlayerControlBar> createState() =>
      _DraggablePlayerControlBarState();
}

class _DraggablePlayerControlBarState extends State<DraggablePlayerControlBar>
    with TickerProviderStateMixin, WindowListener {
  bool _isHoveringPrevious = false;
  bool _isHoveringPlay = false;
  bool _isHoveringNext = false;
  bool _isHoveringPlaylist = false;
  Offset _position = const Offset(16, 0); // 初始位置，底部有16px的边距
  bool _isDragging = false;
  bool _hasMoved = false; // 是否发生了拖动
  bool _isPositionLoaded = false;
  bool _isInDetachedWindow = false; // 是否在独立窗口中
  Offset _windowPosition = Offset.zero; // 窗口位置
  Size? _windowSize; // 窗口大小
  Size? _screenSize; // 屏幕大小
  bool _isLocked = false; // 是否锁定播放器栏位置
  bool _isHoveringLock = false; // 是否悬停在锁定按钮上
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // 用于捕获组件快照

  @override
  void initState() {
    super.initState();
    // 检查是否在独立窗口中
    _checkIfInDetachedWindow();

    // 延迟加载位置，确保窗口尺寸已初始化
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadPosition();

      // 获取屏幕大小
      if (mounted) {
        setState(() {
          _screenSize = MediaQuery.of(context).size;
        });
      }
    });

    // 添加窗口监听器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从 PlayerBarProvider 加载位置
    final playerBarProvider =
        Provider.of<PlayerBarProvider>(context, listen: false);
    if (!_isPositionLoaded) {
      setState(() {
        _position = playerBarProvider.position;
        _isPositionLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // 检查是否在独立窗口中
  Future<void> _checkIfInDetachedWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      final isDetached = prefs.getBool('player_bar_detached') ?? false;

      if (mounted) {
        setState(() {
          _isInDetachedWindow = isDetached;
        });
      }
    }
  }

  @override
  void onWindowMove() async {
    if (_isInDetachedWindow &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();

      // 获取主窗口的位置和大小
      final mainWindowPosition = await windowManager.getPosition();
      final mainWindowSize = await windowManager.getSize();

      // 检查是否在主窗口范围内
      final isInMainWindow = _checkIfInMainWindow(
          position, size, mainWindowPosition, mainWindowSize);

      if (isInMainWindow) {
        // 如果在主窗口范围内，吸附回主窗口
        final playerBarProvider =
            Provider.of<PlayerBarProvider>(context, listen: false);
        await playerBarProvider.attach();

        if (mounted) {
          setState(() {
            _isInDetachedWindow = false;
            _position = Offset(16, 0); // 重置到主窗口底部位置
          });
        }
      }
    }
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('player_bar_x');
    final savedY = prefs.getDouble('player_bar_y');

    if (mounted) {
      setState(() {
        if (savedX != null && savedY != null && !_isInDetachedWindow) {
          // 使用保存的位置（仅在非独立窗口模式下）
          _position = Offset(savedX, savedY);
        } else {
          // 首次启动或在独立窗口模式下，设置默认位置在底部
          _position = const Offset(0, 0); // 初始位置，后续会自动吸附到底部
        }
        _isPositionLoaded = true;
      });

      // 如果在独立窗口中，加载窗口位置
      if (_isInDetachedWindow &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final windowX = prefs.getDouble('player_bar_window_x') ?? 100.0;
        final windowY = prefs.getDouble('player_bar_window_y') ?? 100.0;

        if (mounted) {
          setState(() {
            _windowPosition = Offset(windowX, windowY);
          });
        }
      }
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isInDetachedWindow) {
      // 仅在非独立窗口模式下保存位置
      await prefs.setDouble('player_bar_x', _position.dx);
      await prefs.setDouble('player_bar_y', _position.dy);
    } else {
      // 在独立窗口模式下，保存窗口位置
      await prefs.setDouble('player_bar_window_x', _windowPosition.dx);
      await prefs.setDouble('player_bar_window_y', _windowPosition.dy);
    }
  }

  // 检查播放器栏是否在主窗口范围内
  bool _checkIfInMainWindow(Offset barPosition, Size barSize,
      Offset mainWindowPosition, Size mainWindowSize) {
    // 计算播放器栏的中心点
    final barCenterX = barPosition.dx + barSize.width / 2;
    final barCenterY = barPosition.dy + barSize.height / 2;

    // 计算主窗口的范围
    final mainWindowLeft = mainWindowPosition.dx;
    final mainWindowRight = mainWindowPosition.dx + mainWindowSize.width;
    final mainWindowTop = mainWindowPosition.dy;
    final mainWindowBottom = mainWindowPosition.dy + mainWindowSize.height;

    // 检查播放器栏中心点是否在主窗口范围内
    return barCenterX >= mainWindowLeft &&
        barCenterX <= mainWindowRight &&
        barCenterY >= mainWindowTop &&
        barCenterY <= mainWindowBottom;
  }

  // 检查播放器栏是否在主窗口底部区域
  bool _checkIfInBottomArea(Offset barPosition, Size barSize,
      Offset mainWindowPosition, Size mainWindowSize) {
    // 计算播放器栏的中心点
    final barCenterX = barPosition.dx + barSize.width / 2;
    final barCenterY = barPosition.dy + barSize.height / 2;

    // 计算主窗口的范围
    final mainWindowLeft = mainWindowPosition.dx;
    final mainWindowRight = mainWindowPosition.dx + mainWindowSize.width;
    final mainWindowTop = mainWindowPosition.dy;
    final mainWindowBottom = mainWindowPosition.dy + mainWindowSize.height;

    // 定义底部区域（主窗口底部100像素）
    final bottomAreaTop = mainWindowBottom - 100;

    // 检查播放器栏中心点是否在主窗口底部区域
    return barCenterX >= mainWindowLeft &&
        barCenterX <= mainWindowRight &&
        barCenterY >= bottomAreaTop &&
        barCenterY <= mainWindowBottom;
  }

  // 检查是否拖出主窗口范围
  bool _checkIfDraggedOut(Offset barPosition, Size barSize,
      Offset mainWindowPosition, Size mainWindowSize) {
    // 在主窗口中，barPosition 是相对于窗口的偏移量
    // 我们需要考虑底部边距（16px）
    const bottomMargin = 16.0;
    const sideMargin = 16.0;

    // 计算播放器栏在窗口中的实际位置
    final barLeft = sideMargin + barPosition.dx;
    final barRight = sideMargin + barPosition.dx + barSize.width;
    final barTop = bottomMargin + barPosition.dy;
    final barBottom = bottomMargin + barPosition.dy + barSize.height;

    // 检查播放器栏是否超出了窗口边界
    return barLeft < 0 ||
        barRight > mainWindowSize.width ||
        barTop < 0 ||
        barBottom > mainWindowSize.height;
  }

  // 捕获组件快照并过渡到独立窗口
  Future<void> _captureAndTransitionToDetachedWindow(
    Offset barPosition,
    Size barSize,
    Offset mainWindowPosition,
  ) async {
    try {
      // 1. 捕获组件快照
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final base64Image = base64Encode(pngBytes);

      // 2. 计算独立窗口在屏幕上的位置
      final newWindowPosition = Offset(
        mainWindowPosition.dx + barPosition.dx,
        mainWindowPosition.dy + barPosition.dy,
      );

      // 3. 保存快照和位置信息
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('player_bar_snapshot', base64Image);
      await prefs.setDouble('player_bar_snapshot_x', newWindowPosition.dx);
      await prefs.setDouble('player_bar_snapshot_y', newWindowPosition.dy);
      await prefs.setDouble('player_bar_snapshot_width', barSize.width);
      await prefs.setDouble('player_bar_snapshot_height', barSize.height);

      // 4. 分离到独立窗口
      final playerBarProvider = Provider.of<PlayerBarProvider>(context, listen: false);
      await playerBarProvider.detachWithPosition(newWindowPosition);

      if (mounted) {
        setState(() {
          _isInDetachedWindow = true;
          _windowPosition = newWindowPosition;
          _position = Offset.zero;
        });
      }
    } catch (e) {
      print('捕获快照失败: $e');
      // 如果捕获失败，仍然分离到独立窗口
      final playerBarProvider = Provider.of<PlayerBarProvider>(context, listen: false);
      final newWindowPosition = Offset(
        mainWindowPosition.dx + barPosition.dx,
        mainWindowPosition.dy + barPosition.dy,
      );
      await playerBarProvider.detachWithPosition(newWindowPosition);

      if (mounted) {
        setState(() {
          _isInDetachedWindow = true;
          _windowPosition = newWindowPosition;
          _position = Offset.zero;
        });
      }
    }
  }

  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _hoverScale = 1.2;
  static const double _normalScale = 1.0;

  void _showPlaylistPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(bottom: 80, right: 20),
          child: PlaylistPopup(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentMusic = playerProvider.currentMusic;
        final isPlaying = playerProvider.isPlaying;

        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Material(
              color: Colors.transparent,
              elevation: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned(
                        left: _position.dx,
                        bottom: 16 + _position.dy,
                        right: 16,
                        child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    // 只有在没有拖动的情况下才响应点击
                    if (!_hasMoved) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return Consumer<SettingsProvider>(
                              builder: (context, settings, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      settings.windowBorderRadius),
                                  child: const LyricsPage(),
                                );
                              },
                            );
                          },
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    }
                  },
                  onPanStart: (details) async {
                    // 如果锁定，不允许拖动
                    if (_isLocked) return;

                    setState(() {
                      _isDragging = true;
                      _hasMoved = false;
                    });

                    // 获取窗口信息
                    if (Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isMacOS) {
                      _windowPosition = await windowManager.getPosition();
                      _windowSize = await windowManager.getSize();
                    }
                  },
                  onPanUpdate: (details) async {
                    // 如果锁定，不允许拖动
                    if (_isLocked) return;

                    if (_isInDetachedWindow) {
                      // 在独立窗口模式下，更新窗口位置
                      if (Platform.isWindows ||
                          Platform.isLinux ||
                          Platform.isMacOS) {
                        _windowPosition += details.delta;
                        await windowManager.setPosition(_windowPosition);
                      }
                    } else {
                      // 在主窗口模式下，更新播放器栏位置
                      setState(() {
                        _position += details.delta;
                        _hasMoved = true;
                      });

                      // 检查是否拖出主窗口范围
                      if (_windowSize != null) {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final barSize = renderBox.size;
                          final barPosition = _position;

                          // 获取主窗口位置
                          final mainWindowPosition =
                              await windowManager.getPosition();

                          // 检查是否拖出主窗口范围
                          final isDraggedOut = _checkIfDraggedOut(
                              barPosition,
                              barSize,
                              mainWindowPosition,
                              _windowSize!);

                          if (isDraggedOut) {
                            // 捕获组件快照
                            await _captureAndTransitionToDetachedWindow(
                              barPosition,
                              barSize,
                              mainWindowPosition,
                            );
                          }
                        }
                      }
                    }
                  },
                  onPanEnd: (details) async {
                    setState(() {
                      _isDragging = false;
                    });

                    // 如果在独立窗口中，保存窗口位置
                    if (_isInDetachedWindow &&
                        (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS)) {
                      final playerBarProvider = Provider.of<PlayerBarProvider>(
                          context,
                          listen: false);
                      await playerBarProvider
                          .saveWindowPosition(_windowPosition);

                      // 检查是否应该吸附回主窗口
                      final mainWindowPosition =
                          await windowManager.getPosition();
                      final mainWindowSize = await windowManager.getSize();
                      final isInMainWindow = _checkIfInMainWindow(
                          _windowPosition,
                          Size(600, 80), // 假设播放器栏窗口大小
                          mainWindowPosition,
                          mainWindowSize);

                      if (isInMainWindow) {
                        // 如果在主窗口范围内，吸附回主窗口
                        await playerBarProvider.attach();
                        if (mounted) {
                          setState(() {
                            _isInDetachedWindow = false;
                            _position = Offset.zero; // 重置位置，会自动吸附到底部
                          });
                        }
                      }
                    } else {
                      // 在主窗口中，检查是否需要吸附到底部
                      if (_windowSize != null) {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final barSize = renderBox.size;
                          final barPosition = _position;

                          // 获取主窗口位置
                          final mainWindowPosition =
                              await windowManager.getPosition();

                          // 检查是否拖出主窗口范围
                          final isDraggedOut = _checkIfDraggedOut(
                              barPosition,
                              barSize,
                              mainWindowPosition,
                              _windowSize!);

                          if (isDraggedOut) {
                            // 如果拖出主窗口范围，分离到独立窗口
                            await _captureAndTransitionToDetachedWindow(
                              barPosition,
                              barSize,
                              mainWindowPosition,
                            );
                          } else {
                            // 在主窗口内释放，自动吸附到底部
                            setState(() {
                              _position = const Offset(16, 0);
                            });
                          }
                        }
                      }

                      // 保存播放器栏位置
                      await _savePosition();
                    }
                  },
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: LiquidGlassWidget(
                      enabled: settings.usePlayerGlass,
                      borderRadius: settings.borderRadius,
                      child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(settings.borderRadius),
                      child: BackdropFilter(
                        filter: settings.usePlayerGlass
                            ? ImageFilter.blur(sigmaX: 30, sigmaY: 30)
                            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: settings.usePlayerGlass
                                ? Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(settings.glassOpacity)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(settings.borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 30,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 专辑封面
                              Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          settings.borderRadius),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.2),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          settings.borderRadius),
                                      child: currentMusic?.coverArt != null
                                          ? Image.memory(
                                              currentMusic!.coverArt!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  AppIcons.musicNote,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                  size: 28,
                                                );
                                              },
                                            )
                                          : Icon(
                                              AppIcons.musicNote,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                              size: 28,
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // 歌曲信息
                              Expanded(
                                child: Consumer<SettingsProvider>(
                                  builder: (context, settings, child) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                currentMusic?.title ?? '未播放',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentMusic?.artist ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 播放控制按钮
                              Row(
                                children: [
                                  // 上一曲
                                  MouseRegion(
                                    onEnter: (_) => setState(
                                        () => _isHoveringPrevious = true),
                                    onExit: (_) => setState(
                                        () => _isHoveringPrevious = false),
                                    child: Consumer<SettingsProvider>(
                                      builder: (context, settings, child) {
                                        return Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          child: InkWell(
                                            onTap: () =>
                                                playerProvider.playPrevious(),
                                            borderRadius: BorderRadius.circular(
                                                settings.borderRadius),
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: AnimatedScale(
                                                scale: _isHoveringPrevious
                                                    ? _hoverScale
                                                    : _normalScale,
                                                duration: _animationDuration,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .backward_end_fill,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.8),
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 播放/暂停
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _isHoveringPlay = true),
                                    onExit: (_) =>
                                        setState(() => _isHoveringPlay = false),
                                    child: Consumer<SettingsProvider>(
                                      builder: (context, settings, child) {
                                        return Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          child: InkWell(
                                            onTap: () {
                                              final wasPlaying =
                                                  playerProvider.isPlaying;
                                              playerProvider.togglePlayPause();

                                              // 处理倒计时
                                              if (playerProvider.timerMinutes !=
                                                  null) {
                                                if (wasPlaying) {
                                                  // 暂停播放时，暂停倒计时
                                                  playerProvider.pauseTimer();
                                                } else {
                                                  // 恢复播放时，恢复倒计时
                                                  playerProvider.resumeTimer();
                                                }
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                                settings.borderRadius),
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: AnimatedScale(
                                                scale: _isHoveringPlay
                                                    ? _hoverScale
                                                    : _normalScale,
                                                duration: _animationDuration,
                                                child: Icon(
                                                  isPlaying
                                                      ? CupertinoIcons
                                                          .pause_fill
                                                      : CupertinoIcons
                                                          .play_fill,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.8),
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 下一曲
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _isHoveringNext = true),
                                    onExit: (_) =>
                                        setState(() => _isHoveringNext = false),
                                    child: Consumer<SettingsProvider>(
                                      builder: (context, settings, child) {
                                        return Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          child: InkWell(
                                            onTap: () =>
                                                playerProvider.playNext(),
                                            borderRadius: BorderRadius.circular(
                                                settings.borderRadius),
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: AnimatedScale(
                                                scale: _isHoveringNext
                                                    ? _hoverScale
                                                    : _normalScale,
                                                duration: _animationDuration,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .forward_end_fill,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.8),
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // 锁定/解锁按钮
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isHoveringLock = true),
                                onExit: (_) =>
                                    setState(() => _isHoveringLock = false),
                                child: Consumer<SettingsProvider>(
                                  builder: (context, settings, child) {
                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                          settings.borderRadius),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isLocked = !_isLocked;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(
                                            settings.borderRadius),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: AnimatedScale(
                                            scale: _isHoveringLock
                                                ? _hoverScale
                                                : _normalScale,
                                            duration: _animationDuration,
                                            child: Icon(
                                              _isLocked
                                                  ? CupertinoIcons.lock_fill
                                                  : CupertinoIcons.lock_open_fill,
                                              color: _isLocked
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 播放列表按钮
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isHoveringPlaylist = true),
                                onExit: (_) =>
                                    setState(() => _isHoveringPlaylist = false),
                                child: Consumer<SettingsProvider>(
                                  builder: (context, settings, child) {
                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                          settings.borderRadius),
                                      child: InkWell(
                                        onTap: () =>
                                            _showPlaylistPopup(context),
                                        borderRadius: BorderRadius.circular(
                                            settings.borderRadius),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: AnimatedScale(
                                            scale: _isHoveringPlaylist
                                                ? _hoverScale
                                                : _normalScale,
                                            duration: _animationDuration,
                                            child: Icon(
                                              AppIcons.playlist,
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color
                                                  ?.withOpacity(0.7),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                      ),
                    ],
                  );
                },
              ),
          );
        },
      );
      },
    );
  }
}
      
