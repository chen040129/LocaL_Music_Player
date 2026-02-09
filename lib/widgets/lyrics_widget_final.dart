import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/core/lyric_styles.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class LyricsWidget extends StatefulWidget {
  const LyricsWidget({
    Key? key,
    required this.lyrics,
    required this.position,
    this.onLineTap,
  }) : super(key: key);

  final String lyrics;
  final Duration position;
  final Function(Duration)? onLineTap;

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
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

  @override
  void initState() {
    super.initState();
    _lyricController = LyricController();
    _lyricController.loadLyric(widget.lyrics);
    _lyricController.setProgress(widget.position);
    _lyricController.setOnTapLineCallback((duration) {
      widget.onLineTap?.call(duration);
      _lyricController.stopSelection();
    });
  }

  @override
  void didUpdateWidget(LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _lyricController.loadLyric(widget.lyrics);
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
        // 根据主题和设置调整歌词样式
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
          selectionAnchorPosition: 0.5,
          selectionAlignment: MainAxisAlignment.center,
          scrollDuration: const Duration(milliseconds: 300),
          selectionAutoResumeDuration: const Duration(milliseconds: 200),
          activeAutoResumeDuration: const Duration(milliseconds: 5000),
          scrollCurve: Curves.easeInOutCubic,
          disableTouchEvent: false,
          selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              // 歌词视图 - 使用Listener处理滚轮滚动
              Listener(
                behavior: HitTestBehavior.deferToChild,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    // 将滚轮滚动转为歌词拖动偏移
                    final dy = event.scrollDelta.dy;
                    // 触发拖动状态
                    if (!_lyricController.isSelectingNotifier.value) {
                      _lyricController.isSelectingNotifier.value = true;
                    }
                    // 重置自动恢复定时器
                    _resetResumeTimer();
                    // 通过设置选中索引来滚动歌词
                    final currentIndex = _lyricController.activeIndexNotifiter.value;
                    final lyricModel = _lyricController.lyricNotifier.value;
                    if (lyricModel != null && lyricModel.lines.isNotEmpty) {
                      // 计算新的索引
                      int newIndex = currentIndex;
                      // 根据滚动方向和速度调整
                      if (dy > 0) {
                        // 向下滚动
                        newIndex = (currentIndex + 1).clamp(0, lyricModel.lines.length - 1);
                      } else {
                        // 向上滚动
                        newIndex = (currentIndex - 1).clamp(0, lyricModel.lines.length - 1);
                      }
                      // 更新选中索引
                      if (newIndex != currentIndex) {
                        _lyricController.activeIndexNotifiter.value = newIndex;
                      }
                    }
                  }
                },
                child: Stack(
                  children: [
                    // 歌词视图
                    LyricView(
                      controller: _lyricController,
                      style: adjustedStyle,
                    ),
                    // 上下高斯模糊蒙版
                    if (settings.enableLyricsBlur)
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
              ),
            ],
          ),
        );
      },
    );
  }
}
