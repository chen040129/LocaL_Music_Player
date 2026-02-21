import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluid_background/fluid_background.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_icons.dart';
import '../widgets/lyrics_widget_new.dart' as lyrics_widgets;
import '../widgets/album_cover_widget.dart';

class LyricsPageWithCover extends StatefulWidget {
  const LyricsPageWithCover({Key? key}) : super(key: key);

  @override
  State<LyricsPageWithCover> createState() => _LyricsPageWithCoverState();
}

class _LyricsPageWithCoverState extends State<LyricsPageWithCover>
    with TickerProviderStateMixin {
  bool _isHoveringPin = false;
  bool _isHoveringMinimize = false;
  bool _isHoveringMaximize = false;
  bool _isHoveringClose = false;
  bool _isAlwaysOnTop = false;
  bool _isLiked = false;
  double _volume = 0.7;
  bool _isDragging = false;
  double _dragPosition = 0.0;
  bool _isHoveringProgress = false;
  double _coverDragStartX = 0.0;
  double _coverDragCurrentX = 0.0;
  double _coverDragOffset = 0.0; // 拖动偏移量，用于反馈
  int _currentPage = 0; // 0: 歌曲信息, 1: 播放列表
  bool _showVolumeControl = false;
  bool _isImmersiveMode = false; // 沉浸模式状态

  // 按钮悬停状态
  bool _isPlaylistHovered = false;
  bool _isTimerHovered = false;
  bool _isPlayModeHovered = false;
  bool _isHoveringPrevious = false;
  bool _isHoveringPlayPause = false;
  bool _isHoveringNext = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pageSwitchController;
  late Animation<double> _pageSwitchAnimation;

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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _pageSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageSwitchAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_pageSwitchController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageSwitchController.dispose();
    // 恢复窗口透明度
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.setOpacity(1.0);
    }
    super.dispose();
  }

  Future<void> _checkAlwaysOnTop() async {
    final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    if (mounted) {
      setState(() {
        _isAlwaysOnTop = isAlwaysOnTop;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getActiveTrackColor(
      PlayerProvider playerProvider, ColorScheme colorScheme) {
    try {
      final coverColor = playerProvider.currentMusic?.coverColor;
      if (coverColor != null && coverColor.isFinite) {
        // 确保颜色值在有效范围内
        if (coverColor >= 0 && coverColor <= 0xFFFFFFFF) {
          final color = Color(coverColor);
          // 检查颜色值是否有效
          if (color.alpha >= 0 &&
              color.alpha <= 255 &&
              color.red >= 0 &&
              color.red <= 255 &&
              color.green >= 0 &&
              color.green <= 255 &&
              color.blue >= 0 &&
              color.blue <= 255) {
            return color;
          }
        }
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }
    return colorScheme.primary;
  }

  /// 构建渐变背景
  Widget _buildGradientBackground(PlayerProvider playerProvider,
      SettingsProvider settings, ColorScheme colorScheme) {
    // 获取歌曲主题色
    Color? songColor;
    try {
      final coverColor = playerProvider.currentMusic?.coverColor;
      if (coverColor != null && coverColor.isFinite) {
        if (coverColor >= 0 && coverColor <= 0xFFFFFFFF) {
          final color = Color(coverColor);
          if (color.alpha >= 0 &&
              color.alpha <= 255 &&
              color.red >= 0 &&
              color.red <= 255 &&
              color.green >= 0 &&
              color.green <= 255 &&
              color.blue >= 0 &&
              color.blue <= 255) {
            songColor = color;
          }
        }
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }

    // 如果歌曲没有主题色，使用黑色
    final topLeftColor = songColor ?? Colors.black;

    // 软件主题色：根据深色/浅色模式自动切换黑色或白色
    final bottomRightColor =
        colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white;

    if (settings.gradientType == GradientType.dynamic) {
      // 动态渐变
      return AnimatedContainer(
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topLeftColor,
              Color.lerp(topLeftColor, bottomRightColor,
                  1 - settings.gradientSongColorRatio)!,
              bottomRightColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    } else {
      // 静态渐变
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topLeftColor,
              Color.lerp(topLeftColor, bottomRightColor,
                  1 - settings.gradientSongColorRatio)!,
              bottomRightColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
  }

  /// 构建纯色背景
  Widget _buildSolidBackground(
      PlayerProvider playerProvider, ColorScheme colorScheme) {
    // 获取歌曲主题色
    Color? songColor;
    try {
      final coverColor = playerProvider.currentMusic?.coverColor;
      if (coverColor != null && coverColor.isFinite) {
        if (coverColor >= 0 && coverColor <= 0xFFFFFFFF) {
          final color = Color(coverColor);
          if (color.alpha >= 0 &&
              color.alpha <= 255 &&
              color.red >= 0 &&
              color.red <= 255 &&
              color.green >= 0 &&
              color.green <= 255 &&
              color.blue >= 0 &&
              color.blue <= 255) {
            songColor = color;
          }
        }
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }

    // 如果歌曲没有主题色，使用黑色
    return Container(
      color: songColor ?? Colors.black,
    );
  }

  /// 构建流体背景
  Widget _buildFluidBackground(
      PlayerProvider playerProvider, SettingsProvider settings) {
    // 获取歌曲封面颜色
    final music = playerProvider.currentMusic;
    Color? primaryColor;
    Color? secondaryColor;
    Color? tertiaryColor;

    try {
      if (music?.coverColor != null &&
          music!.coverColor! >= 0 &&
          music.coverColor! <= 0xFFFFFFFF) {
        primaryColor = Color(music.coverColor!);
      }
      if (music?.secondaryColor != null &&
          music!.secondaryColor! >= 0 &&
          music.secondaryColor! <= 0xFFFFFFFF) {
        secondaryColor = Color(music.secondaryColor!);
      }
      if (music?.tertiaryColor != null &&
          music!.tertiaryColor! >= 0 &&
          music.tertiaryColor! <= 0xFFFFFFFF) {
        tertiaryColor = Color(music.tertiaryColor!);
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }

    // 使用歌曲封面颜色，如果没有则使用默认颜色
    final colors = [
      primaryColor ?? Colors.blue,
      secondaryColor ?? Colors.purple,
      tertiaryColor ?? Colors.indigo,
      Colors.black,
    ];

    return FluidBackground(
      key: ValueKey('fluid_${music?.id ?? 0}'),
      initialPositions: InitialOffsets.custom([
        const Offset(0.3, 0.5),
        const Offset(0.7, 0.3),
        const Offset(0.2, 0.8),
        const Offset(0.8, 0.7),
      ]),
      initialColors: InitialColors.custom(colors),
      bubblesSize: settings.fluidBubblesSize,
      velocity: settings.isFluidDynamic ? settings.fluidVelocity : 0,
      bubbleMutationDuration: settings.isFluidDynamic
          ? Duration(milliseconds: settings.fluidAnimationDuration)
          : null,
      allowColorChanging: true,
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentMusic = playerProvider.currentMusic;
        final isPlaying = playerProvider.isPlaying;
        final position = playerProvider.position;
        final duration = playerProvider.duration;
        final progress = playerProvider.progressPercent;
        final playMode = playerProvider.playMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Container(
                decoration: BoxDecoration(
                  color: settings.songPageBackgroundType ==
                          SongPageBackgroundType.transparent
                      ? Colors.transparent
                      : colorScheme.surface,
                ),
                child: Stack(
                  children: [
                    // 根据背景类型显示不同的背景
                    Positioned.fill(
                      child: Consumer2<PlayerProvider, SettingsProvider>(
                        builder: (context, player, settings, child) {
                          switch (settings.songPageBackgroundType) {
                            case SongPageBackgroundType.transparent:
                              // 透明背景：使用设置的透明度
                              return Container(
                                color: Colors.black
                                    .withOpacity(1.0 - settings.pageOpacity),
                              );
                            case SongPageBackgroundType.fluid:
                              return _buildFluidBackground(player, settings);
                            case SongPageBackgroundType.blur:
                              if (currentMusic?.coverArt != null) {
                                return Opacity(
                                  opacity: 0.3,
                                  child: ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                      sigmaX: settings.blurAmount,
                                      sigmaY: settings.blurAmount,
                                    ),
                                    child: Image.memory(
                                      currentMusic!.coverArt!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                color: colorScheme.surface,
                              );
                            case SongPageBackgroundType.gradient:
                              return _buildGradientBackground(
                                  playerProvider, settings, colorScheme);
                            case SongPageBackgroundType.solid:
                              return _buildSolidBackground(
                                  playerProvider, colorScheme);
                            case SongPageBackgroundType.customImage:
                              if (settings.customImagePath.isNotEmpty) {
                                BoxFit boxFit;
                                switch (settings.imageFitType) {
                                  case ImageFitType.fill:
                                    boxFit = BoxFit.fill;
                                    break;
                                  case ImageFitType.cover:
                                    boxFit = BoxFit.fill;
                                    break;
                                  case ImageFitType.contain:
                                    boxFit = BoxFit.fill;
                                    break;
                                  case ImageFitType.fitWidth:
                                    boxFit = BoxFit.fill;
                                    break;
                                  case ImageFitType.fitHeight:
                                    boxFit = BoxFit.fill;
                                    break;
                                  case ImageFitType.none:
                                    boxFit = BoxFit.fill;
                                    break;
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: Image.file(
                                    File(settings.customImagePath),
                                    fit: boxFit,
                                  ),
                                );
                              }
                              return Container(
                                color: colorScheme.surface,
                              );
                          }
                        },
                      ),
                    ),
                    // 主内容区域
                    SafeArea(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // 顶部信息栏
                            AnimatedOpacity(
                              opacity: _isImmersiveMode ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 32, left: 16, right: 16),
                                child: Row(
                                  children: [
                                    // 回退按钮
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.back),
                                      color: colorScheme.onSurface,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    const SizedBox(width: 12),
                                    // 歌曲信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentMusic?.title ?? '未播放',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currentMusic?.artist ?? '未知艺术家',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
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
                            const SizedBox(height: 32),
                            // 主内容区：左侧封面和控制区 + 右侧歌词区
                            Expanded(
                              child: Row(
                                children: [
                                  // 左侧封面和控制区
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 48),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // 根据当前页面显示不同内容
                                          _currentPage == 0
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                      // 专辑封面
                                                      GestureDetector(
                                                        onTap: () {
                                                          // 点击封面切换沉浸模式
                                                          setState(() {
                                                            _isImmersiveMode = !_isImmersiveMode;
                                                          });
                                                        },
                                                        onHorizontalDragStart: (details) {
                                                          setState(() {
                                                            _coverDragStartX = details.globalPosition.dx;
                                                            _coverDragCurrentX = details.globalPosition.dx;
                                                            _coverDragOffset = 0.0;
                                                          });
                                                        },
                                                        onHorizontalDragUpdate: (details) {
                                                          setState(() {
                                                            _coverDragCurrentX = details.globalPosition.dx;
                                                            final dragDistance = _coverDragCurrentX - _coverDragStartX;
                                                            // 只允许向右拖动，限制偏移量在 0 到 200 之间
                                                            _coverDragOffset = dragDistance.clamp(0.0, 200.0);
                                                          });
                                                        },
                                                        onHorizontalDragEnd: (details) {
                                                          final dragDistance = _coverDragCurrentX - _coverDragStartX;
                                                          if (dragDistance > 100) {
                                                            // 向右拖动，切换到播放列表
                                                            setState(() {
                                                              _currentPage = 1;
                                                              _coverDragOffset = 0.0;
                                                            });
                                                          }
                                                          setState(() {
                                                            _coverDragStartX = 0.0;
                                                            _coverDragCurrentX = 0.0;
                                                            _coverDragOffset = 0.0;
                                                          });
                                                        },
                                                        child: AnimatedBuilder(
                                                          animation: _pageSwitchAnimation,
                                                          builder: (context, child) {
                                                            return Transform.scale(
                                                              scale: 1.0 - _pageSwitchAnimation.value * 0.2,
                                                              child: Opacity(
                                                                opacity: 1.0 - _pageSwitchAnimation.value * 0.8,
                                                                child: Transform.translate(
                                                                  offset: Offset(_coverDragOffset * 0.3, 0),
                                                                  child: Opacity(
                                                                    opacity: 1 - (_coverDragOffset.abs() / 400),
                                                                    child: AlbumCoverWidget(),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 32),
                                                      // 控制区
                                                      // 这里添加控制按钮的代码...
                                                    ],
                                                  )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 右侧歌词区
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 48, top: 32, bottom: 32),
                                      child: Consumer<PlayerProvider>(
                                        builder: (context, player, child) {
                                          return lyrics_widgets.LyricsWidgetNew(
                                            lyrics: player.currentLyrics,
                                            position: player.position,
                                            settings: settings,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
