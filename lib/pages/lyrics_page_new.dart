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
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_icons.dart';
import '../widgets/lyrics_widget_new.dart' as lyrics_widgets;

// 自定义SliderTrackShape，用于控制进度条的宽度
class CustomSliderTrackShape extends SliderTrackShape {
  final double trackWidth;

  const CustomSliderTrackShape({this.trackWidth = 60});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = this.trackWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Canvas canvas = context.canvas;
    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.fill;

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.fill;

    final double trackHeight = sliderTheme.trackHeight!;
    // 计算激活轨道的宽度，基于滑块中心点相对于轨道的位置
    final double relativeThumbPosition = (thumbCenter.dx - trackRect.left) / trackRect.width;
    final double activeTrackWidth = trackRect.width * relativeThumbPosition.clamp(0.0, 1.0);

    // 绘制非激活轨道
    canvas.drawRect(
      Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        trackRect.width,
        trackHeight,
      ),
      inactivePaint,
    );

    // 绘制激活轨道
    canvas.drawRect(
      Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        activeTrackWidth,
        trackHeight,
      ),
      activePaint,
    );
  }
}

class LyricsPage extends StatefulWidget {
  const LyricsPage({Key? key}) : super(key: key);

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> with TickerProviderStateMixin {
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

  Color _getActiveTrackColor(PlayerProvider playerProvider, ColorScheme colorScheme) {
    try {
      final coverColor = playerProvider.currentMusic?.coverColor;
      if (coverColor != null && coverColor.isFinite) {
        // 确保颜色值在有效范围内
        if (coverColor >= 0 && coverColor <= 0xFFFFFFFF) {
          final color = Color(coverColor);
          // 检查颜色值是否有效
          if (color.alpha >= 0 && color.alpha <= 255 &&
              color.red >= 0 && color.red <= 255 &&
              color.green >= 0 && color.green <= 255 &&
              color.blue >= 0 && color.blue <= 255) {
            return color;
          }
        }
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }
    return colorScheme.primary;
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
          body: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Padding(
                padding: EdgeInsets.all(settings.windowBorderRadius > 0 ? settings.windowBorderRadius * 0.3 : 0),
                child: Stack(
                  children: [
                    // 背景模糊效果
              if (currentMusic?.coverArt != null)
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    if (!settings.useBlurBackground) {
                      return const SizedBox.shrink();
                    }
                    return Positioned.fill(
                      child: Opacity(
                        opacity: 0.3,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Image.memory(
                            currentMusic!.coverArt!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // 渐变遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withOpacity(0.7),
                        colorScheme.surface.withOpacity(0.85),
                        colorScheme.surface.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // 主内容区域
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // 顶部信息栏
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 32, left: 16, right: 16),
                        child: Row(
                          children: [
                            // 回退按钮
                            IconButton(
                              icon: const Icon(CupertinoIcons.back),
                              color: colorScheme.onSurface,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                            // 歌曲信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 32),
                      // 主内容区：左侧封面和控制区 + 右侧歌词区
                      Expanded(
                        child: Row(
                          children: [
                            // 左侧封面和控制区
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 48),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 根据当前页面显示不同内容
                                    _currentPage == 0
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                                // 专辑封面
                                                Consumer<SettingsProvider>(
                                                  builder: (context, settings, child) {
                                                    if (!settings.showAlbumArt) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return LayoutBuilder(
                                                      builder:
                                                          (context, constraints) {
                                                        // 获取整个窗口的宽度
                                                        final windowWidth =
                                                            MediaQuery.of(context)
                                                                .size
                                                                .width;
                                                        // 根据窗口宽度计算封面大小，使用更平滑的比例
                                                        final size = (windowWidth *
                                                                0.25)
                                                            .clamp(330.0, 700.0);
                                                        return GestureDetector(
                                                      onHorizontalDragStart:
                                                          (details) {
                                                        setState(() {
                                                          _coverDragStartX =
                                                              details
                                                                  .globalPosition
                                                                  .dx;
                                                          _coverDragCurrentX =
                                                              details
                                                                  .globalPosition
                                                                  .dx;
                                                          _coverDragOffset =
                                                              0.0;
                                                        });
                                                      },
                                                      onHorizontalDragUpdate:
                                                          (details) {
                                                        setState(() {
                                                          _coverDragCurrentX =
                                                              details
                                                                  .globalPosition
                                                                  .dx;
                                                          final dragDistance =
                                                              _coverDragCurrentX -
                                                                  _coverDragStartX;
                                                          // 只允许向右拖动，限制偏移量在 0 到 200 之间
                                                          _coverDragOffset =
                                                              dragDistance
                                                                  .clamp(0.0,
                                                                      200.0);
                                                        });
                                                      },
                                                      onHorizontalDragEnd:
                                                          (details) {
                                                        final dragDistance =
                                                            _coverDragCurrentX -
                                                                _coverDragStartX;
                                                        if (dragDistance >
                                                            100) {
                                                          // 向右拖动，切换到播放列表
                                                          setState(() {
                                                            _currentPage = 1;
                                                            _coverDragOffset =
                                                                0.0;
                                                          });
                                                        }
                                                        setState(() {
                                                          _coverDragStartX =
                                                              0.0;
                                                          _coverDragCurrentX =
                                                              0.0;
                                                          _coverDragOffset =
                                                              0.0;
                                                        });
                                                      },
                                                      child: AnimatedBuilder(
                                                        animation:
                                                            _pageSwitchAnimation,
                                                        builder:
                                                            (context, child) {
                                                          return Transform.scale(
                                                            scale: 1.0 -
                                                                _pageSwitchAnimation.value *
                                                                    0.2,
                                                            child: Opacity(
                                                              opacity: 1.0 -
                                                                  _pageSwitchAnimation.value *
                                                                      0.8,
                                                              child: Transform.translate(
                                                                offset: Offset(
                                                                    _coverDragOffset *
                                                                            0.3,
                                                                    0),
                                                                child: Opacity(
                                                                  opacity: 1 -
                                                                      (_coverDragOffset
                                                                                  .abs() /
                                                                              400),
                                                                  child: child,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: SizedBox(
                                                          width: size,
                                                          height: size,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.2),
                                                                  blurRadius:
                                                                      20,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 8),
                                                                ),
                                                              ],
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              child: currentMusic
                                                                          ?.coverArt !=
                                                                      null
                                                                  ? Image
                                                                      .memory(
                                                                      currentMusic!
                                                                          .coverArt!,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    )
                                                                  : Container(
                                                                      color: colorScheme
                                                                          .surfaceContainerHighest,
                                                                      child:
                                                                          Icon(
                                                                        AppIcons
                                                                            .musicNote,
                                                                        size:
                                                                            80,
                                                                        color: colorScheme
                                                                            .onSurface
                                                                            .withOpacity(0.3),
                                                                      ),
                                                                    ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 32),
                                                // 控制区
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // 进度条
                                                    MouseRegion(
                                                      onEnter: (_) => setState(
                                                          () =>
                                                              _isHoveringProgress =
                                                                  true),
                                                      onExit: (_) => setState(() =>
                                                          _isHoveringProgress =
                                                              false),
                                                      child: Listener(
                                                        onPointerSignal: (pointerSignal) {
                                                          if (pointerSignal is PointerScrollEvent && _showVolumeControl) {
                                                            // 限制单次滚动的最大调整量，防止快速滚动时超出范围
                                                            final delta = (pointerSignal.scrollDelta.dy * 0.001).clamp(-0.1, 0.1);
                                                            final newProgress = (progress - delta).clamp(0.0, 1.0);
                                                            playerProvider.seekToPercent(newProgress);
                                                          }
                                                        },
                                                        child: Focus(
                                                          onKeyEvent: (node, event) {
                                                            if (_showVolumeControl && event is KeyDownEvent) {
                                                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                                                final newProgress = (progress - 0.05).clamp(0.0, 1.0);
                                                                playerProvider.seekToPercent(newProgress);
                                                                return KeyEventResult.handled;
                                                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                                                final newProgress = (progress + 0.05).clamp(0.0, 1.0);
                                                                playerProvider.seekToPercent(newProgress);
                                                                return KeyEventResult.handled;
                                                              }
                                                            }
                                                            return KeyEventResult.ignored;
                                                          },
                                                          child: Row(
                                                            children: [
                                                              AnimatedOpacity(
                                                                opacity:
                                                                    _isHoveringProgress
                                                                        ? 1.0
                                                                        : 0.0,
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            200),
                                                                child: Text(
                                                                  _formatDuration(
                                                                      position),
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.6),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 12),
                                                              Expanded(
                                                                child: SliderTheme(
                                                                  data: SliderTheme
                                                                          .of(context)
                                                                      .copyWith(
                                                                    trackHeight: 3,
                                                                    thumbShape:
                                                                        const RoundSliderThumbShape(
                                                                            enabledThumbRadius:
                                                                                0),
                                                                    overlayShape:
                                                                        const RoundSliderOverlayShape(
                                                                            overlayRadius:
                                                                                0),
                                                                    activeTrackColor: currentMusic
                                                                                ?.coverColor !=
                                                                            null
                                                                        ? Color(currentMusic!
                                                                            .coverColor!)
                                                                        : colorScheme
                                                                            .primary,
                                                                    inactiveTrackColor:
                                                                        colorScheme
                                                                            .onSurface
                                                                            .withOpacity(
                                                                                0.2),
                                                                    thumbColor: Colors
                                                                        .transparent,
                                                                    overlayColor: Colors
                                                                        .transparent,
                                                                  ),
                                                                  child: Slider(
                                                                    value: _isDragging
                                                                        ? _dragPosition.clamp(0.0, 1.0)
                                                                        : progress.clamp(0.0, 1.0),
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(() {
                                                                        _isDragging =
                                                                            true;
                                                                        _dragPosition =
                                                                            value.clamp(0.0, 1.0);
                                                                      });
                                                                    },
                                                                    onChangeEnd:
                                                                        (value) {
                                                                      setState(() {
                                                                        _isDragging =
                                                                            false;
                                                                      });
                                                                      playerProvider
                                                                          .seekToPercent(
                                                                              value.clamp(0.0, 1.0));
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                          const SizedBox(
                                                              width: 12),
                                                          AnimatedOpacity(
                                                            opacity:
                                                                _isHoveringProgress
                                                                    ? 1.0
                                                                    : 0.0,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        200),
                                                            child: Text(
                                                              _formatDuration(
                                                                  duration),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                        0.6),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 0),
                                                    // 播放控制按钮
                                                    Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // 主播放控制行（上一曲、播放/暂停、下一曲）
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // 上一曲
                                                            MouseRegion(
                                                              onEnter: (_) => setState(() => _isHoveringPrevious = true),
                                                              onExit: (_) => setState(() => _isHoveringPrevious = false),
                                                              child: InkWell(
                                                                onTap: () => playerProvider.playPrevious(),
                                                                splashColor: Colors.transparent,
                                                                highlightColor: Colors.transparent,
                                                                hoverColor: Colors.transparent,
                                                                child: AnimatedScale(
                                                                  scale: _isHoveringPrevious ? _hoverScale : _normalScale,
                                                                  duration: _animationDuration,
                                                                  child: Icon(
                                                                      CupertinoIcons.backward_end_fill,
                                                                      color: _isHoveringPrevious
                                                                          ? colorScheme.primary
                                                                          : colorScheme.onSurface.withOpacity(0.8),
                                                                      size: 32,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 20),
                                                            // 播放/暂停
                                                            MouseRegion(
                                                              onEnter: (_) => setState(() => _isHoveringPlayPause = true),
                                                              onExit: (_) => setState(() => _isHoveringPlayPause = false),
                                                              child: InkWell(
                                                                onTap: () {
                                                                    playerProvider.togglePlayPause();
                                                                  },
                                                                splashColor: Colors.transparent,
                                                                highlightColor: Colors.transparent,
                                                                hoverColor: Colors.transparent,
                                                                child: AnimatedScale(
                                                                  scale: _isHoveringPlayPause ? _hoverScale : _normalScale,
                                                                  duration: _animationDuration,
                                                                  child: Icon(
                                                                    isPlaying
                                                                        ? CupertinoIcons.pause_fill
                                                                        : CupertinoIcons.play_fill,
                                                                    color: _isHoveringPlayPause
                                                                        ? colorScheme.primary
                                                                        : colorScheme.onSurface.withOpacity(0.8),
                                                                    size: 44,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 20),
                                                            // 下一曲
                                                            MouseRegion(
                                                              onEnter: (_) => setState(() => _isHoveringNext = true),
                                                              onExit: (_) => setState(() => _isHoveringNext = false),
                                                              child: InkWell(
                                                                onTap: () => playerProvider.playNext(),
                                                                splashColor: Colors.transparent,
                                                                highlightColor: Colors.transparent,
                                                                hoverColor: Colors.transparent,
                                                                child: AnimatedScale(
                                                                  scale: _isHoveringNext ? _hoverScale : _normalScale,
                                                                  duration: _animationDuration,
                                                                  child: Icon(
                                                                      CupertinoIcons.forward_end_fill,
                                                                      color: _isHoveringNext
                                                                          ? colorScheme.primary
                                                                          : colorScheme.onSurface.withOpacity(0.8),
                                                                      size: 32,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        // 次级控制行（音量、播放列表、定时播放、循环模式）
                                                        SizedBox(
                                                          width: 400, // 与主播放控制行的总宽度一致（32+20+44+20+32=148，加上一些边距）
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                            children: [
                                                              // 音量调节
                                                              MouseRegion(
                                                                onEnter: (_) => setState(() => _showVolumeControl = true),
                                                                onExit: (_) => setState(() => _showVolumeControl = false),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Listener(
                                                                      onPointerSignal: (pointerSignal) {
                                                                        if (pointerSignal is PointerScrollEvent) {
                                                                          // 限制单次滚动的最大调整量，防止快速滚动时超出范围
                                                                          final delta = (pointerSignal.scrollDelta.dy * 0.001).clamp(-0.1, 0.1);
                                                                          final newVolume = (_volume - delta).clamp(0.0, 1.0);
                                                                          setState(() {
                                                                            _volume = newVolume;
                                                                          });
                                                                          playerProvider.setVolume(newVolume);
                                                                        }
                                                                      },
                                                                      child: Focus(
                                                                        onKeyEvent: (node, event) {
                                                                          if (event is KeyDownEvent) {
                                                                            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                                                              setState(() {
                                                                                _volume = (_volume - 0.05).clamp(0.0, 1.0);
                                                                              });
                                                                              playerProvider.setVolume(_volume);
                                                                              return KeyEventResult.handled;
                                                                            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                                                              setState(() {
                                                                                _volume = (_volume + 0.05).clamp(0.0, 1.0);
                                                                              });
                                                                              playerProvider.setVolume(_volume);
                                                                              return KeyEventResult.handled;
                                                                            }
                                                                          }
                                                                          return KeyEventResult.ignored;
                                                                        },
                                                                        child: IconButton(
                                                                          splashColor: Colors.transparent,
                                                                          highlightColor: Colors.transparent,
                                                                          hoverColor: Colors.transparent,
                                                                          icon: AnimatedScale(
                                                                            scale: _showVolumeControl ? _hoverScale : _normalScale,
                                                                            duration: _animationDuration,
                                                                            child: Icon(
                                                                              _volume > 0
                                                                                  ? CupertinoIcons.speaker_2_fill
                                                                                  : CupertinoIcons.speaker_slash,
                                                                              color: _showVolumeControl
                                                                                  ? colorScheme.primary
                                                                                  : colorScheme.onSurface.withOpacity(0.7),
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              _volume = _volume > 0 ? 0.0 : 0.7;
                                                                            });
                                                                            playerProvider.setVolume(_volume);
                                                                          },
                                                                          padding: EdgeInsets.zero,
                                                                          constraints: const BoxConstraints(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    // 音量控制条
                                                                    if (_showVolumeControl)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(left: 8),
                                                                        child: Container(
                                                                          width: 280,
                                                                          decoration: BoxDecoration(
                                                                            gradient: LinearGradient(
                                                                              begin: Alignment.topLeft,
                                                                              end: Alignment.bottomRight,
                                                                              colors: [
                                                                                colorScheme.surface.withOpacity(0.7),
                                                                                colorScheme.surface.withOpacity(0.85),
                                                                                colorScheme.surface.withOpacity(0.95),
                                                                              ],
                                                                              stops: const [0.0, 0.3, 1.0],
                                                                            ),
                                                                            borderRadius: BorderRadius.circular(8),
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                          child: SliderTheme(
                                                                            data: SliderThemeData(
                                                                              trackHeight: 3,
                                                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                                                                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                                                                              activeTrackColor: _getActiveTrackColor(playerProvider, colorScheme),
                                                                              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
                                                                              thumbColor: Colors.transparent,
                                                                              overlayColor: Colors.transparent,
                                                                            ),
                                                                            child: Slider(
                                                                              value: _volume.clamp(0.0, 1.0),
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  _volume = value.clamp(0.0, 1.0);
                                                                                });
                                                                                playerProvider.setVolume(value.clamp(0.0, 1.0));
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              // 播放列表、定时播放、循环模式（仅在音量控制条未展开时显示）
                                                              if (!_showVolumeControl) ...[
                                                                // 播放列表
                                                                MouseRegion(
                                                                  cursor: SystemMouseCursors.click,
                                                                  onEnter: (_) => setState(() => _isPlaylistHovered = true),
                                                                  onExit: (_) => setState(() => _isPlaylistHovered = false),
                                                                  child: GestureDetector(
                                                                    onTap: () {
                                                                      _pageSwitchController
                                                                          .forward(from: 0)
                                                                          .then((_) {
                                                                        setState(() {
                                                                          _currentPage = 1;
                                                                        });
                                                                        _pageSwitchController
                                                                            .reset();
                                                                      });
                                                                    },
                                                                    child: AnimatedContainer(
                                                                      duration: const Duration(milliseconds: 200),
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.transparent,
                                                                        borderRadius: BorderRadius.circular(8),
                                                                      ),
                                                                      child: AnimatedScale(
                                                                        scale: _isPlaylistHovered ? _hoverScale : _normalScale,
                                                                        duration: _animationDuration,
                                                                        child: Icon(
                                                                            CupertinoIcons.list_bullet,
                                                                            color: _isPlaylistHovered
                                                                                ? colorScheme.primary
                                                                                : colorScheme.onSurface.withOpacity(0.7),
                                                                            size: 20,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // 定时播放
                                                                playerProvider.timerMinutes != null
                                                                    ? _buildTimerWidget(context, colorScheme)
                                                                    : MouseRegion(
                                                                        cursor: SystemMouseCursors.click,
                                                                        onEnter: (_) => setState(() => _isTimerHovered = true),
                                                                        onExit: (_) => setState(() => _isTimerHovered = false),
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            _showTimerDialog(context);
                                                                          },
                                                                          child: AnimatedContainer(
                                                                            duration: const Duration(milliseconds: 200),
                                                                            padding: const EdgeInsets.all(8),
                                                                            decoration: BoxDecoration(
                                                                              color: Colors.transparent,
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child: AnimatedScale(
                                                                              scale: _isTimerHovered ? _hoverScale : _normalScale,
                                                                              duration: _animationDuration,
                                                                              child: Icon(
                                                                                CupertinoIcons.clock,
                                                                                color: _isTimerHovered
                                                                                    ? colorScheme.primary
                                                                                    : colorScheme.onSurface.withOpacity(0.7),
                                                                                size: 20,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                // 循环模式
                                                                MouseRegion(
                                                                  cursor: SystemMouseCursors.click,
                                                                  onEnter: (_) => setState(() => _isPlayModeHovered = true),
                                                                  onExit: (_) => setState(() => _isPlayModeHovered = false),
                                                                  child: GestureDetector(
                                                                    onTap: () =>
                                                                        playerProvider.togglePlayMode(),
                                                                    child: AnimatedContainer(
                                                                      duration: const Duration(milliseconds: 200),
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.transparent,
                                                                        borderRadius: BorderRadius.circular(8),
                                                                      ),
                                                                      child: AnimatedScale(
                                                                        scale: _isPlayModeHovered ? _hoverScale : _normalScale,
                                                                        duration: _animationDuration,
                                                                        child: Icon(
                                                                            _getPlayModeIcon(playMode),
                                                                            color: _isPlayModeHovered
                                                                                ? colorScheme.primary
                                                                                : colorScheme.onSurface.withOpacity(0.7),
                                                                            size: 20,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ])
                                        : _buildPlaylistPage(playerProvider),
                                  ],
                                ),
                              ),
                            ),
                            // 右侧歌词区
                            Expanded(
                              child: Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                                  // 根据设置决定是否显示歌词
                                  if (!settings.showLyricsInPlayer) {
                                    return Center(
                                      child: Text(
                                        '歌词显示已关闭',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 48, right: 48, bottom: 80),
                                    child: playerProvider.currentLyrics != null
                                        ? lyrics_widgets.LyricsWidget(
                                            lyrics: playerProvider.currentLyrics!,
                                            position: position,
                                            onLineTap: (duration) {
                                              playerProvider.seekTo(duration);
                                            },
                                          )
                                        : Center(
                                            child: Text(
                                              '暂无歌词',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.5),
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
                          onPanStart: (Platform.isWindows ||
                                  Platform.isLinux ||
                                  Platform.isMacOS)
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
          ),
        );
      },
    );
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return CupertinoIcons.arrow_up_arrow_down_square;
      case PlayMode.shuffle:
        return CupertinoIcons.shuffle;
      case PlayMode.loop:
        return CupertinoIcons.repeat_1;
      case PlayMode.listLoop:
        return CupertinoIcons.repeat;
    }
  }

  String _getPlayModeName(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.loop:
        return '单曲循环';
      case PlayMode.listLoop:
        return '列表循环';
    }
  }

  Widget _buildPinButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringPin = true),
      onExit: (_) => setState(() => _isHoveringPin = false),
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: AnimatedScale(
          scale: _isHoveringPin ? _hoverScale : _normalScale,
          duration: _animationDuration,
          child: Icon(
            _isAlwaysOnTop ? AppIcons.pinFill : AppIcons.pin,
            size: _iconSize,
            color: _isHoveringPin
                ? theme.colorScheme.primary
                : (_isAlwaysOnTop ? Colors.blue : iconColor),
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
    );
  }

  Widget _buildMinimizeButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMinimize = true),
      onExit: (_) => setState(() => _isHoveringMinimize = false),
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: AnimatedScale(
          scale: _isHoveringMinimize ? _hoverScale : _normalScale,
          duration: _animationDuration,
          child: Icon(
            CupertinoIcons.minus,
            size: _iconSize,
            color: _isHoveringMinimize
                ? theme.colorScheme.primary
                : iconColor,
          ),
        ),
        onPressed: () => windowManager.minimize(),
        padding: EdgeInsets.zero,
        constraints: _iconButtonConstraints,
      ),
    );
  }

  Widget _buildMaximizeButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMaximize = true),
      onExit: (_) => setState(() => _isHoveringMaximize = false),
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: AnimatedScale(
          scale: _isHoveringMaximize ? _hoverScale : _normalScale,
          duration: _animationDuration,
          child: Icon(
            CupertinoIcons.fullscreen,
            size: _iconSize,
            color: _isHoveringMaximize
                ? theme.colorScheme.primary
                : iconColor,
          ),
        ),
        onPressed: () => windowManager.maximize(),
        padding: EdgeInsets.zero,
        constraints: _iconButtonConstraints,
      ),
    );
  }

  Widget _buildCloseButton() {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringClose = true),
      onExit: (_) => setState(() => _isHoveringClose = false),
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: AnimatedScale(
          scale: _isHoveringClose ? _hoverScale : _normalScale,
          duration: _animationDuration,
          child: Icon(
            CupertinoIcons.xmark,
            size: _iconSize,
            color: _isHoveringClose
                ? theme.colorScheme.primary
                : iconColor,
          ),
        ),
        onPressed: () async {
          // 触发窗口关闭事件，让main.dart中的onWindowClose处理
          await windowManager.close();
        },
        padding: EdgeInsets.zero,
        constraints: _iconButtonConstraints,
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showTimerDialog(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 临时变量，用于存储用户在对话框中选择的分钟数
    int? tempTimerMinutes = playerProvider.timerMinutes;
    
    // 计算剩余时间（秒）- 静止状态，显示设置的原始时间
    int remainingSeconds = playerProvider.originalTimerMinutes != null ? playerProvider.originalTimerMinutes! * 60 : 0;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hours = remainingSeconds ~/ 3600;
          final minutes = (remainingSeconds % 3600) ~/ 60;
          final seconds = remainingSeconds % 60;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock_fill,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '定时播放',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 倒计时显示
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeUnit(hours, '小时', colorScheme),
                        const SizedBox(width: 16),
                        _buildTimeUnit(minutes, '分钟', colorScheme),
                        const SizedBox(width: 16),
                        _buildTimeUnit(seconds, '秒', colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('设置定时关闭时间（分钟）'),
                  const SizedBox(height: 16),
                  // 进度条控制
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0 分钟',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${tempTimerMinutes ?? (playerProvider.originalTimerMinutes ?? 30)} 分钟',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            '180 分钟',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.2),
                          thumbColor: colorScheme.primary,
                          overlayColor: colorScheme.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: (tempTimerMinutes ?? (playerProvider.originalTimerMinutes ?? 30)).toDouble(),
                          min: 0,
                          max: 180,
                          divisions: 180,
                          onChanged: (value) {
                            setDialogState(() {
                              tempTimerMinutes = value.round();
                              remainingSeconds = tempTimerMinutes! * 60;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 快速选择按钮
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [15, 30, 45, 60, 90, 120].map((minutes) {
                      final isSelected = tempTimerMinutes == minutes;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                tempTimerMinutes = minutes;
                                remainingSeconds = tempTimerMinutes! * 60;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                '$minutes 分钟',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // 自定义输入
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('自定义: '),
                      SizedBox(
                        width: 80,
                        child: CupertinoTextField(
                          keyboardType: TextInputType.number,
                          placeholder: '分钟',
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            final minutes = int.tryParse(value);
                            if (minutes != null && minutes > 0) {
                              setDialogState(() {
                                tempTimerMinutes = minutes;
                                remainingSeconds = minutes * 60;
                              });
                            }
                          },
                        ),
                      ),
                      const Text(' 分钟'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 按钮区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          playerProvider.cancelTimer();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.error,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '取消定时',
                          style: TextStyle(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (tempTimerMinutes != null) {
                            playerProvider.setTimer(tempTimerMinutes!);
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );    
      }
      ),
    );
  }

  void _showPlaylistDialog(
      BuildContext context, PlayerProvider playerProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('播放列表'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: playerProvider.playlist.isEmpty
              ? const Center(child: Text('播放列表为空'))
              : ListView.builder(
                  itemCount: playerProvider.playlist.length,
                  itemBuilder: (context, index) {
                    final music = playerProvider.playlist[index];
                    final isCurrentPlaying =
                        playerProvider.currentIndex == index;
                    return CupertinoListTile(
                      leading: music.coverArt != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                music.coverArt!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                CupertinoIcons.music_note,
                                size: 20,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                      title: Text(
                        music.title,
                        style: TextStyle(
                          fontWeight: isCurrentPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentPlaying
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.label,
                        ),
                      ),
                      subtitle: Text(
                        music.artist,
                        style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      trailing: isCurrentPlaying
                          ? const Icon(
                              CupertinoIcons.play_fill,
                              color: CupertinoColors.activeBlue,
                            )
                          : CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                playerProvider.playAtIndex(index);
                                Navigator.of(context).pop();
                              },
                              child: const Icon(CupertinoIcons.play_fill),
                            ),
                      onTap: () {
                        playerProvider.playAtIndex(index);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPage(PlayerProvider playerProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: playerProvider.playlist.isEmpty
            ? Center(
                child: Text(
                  '播放列表为空',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              )
            : GestureDetector(
                onTap: () {
                  _pageSwitchController.forward(from: 0).then((_) {
                    setState(() {
                      _currentPage = 0;
                    });
                    _pageSwitchController.reset();
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
                    // 限制偏移量在 -200 到 200 之间
                    _coverDragOffset = dragDistance.clamp(-200.0, 200.0);
                  });
                },
                onHorizontalDragEnd: (details) {
                  final dragDistance = _coverDragCurrentX - _coverDragStartX;
                  if (dragDistance < -100) {
                    // 向左拖动，切换到歌曲信息
                    setState(() {
                      _currentPage = 0;
                      _coverDragOffset = 0.0;
                    });
                  }
                  setState(() {
                    _coverDragStartX = 0.0;
                    _coverDragCurrentX = 0.0;
                    _coverDragOffset = 0.0;
                  });
                },
                child: Transform.translate(
                  offset: Offset(_coverDragOffset * 0.3, 0),
                  child: Opacity(
                    opacity: 1 - (_coverDragOffset.abs() / 400),
                    child: Column(
                      children: [
                        // 表头
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
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
                              _coverDragOffset = dragDistance.clamp(-200.0, 200.0);
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            final dragDistance = _coverDragCurrentX - _coverDragStartX;
                            if (dragDistance < -100) {
                              setState(() {
                                _currentPage = 0;
                                _coverDragOffset = 0.0;
                              });
                            }
                            setState(() {
                              _coverDragStartX = 0.0;
                              _coverDragCurrentX = 0.0;
                              _coverDragOffset = 0.0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  '播放列表',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${playerProvider.playlist.length} 首歌曲',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 播放顺序按钮
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => playerProvider.togglePlayMode(),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getPlayModeIcon(playerProvider.playMode),
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // 播放列表
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: playerProvider.playlist.length,
                            itemBuilder: (context, index) {
                              final music = playerProvider.playlist[index];
                              final isCurrentPlaying =
                                  playerProvider.currentIndex == index;
                              return ListTile(
                                leading: music.coverArt != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(
                                          music.coverArt!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          AppIcons.musicNote,
                                          size: 20,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                title: Text(
                                  music.title,
                                  style: TextStyle(
                                    fontWeight: isCurrentPlaying
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentPlaying
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  music.artist,
                                  style: TextStyle(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                trailing: isCurrentPlaying
                                    ? Icon(
                                        CupertinoIcons.play_fill,
                                        color: colorScheme.primary,
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                            CupertinoIcons.play_fill),
                                        onPressed: () {
                                          playerProvider.playAtIndex(index);
                                        },
                                      ),
                                onTap: () {
                                  playerProvider.playAtIndex(index);
                                },
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
    );
  }

  Widget _buildTimerWidget(BuildContext context, ColorScheme colorScheme) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // 只有在歌曲正在播放时才使用StreamBuilder来更新倒计时
    if (playerProvider.isPlaying) {
      return StreamBuilder<int>(
        stream: Stream.periodic(
          const Duration(seconds: 1),
          (count) => count,
        ),
        initialData: 0,
        builder: (context, snapshot) {
          // 计算剩余时间
          int remaining;
          double progress;
          if (playerProvider.timerStartTime == null) {
            // 暂停状态，显示保存的剩余时间
            remaining = playerProvider.pausedRemainingSeconds ?? (playerProvider.originalTimerMinutes! * 60);
            progress = remaining / (playerProvider.originalTimerMinutes! * 60);
          } else {
            // 运行状态，计算实际剩余时间
            final elapsed = DateTime.now().difference(playerProvider.timerStartTime!).inSeconds;
            final totalSeconds = playerProvider.originalTimerMinutes! * 60;
            remaining = totalSeconds - elapsed;
            progress = remaining / totalSeconds;
          }
          if (remaining <= 0) {
            return IconButton(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '00:00',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  // 进度条
                  SizedBox(
                    width: 40,
                    height: 3,
                    child: LinearProgressIndicator(
                      value: 0,
                      backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ],
              ),
              color: colorScheme.onSurface.withOpacity(0.7),
              onPressed: () {
                _showTimerDialog(context);
              },
              tooltip: '定时播放',
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
            );
          }
          final minutes = remaining ~/ 60;
          final seconds = remaining % 60;
          return IconButton(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progress < 0.2 ? Colors.red : colorScheme.primary,
                  ),
                ),
                // 进度条
                SizedBox(
                  width: 40,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress < 0.2 ? Colors.red : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            color: colorScheme.onSurface.withOpacity(0.7),
            onPressed: () {
              _showTimerDialog(context);
            },
            tooltip: '定时播放',
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
          );
        },
      );
    } else {
      // 歌曲未播放，显示静态的剩余时间
      int remaining = playerProvider.pausedRemainingSeconds ?? (playerProvider.originalTimerMinutes! * 60);
      double progress = remaining / (playerProvider.originalTimerMinutes! * 60);

      if (remaining <= 0) {
        return IconButton(
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '00:00',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              // 进度条
              SizedBox(
                width: 40,
                height: 3,
                child: LinearProgressIndicator(
                  value: 0,
                  backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ],
          ),
          color: colorScheme.onSurface.withOpacity(0.7),
          onPressed: () {
            _showTimerDialog(context);
          },
          tooltip: '定时播放',
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(),
        );
      }

      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      return IconButton(
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: progress < 0.2 ? Colors.red : colorScheme.primary,
              ),
            ),
            // 进度条
            SizedBox(
              width: 40,
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.2 ? Colors.red : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        color: colorScheme.onSurface.withOpacity(0.7),
        onPressed: () {
          _showTimerDialog(context);
        },
        tooltip: '定时播放',
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: const BoxConstraints(),
      );
    }
  }
}
