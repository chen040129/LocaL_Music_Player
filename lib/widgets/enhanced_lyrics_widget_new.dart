import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/core/lyric_styles.dart';
import 'package:flutter_lyric/widgets/lyric_selected_content_background.dart';
import 'package:flutter_lyric/widgets/lyric_selected_progress.dart';
import 'package:flutter_lyric/widgets/highlight_listenable_builder.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class EnhancedLyricsWidget extends StatefulWidget {
  const EnhancedLyricsWidget({
    Key? key,
    required this.lyrics,
    required this.position,
    this.onLineTap,
  }) : super(key: key);

  final String lyrics;
  final Duration position;
  final Function(Duration)? onLineTap;

  @override
  State<EnhancedLyricsWidget> createState() => _EnhancedLyricsWidgetState();
}

class _EnhancedLyricsWidgetState extends State<EnhancedLyricsWidget> {
  late LyricController _lyricController;
  final ValueNotifier<LyricStyle> _styleNotifier = ValueNotifier(
    LyricStyles.default1,
  );

  // 恢复播放进度的定时器
  Timer? _resumeTimer;
  // 记录用户是否正在手动滚动
  bool _isUserScrolling = false;
  // 记录上一次的播放位置
  Duration _lastPosition = Duration.zero;
  // 当前选中的歌词行的时间
  Duration _selectedLineTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lyricController = LyricController();

    // 修改歌词加载方式，添加前导空行以确保第一句歌词居中显示
    // 在歌词前添加一些空行，使第一句歌词能够显示在中间位置
    final emptyLines = List<String>.filled(10, '[00:00.00]');
    final modifiedLyrics = emptyLines.join('
') + '
' + widget.lyrics;

    // 加载修改后的歌词
    _lyricController.loadLyric(modifiedLyrics);

    // 初始化时立即设置进度为0，确保第一句歌词显示在中间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 使用一个简单的延迟来确保UI已经完全加载
      Future.delayed(const Duration(milliseconds: 200), () {
        // 设置进度为第一个非空行，确保第一句歌词显示在中间
        _lyricController.setProgress(Duration.zero);

        // 等待一小段时间，确保设置生效
        Future.delayed(const Duration(milliseconds: 100), () {
          // 立即触发动画，确保歌词居中显示
          _lyricController.notifyEvent(LyricEvent.playSwitchAnimation);

          // 短暂延迟后再设置当前播放位置，确保第一句歌词有足够时间居中显示
          Future.delayed(const Duration(milliseconds: 100), () {
            _lyricController.setProgress(widget.position);
          });
        });
      });
    });

    _lyricController.setOnTapLineCallback((duration) {
      widget.onLineTap?.call(duration);
      _lyricController.stopSelection();
    });
  }

  @override
  void didUpdateWidget(EnhancedLyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      // 修改歌词加载方式，添加前导空行以确保第一句歌词居中显示
      // 在歌词前添加一些空行，使第一句歌词能够显示在中间位置
      final emptyLines = List<String>.filled(10, '[00:00.00]');
      final modifiedLyrics = emptyLines.join('
') + '
' + widget.lyrics;

      // 加载修改后的歌词
      _lyricController.loadLyric(modifiedLyrics);

      // 加载新歌词后，设置初始位置为中间
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 使用一个简单的延迟来确保UI已经完全加载
        Future.delayed(const Duration(milliseconds: 200), () {
          // 设置进度为第一个非空行，确保第一句歌词显示在中间
          _lyricController.setProgress(Duration.zero);

          // 等待一小段时间，确保设置生效
          Future.delayed(const Duration(milliseconds: 100), () {
            // 立即触发动画，确保歌词居中显示
            _lyricController.notifyEvent(LyricEvent.playSwitchAnimation);

            // 短暂延迟后再设置当前播放位置，确保第一句歌词有足够时间居中显示
            Future.delayed(const Duration(milliseconds: 100), () {
              _lyricController.setProgress(widget.position);

              // 确保切换歌曲时不会显示虚线和时间
              _lyricController.isSelectingNotifier.value = false;
            });
          });
        });
      });
    }
    if (oldWidget.position != widget.position) {
      // 只有在用户没有手动滚动时才更新进度
      if (!_isUserScrolling) {
        _lyricController.setProgress(widget.position);
      }
      _lastPosition = widget.position;
    }
  }

  @override
  void dispose() {
    _lyricController.dispose();
    _styleNotifier.dispose();
    _resumeTimer?.cancel();
    super.dispose();
  }

  /// 重置自动恢复播放进度的定时器
  void _resetResumeTimer() {
    _resumeTimer?.cancel();
    _isUserScrolling = true;
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _isUserScrolling = false;
        _lyricController.isSelectingNotifier.value = false;
        // 恢复到当前播放位置
        _lyricController.setProgress(_lastPosition);
      }
    });
  }

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  /// 根据对齐方式获取TextAlign
  TextAlign _getTextAlign(LyricsAlignment alignment) {
    switch (alignment) {
      case LyricsAlignment.left:
        return TextAlign.left;
      case LyricsAlignment.center:
        return TextAlign.center;
      case LyricsAlignment.right:
        return TextAlign.right;
    }
  }

  /// 根据对齐方式获取CrossAxisAlignment
  CrossAxisAlignment _getCrossAxisAlignment(LyricsAlignment alignment) {
    switch (alignment) {
      case LyricsAlignment.left:
        return CrossAxisAlignment.start;
      case LyricsAlignment.center:
        return CrossAxisAlignment.center;
      case LyricsAlignment.right:
        return CrossAxisAlignment.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return ValueListenableBuilder(
      valueListenable: _styleNotifier,
      builder: (context, style, child) {
        // 使用增强的歌词样式，添加更多视觉效果
        final adjustedStyle = LyricStyle(
          textStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4 * settings.lyricsOpacity)
                : Colors.black.withOpacity(0.4 * settings.lyricsOpacity),
            fontSize: settings.lyricsFontSize,
            height: 1.8,
          ),
          activeStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(1.0 * settings.lyricsOpacity)
                : Colors.black.withOpacity(1.0 * settings.lyricsOpacity),
            fontSize: settings.activeLyricsFontSize,
            fontWeight: FontWeight.bold,
            height: 1.8,
            shadows: settings.lyricsEffectType == LyricsEffectType.shadow
                ? [
                    // 添加阴影效果
                    Shadow(
                      color: isDark ? Colors.black.withOpacity(0.6) : Colors.grey.withOpacity(0.6),
                      blurRadius: 4.0,
                      offset: const Offset(2.0, 2.0),
                    ),
                    Shadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                      blurRadius: 8.0,
                      offset: const Offset(1.0, 1.0),
                    ),
                  ]
                : [
                    // 添加辉光效果
                    Shadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 3.0,
                    ),
                    Shadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 6.0,
                    ),
                  ],
          ),
          translationStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.35 * settings.lyricsOpacity)
                : Colors.black.withOpacity(0.35 * settings.lyricsOpacity),
            fontSize: 14,
            height: 1.5,
          ),
          selectedColor: isDark ? Colors.white : Colors.black,
          selectedTranslationColor: isDark ? Colors.white : Colors.black,
          lineTextAlign: _getTextAlign(settings.lyricsAlignment),
          lineGap: settings.lyricsLineGap.toDouble(),
          translationLineGap: 4.0,
          contentAlignment: _getCrossAxisAlignment(settings.lyricsAlignment),
          selectionAnchorPosition: 0.5, // 设置为0.5，使歌词从中间位置开始显示
          selectionAlignment: MainAxisAlignment.center,
          activeAnchorPosition: 0.5, // 设置为0.5，使当前播放行也从中间位置开始显示
          activeAlignment: MainAxisAlignment.center,

          scrollDuration: Duration(milliseconds: settings.scrollDuration),
          selectionAutoResumeDuration: Duration(milliseconds: settings.selectionAutoResumeDuration),
          activeAutoResumeDuration: Duration(milliseconds: settings.activeAutoResumeDuration),
          scrollCurve: _getCurve(settings.scrollCurve),
          disableTouchEvent: false,
          selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
          // 添加渐变效果 - 更明显的渐变
          fadeRange: settings.enableLyricsBlur && !settings.useCustomBlur
              ? FadeRange(top: 80.0, bottom: 80.0)
              : null,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              // 歌词视图 - 使用LyricView，内置了滚轮滚动支持
              LyricView(
                controller: _lyricController,
                style: adjustedStyle,

              ),
              // 拖动时显示时间和虚线
              SelectListenableBuilder(
                controller: _lyricController,
                builder: (state, child) {
                  // 只有在用户拖动时才显示虚线和时间
                  if (!_lyricController.isSelectingNotifier.value) {
                    return const SizedBox.shrink();
                  }

                  return Stack(
                    children: [
                      // 中间虚线 - 与歌词居中对齐
                      Positioned(
                        top: state.centerY,
                        left: 16, // 与歌词左边界对齐
                        right: 60, // 减少与时间的距离
                        child: FractionalTranslation(
                          translation: Offset(0, -0.5),
                          child: CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: DashedLinePainter(
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                              strokeWidth: 1.0,
                              dashWidth: 4.0,
                              dashSpace: 2.0,
                            ),
                          ),
                        ),
                      ),
                      // 时间显示 - 在虚线右边
                      Positioned(
                        right: 16, // 在屏幕右侧
                        top: state.centerY,
                        child: FractionalTranslation(
                          translation: Offset(0, -0.5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(state.duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // 如果需要，添加自定义高斯模糊蒙版（作为备选方案）
              if (settings.enableLyricsBlur && settings.useCustomBlur)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        // 上半部分高斯模糊蒙版
                        Expanded(
                          child: ClipRect(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 8.0,
                                sigmaY: 8.0,
                                tileMode: ui.TileMode.decal,
                              ),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                        // 中间透明区域（当前歌词）
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                        // 下半部分高斯模糊蒙版
                        Expanded(
                          child: ClipRect(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 8.0,
                                sigmaY: 8.0,
                                tileMode: ui.TileMode.decal,
                              ),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
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

  // 根据字符串获取对应的Curve对象
  Curve _getCurve(String curveName) {
    switch (curveName) {
      case 'linear':
        return Curves.linear;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeInCubic':
        return Curves.easeInCubic;
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      case 'easeInOutCubic':
        return Curves.easeInOutCubic;
      case 'easeInQuad':
        return Curves.easeInQuad;
      case 'easeOutQuad':
        return Curves.easeOutQuad;
      case 'easeInOutQuad':
        return Curves.easeInOutQuad;
      case 'easeInQuart':
        return Curves.easeInQuart;
      case 'easeOutQuart':
        return Curves.easeOutQuart;
      case 'easeInOutQuart':
        return Curves.easeInOutQuart;
      case 'easeInSine':
        return Curves.easeInSine;
      case 'easeOutSine':
        return Curves.easeOutSine;
      case 'easeInOutSine':
        return Curves.easeInOutSine;
      default:
        return Curves.easeInOutCubic;
    }
  }
}

/// 虚线绘制器
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashCount = (size.width / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      final endX = startX + dashWidth;
      if (endX > size.width) break;

      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DashedLinePainter) {
      return oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.dashWidth != dashWidth ||
          oldDelegate.dashSpace != dashSpace;
    }
    return true;
  }
}
