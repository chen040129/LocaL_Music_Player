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

  // 添加滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 是否正在滑动
  bool _isDragging = false;
  // 记录用户最后交互时间，用于自动恢复播放进度
  DateTime _lastInteractionTime = DateTime.now();
  // 恢复播放进度的定时器
  Timer? _resumeTimer;
  // 记录上一次滚动的索引，用于优化滚动体验
  int _lastScrollIndex = -1;

  /// 将字符串转换为Curve对象
  Curve _getCurve(String curveName) {
    switch (curveName) {
      // 基础曲线
      case 'linear':
        return Curves.linear;
      case 'ease':
        return Curves.ease;
      // 缓入曲线
      case 'easeIn':
        return Curves.easeIn;
      case 'easeInCubic':
        return Curves.easeInCubic;
      case 'easeInQuart':
        return Curves.easeInQuart;
      case 'easeInQuint':
        return Curves.easeInQuint;
      case 'easeInSine':
        return Curves.easeInSine;
      case 'easeInExpo':
        return Curves.easeInExpo;
      case 'easeInCirc':
        return Curves.easeInCirc;
      case 'easeInBack':
        return Curves.easeInBack;
      // 缓出曲线
      case 'easeOut':
        return Curves.easeOut;
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      case 'easeOutQuart':
        return Curves.easeOutQuart;
      case 'easeOutQuint':
        return Curves.easeOutQuint;
      case 'easeOutSine':
        return Curves.easeOutSine;
      case 'easeOutExpo':
        return Curves.easeOutExpo;
      case 'easeOutCirc':
        return Curves.easeOutCirc;
      case 'easeOutBack':
        return Curves.easeOutBack;
      // 缓入缓出曲线
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeInOutCubic':
        return Curves.easeInOutCubic;
      case 'easeInOutQuart':
        return Curves.easeInOutQuart;
      case 'easeInOutQuint':
        return Curves.easeInOutQuint;
      case 'easeInOutSine':
        return Curves.easeInOutSine;
      case 'easeInOutExpo':
        return Curves.easeInOutExpo;
      case 'easeInOutCirc':
        return Curves.easeInOutCirc;
      case 'easeInOutBack':
        return Curves.easeInOutBack;
      // 特殊曲线
      case 'fastOutSlowIn':
        return Curves.fastOutSlowIn;
      case 'slowMiddle':
        return Curves.slowMiddle;
      case 'elasticOut':
        return Curves.elasticOut;
      case 'elasticIn':
        return Curves.elasticIn;
      case 'elasticInOut':
        return Curves.elasticInOut;
      default:
        return Curves.easeInOutCubic;
    }
  }

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
    // 只在非选择状态下更新进度，避免用户滚动时被打断
    if (oldWidget.position != widget.position && !_lyricController.isSelectingNotifier.value) {
      _lyricController.setProgress(widget.position);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _lyricController.dispose();
    _styleNotifier.dispose();
    _resumeTimer?.cancel();
    super.dispose();
  }

  /// 重置自动恢复播放进度的定时器
  void _resetResumeTimer() {
    _resumeTimer?.cancel();
    _lastInteractionTime = DateTime.now();
    _resumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _lyricController.isSelectingNotifier.value = false;
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
        // 根据主题和设置调整歌词样式，增强动态效果
        final adjustedStyle = LyricStyle(
          // 非激活歌词样式
          textStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4 * settings.lyricsOpacity)
                : Colors.black.withOpacity(0.4 * settings.lyricsOpacity),
            fontSize: settings.lyricsFontSize,
            height: 1.8,
          ),
          // 激活歌词样式（当前演唱的歌词）
          activeStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(1.0 * settings.lyricsOpacity)
                : Colors.black.withOpacity(1.0 * settings.lyricsOpacity),
            fontSize: settings.activeLyricsFontSize,
            fontWeight: FontWeight.bold,
            height: 1.8,
          ),
          // 翻译歌词样式
          translationStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.35 * settings.lyricsOpacity)
                : Colors.black.withOpacity(0.35 * settings.lyricsOpacity),
            fontSize: 14,
            height: 1.5,
          ),
          // 选中歌词样式
          selectedColor: isDark ? Colors.white : Colors.black,
          selectedTranslationColor: isDark ? Colors.white : Colors.black,
          // 歌词对齐方式
          lineTextAlign: _getTextAlign(settings.lyricsAlignment),
          // 歌词行间距
          lineGap: settings.lyricsLineGap.toDouble(),
          // 翻译歌词行间距
          translationLineGap: 4.0,
          // 内容对齐方式
          contentAlignment: _getCrossAxisAlignment(settings.lyricsAlignment),
          // 选中锚点位置
          selectionAnchorPosition: 0.5,
          // 选中锚点对齐方式
          selectionAlignment: MainAxisAlignment.center,
          // 滚动动画时长 - 使用设置中的值
          scrollDuration: Duration(milliseconds: settings.scrollDuration),
          // 选中行自动恢复时长 - 使用设置中的值
          selectionAutoResumeDuration: Duration(milliseconds: settings.selectionAutoResumeDuration),
          // 播放行自动恢复时长 - 使用设置中的值
          activeAutoResumeDuration: Duration(milliseconds: settings.activeAutoResumeDuration),
          // 滚动动画曲线 - 使用设置中的值
          scrollCurve: _getCurve(settings.scrollCurve),
          // 禁用触摸事件 - 由GestureDetector处理
          disableTouchEvent: false,
          // 选中行自动恢复模式 - 停止选择后再恢复
          selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
          // 禁用高亮效果 - 去除悬停时的浅灰色矩形边缘
          activeHighlightColor: null,
          activeHighlightGradient: null,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              // 歌词视图 - 支持滚轮滚动
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    // 触发拖动状态，让LyricView知道用户正在手动滚动
                    _lyricController.isSelectingNotifier.value = true;
                    // 获取当前高亮的歌词行
                    final currentIndex = _lyricController.activeIndexNotifiter.value;
                    // 根据滚轮方向调整歌词行
                    final delta = pointerSignal.scrollDelta.dy;
                    final newIndex = delta > 0 
                        ? currentIndex + 1 
                        : currentIndex - 1;
                    // 确保新索引在有效范围内
                    final lyricModel = _lyricController.lyricNotifier.value;
                    if (lyricModel != null && newIndex >= 0 && newIndex < lyricModel.lines.length) {
                      // 更新高亮的歌词行
                      _lyricController.activeIndexNotifiter.value = newIndex;
                      // 延迟恢复到播放行 - 增加延迟时间到5秒
                      _resetResumeTimer();
                    }
                  }
                },
                child: Stack(
                  children: [
                    // 歌词视图
                    Material(
                      color: Colors.transparent,
                      type: MaterialType.transparency,
                      child: InkWell(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {},
                        child: LyricView(
                          controller: _lyricController,
                          style: adjustedStyle,
                        ),
                      ),
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
