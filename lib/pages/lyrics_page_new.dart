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
import '../constants/app_icons.dart';
import '../widgets/lyrics_widget.dart';

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
  int? _timerMinutes; // 用户设置的定时分钟数
  int? _originalTimerMinutes; // 保存原始设置的分钟数，用于恢复
  Timer? _timer;
  DateTime? _timerStartTime;
  int? _pausedRemainingSeconds;

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
    _timer?.cancel();
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
          body: Stack(
            children: [
              // 背景模糊效果
              if (currentMusic?.coverArt != null)
                Positioned.fill(
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
                                                LayoutBuilder(
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
                                                ),
                                                const SizedBox(height: 32),
                                                // 控制区
                                                Column(
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
                                                                    ? _dragPosition
                                                                    : progress,
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    _isDragging =
                                                                        true;
                                                                    _dragPosition =
                                                                        value;
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
                                                                          value);
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
                                                    const SizedBox(height: 0),
                                                    // 播放控制按钮
                                                    Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            // 上一曲
                                                            IconButton(
                                                              icon: const Icon(
                                                                  CupertinoIcons
                                                                      .backward_end_fill),
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.8),
                                                              onPressed: () =>
                                                                  playerProvider
                                                                      .playPrevious(),
                                                              iconSize: 32,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                            const SizedBox(
                                                                width: 20),
                                                            // 播放/暂停
                                                            IconButton(
                                                              icon: Icon(
                                                                isPlaying
                                                                    ? CupertinoIcons
                                                                        .pause_fill
                                                                    : CupertinoIcons
                                                                        .play_fill,
                                                                color: colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                        0.8),
                                                              ),
                                                              iconSize: 44,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              onPressed: () {
                                                                  final wasPlaying = playerProvider.isPlaying;
                                                                  playerProvider.togglePlayPause();

                                                                  // 处理倒计时
                                                                  if (_timerMinutes != null) {
                                                                    if (wasPlaying) {
                                                                      // 暂停播放时，保存剩余时间并暂停倒计时
                                                                      setState(() {
                                                                        if (_timerStartTime != null) {
                                                                          final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
                                                                          final totalSeconds = _originalTimerMinutes! * 60;
                                                                          _pausedRemainingSeconds = totalSeconds - elapsed;
                                                                        }
                                                                        _timerStartTime = null;
                                                                        // 取消之前的定时器
                                                                        _timer?.cancel();
                                                                      });
                                                                    } else {
                                                                      // 恢复播放时，恢复倒计时
                                                                      setState(() {
                                                                        _timerStartTime = DateTime.now();
                                                                        // 重新设置定时器，使用剩余秒数
                                                                        if (_pausedRemainingSeconds != null) {
                                                                          _timer?.cancel();
                                                                          _timer = Timer(Duration(seconds: _pausedRemainingSeconds!), () {
                                                                            final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                                                                            playerProvider.stop();
                                                                            setState(() {
                                                                              _timerMinutes = null;
                                                                              _originalTimerMinutes = null;
                                                                              _timerStartTime = null;
                                                                              _pausedRemainingSeconds = null;
                                                                            });
                                                                          });
                                                                        }
                                                                      });
                                                                    }
                                                                  }
                                                                },
                                                            ),
                                                            const SizedBox(
                                                                width: 20),
                                                            // 下一曲
                                                            IconButton(
                                                              icon: const Icon(
                                                                  CupertinoIcons
                                                                      .forward_end_fill),
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.8),
                                                              onPressed: () =>
                                                                  playerProvider
                                                                      .playNext(),
                                                              iconSize: 32,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        // 播放控制按钮行
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      48),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              // 播放列表
                                                              Offstage(
                                                                offstage: _showVolumeControl,
                                                                child: AnimatedOpacity(
                                                                  duration: const Duration(milliseconds: 200),
                                                                  opacity: _showVolumeControl ? 0.0 : 1.0,
                                                                  child: IconButton(
                                                                    icon: const Icon(
                                                                        CupertinoIcons
                                                                            .list_bullet),
                                                                    color: colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.7),
                                                                    onPressed: () {
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
                                                                    tooltip: '播放列表',
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                  ),
                                                                ),
                                                              ),
                                                              // 音量调节
                                                              AnimatedContainer(
                                                                duration: const Duration(milliseconds: 200),
                                                                width: _showVolumeControl ? 220 : 24,
                                                                child: Listener(
                                                                  onPointerSignal: (pointerSignal) {
                                                                    if (pointerSignal is PointerScrollEvent) {
                                                                      setState(() {
                                                                        _volume = (_volume - pointerSignal.scrollDelta.dy * 0.001).clamp(0.0, 1.0);
                                                                      });
                                                                      playerProvider.setVolume(_volume);
                                                                    }
                                                                  },
                                                                  child: MouseRegion(
                                                                    onEnter: (_) =>
                                                                        setState(() =>
                                                                            _showVolumeControl =
                                                                                true),
                                                                    onExit: (_) =>
                                                                        setState(() =>
                                                                            _showVolumeControl =
                                                                                false),
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
                                                                      child: Container(
                                                                        alignment: Alignment.center,
                                                                        child: _showVolumeControl
                                                                            ? Row(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  IconButton(
                                                                                    icon: Icon(
                                                                                      _volume > 0
                                                                                          ? CupertinoIcons.speaker_2_fill
                                                                                          : CupertinoIcons.speaker_slash,
                                                                                    ),
                                                                                    color: colorScheme
                                                                                        .onSurface
                                                                                        .withOpacity(
                                                                                            0.7),
                                                                                    onPressed: () {
                                                                                      setState(() {
                                                                                        _volume = _volume > 0 ? 0.0 : 0.7;
                                                                                      });
                                                                                      playerProvider.setVolume(_volume);
                                                                                    },
                                                                                    tooltip: '音量',
                                                                                    padding: const EdgeInsets.all(6),
                                                                                    constraints: const BoxConstraints(),
                                                                                  ),
                                                                                  const SizedBox(width: 2),
                                                                                  Flexible(
                                                                                    child: SizedBox(
                                                                                      width: 140,
                                                                                      child: SliderTheme(
                                                                                        data: SliderThemeData(
                                                                                          trackHeight: 2,
                                                                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                                                                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                                                                                          activeTrackColor: _getActiveTrackColor(playerProvider, colorScheme),
                                                                                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.2),
                                                                                        ),
                                                                                        child: Slider(
                                                                                          value: _volume,
                                                                                          onChanged: (value) {
                                                                                            setState(() {
                                                                                              _volume = value;
                                                                                            });
                                                                                            playerProvider.setVolume(value);
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              )
                                                                            : IconButton(
                                                                                icon: Icon(
                                                                                  _volume > 0
                                                                                      ? CupertinoIcons.speaker_2_fill
                                                                                      : CupertinoIcons.speaker_slash,
                                                                                ),
                                                                                color: colorScheme
                                                                                    .onSurface
                                                                                    .withOpacity(
                                                                                        0.7),
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    _volume = _volume > 0 ? 0.0 : 0.7;
                                                                                  });
                                                                                  playerProvider.setVolume(_volume);
                                                                                },
                                                                                tooltip: '音量',
                                                                                padding: EdgeInsets.zero,
                                                                                constraints: const BoxConstraints(),
                                                                              ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              // 定时播放
                                                              Offstage(
                                                                offstage: _showVolumeControl,
                                                                child: AnimatedOpacity(
                                                                  duration: const Duration(milliseconds: 200),
                                                                  opacity: _showVolumeControl ? 0.0 : 1.0,
                                                                  child: _timerMinutes != null
                                                                    ? StreamBuilder<int>(
                                                                        stream: Stream.periodic(
                                                                          const Duration(seconds: 1),
                                                                          (count) => count,
                                                                        ),
                                                                        initialData: 0,
                                                                        builder: (context, snapshot) {
                                                                          // 计算剩余时间
                                                                          int remaining;
                                                                          if (_timerStartTime == null) {
                                                                            // 暂停状态，显示保存的剩余时间
                                                                            remaining = _pausedRemainingSeconds ?? (_originalTimerMinutes! * 60);
                                                                          } else {
                                                                            // 运行状态，计算实际剩余时间
                                                                            final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
                                                                            final totalSeconds = _originalTimerMinutes! * 60;
                                                                            remaining = totalSeconds - elapsed;
                                                                          }
                                                                          if (remaining <= 0) {
                                                                            return IconButton(
                                                                              icon: const Text(
                                                                                '00:00',
                                                                                style: TextStyle(
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: CupertinoColors.systemGrey,
                                                                                ),
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
                                                                            icon: Text(
                                                                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: colorScheme.primary,
                                                                              ),
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
                                                                      )
                                                                    : IconButton(
                                                                        icon: const Icon(
                                                                          CupertinoIcons.clock,
                                                                          size: 24,
                                                                        ),
                                                                        color: colorScheme.onSurface.withOpacity(0.7),
                                                                        onPressed: () {
                                                                          _showTimerDialog(context);
                                                                        },
                                                                        tooltip: '定时播放',
                                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                        constraints: const BoxConstraints(),
                                                                      ),
                                                                ),
                                                              ),
                                                              // 循环模式
                                                              Offstage(
                                                                offstage: _showVolumeControl,
                                                                child: AnimatedOpacity(
                                                                  duration: const Duration(milliseconds: 200),
                                                                  opacity: _showVolumeControl ? 0.0 : 1.0,
                                                                  child: IconButton(
                                                                    icon: Icon(
                                                                        _getPlayModeIcon(
                                                                            playMode)),
                                                                    color: colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.7),
                                                                    onPressed: () =>
                                                                        playerProvider
                                                                            .togglePlayMode(),
                                                                    tooltip:
                                                                        _getPlayModeName(
                                                                            playMode),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                  ),
                                                                ),
                                                              ),
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
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 48, right: 48, bottom: 80),
                                child: playerProvider.currentLyrics != null
                                    ? LyricsWidget(
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
    final hoverBackgroundColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

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
    final hoverBackgroundColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMinimize = true),
      onExit: (_) => setState(() => _isHoveringMinimize = false),
      child: AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color:
              _isHoveringMinimize ? hoverBackgroundColor : Colors.transparent,
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

  void _showTimerDialog(BuildContext context) {
    // 计算剩余时间（秒）
    int remainingSeconds = _originalTimerMinutes != null ? _originalTimerMinutes! * 60 : 0;
    // 暂停倒计时显示，保存剩余时间
    final DateTime? pauseStartTime = _timerStartTime;
    if (_timerStartTime != null && _originalTimerMinutes != null) {
      final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      final totalSeconds = _originalTimerMinutes! * 60;
      _pausedRemainingSeconds = totalSeconds - elapsed;
      remainingSeconds = _pausedRemainingSeconds!;
    }
    _timerStartTime = null;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 启动定时器更新剩余时间
          Timer? updateTimer;
          updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (remainingSeconds > 0) {
              setDialogState(() {
                remainingSeconds--;
              });
            } else {
              timer.cancel();
            }
          });

          return CupertinoAlertDialog(
            title: const Text('定时播放'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('设置定时关闭时间（分钟）'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () {
                        setDialogState(() {
                          if (_timerMinutes != null && _timerMinutes! > 1) {
                            _timerMinutes = _timerMinutes! - 1;
                            remainingSeconds = _timerMinutes! * 60;
                          }
                        });
                      },
                      child: const Icon(CupertinoIcons.minus_circle),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_timerMinutes ?? (_originalTimerMinutes ?? 30)} 分钟',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () {
                        setDialogState(() {
                          _timerMinutes = (_timerMinutes ?? (_originalTimerMinutes ?? 30)) + 1;
                          remainingSeconds = _timerMinutes! * 60;
                        });
                      },
                      child: const Icon(CupertinoIcons.plus_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [15, 30, 45, 60, 90, 120].map((minutes) {
                    return CupertinoButton(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: _timerMinutes == minutes
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey5,
                      onPressed: () {
                        setDialogState(() {
                          _timerMinutes = minutes;
                          remainingSeconds = _timerMinutes! * 60;
                        });
                      },
                      child: Text(
                        '$minutes 分钟',
                        style: TextStyle(
                          color: _timerMinutes == minutes
                              ? CupertinoColors.white
                              : CupertinoColors.label,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              updateTimer?.cancel();
              // 恢复倒计时显示
              setState(() {
                _timerStartTime = pauseStartTime;
                _pausedRemainingSeconds = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              // 取消定时器和更新定时器
              updateTimer?.cancel();
              _timer?.cancel();
              setState(() {
                _timerMinutes = null;
                _timerStartTime = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('取消定时'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              // 取消更新定时器
              updateTimer?.cancel();
              // 取消之前的定时器
              _timer?.cancel();
              // 设置新的定时器
              if (_timerMinutes != null) {
                setState(() {
                  // 保存原始设置的分钟数
                  _originalTimerMinutes = _timerMinutes;
                  // 记录定时开始时间
                  _timerStartTime = DateTime.now();
                  // 清除保存的剩余时间
                  _pausedRemainingSeconds = null;
                  // 使用实际设置的剩余时间
                  _timer = Timer(Duration(minutes: _timerMinutes!), () {
                    // 定时时间到，停止播放
                    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                    playerProvider.stop();
                    // 清除定时时间和开始时间
                    setState(() {
                      _timerMinutes = null;
                      _originalTimerMinutes = null;
                      _timerStartTime = null;
                    });
                  });
                });
              } else {
                // 如果没有设置定时时间，恢复之前的倒计时显示
                setState(() {
                  _timerStartTime = pauseStartTime;
                  _pausedRemainingSeconds = null;
                });
              }
              Navigator.of(context).pop();
            },
            isDefaultAction: true,
            child: const Text('确定'),
          ),
        ],
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
}
