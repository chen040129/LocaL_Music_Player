
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
      _lyricController.setProgress(widget.position);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _lyricController.dispose();
    _styleNotifier.dispose();
    super.dispose();
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
          // 滚动动画时长 - 使用更长的时长实现更平滑的过渡
          scrollDuration: const Duration(milliseconds: 500),
          // 选中行自动恢复时长 - 增加时长使过渡更平滑
          selectionAutoResumeDuration: const Duration(milliseconds: 400),
          // 播放行自动恢复时长 - 增加时长使过渡更平滑
          activeAutoResumeDuration: const Duration(milliseconds: 3500),
          // 滚动动画曲线 - 使用更平滑的曲线
          scrollCurve: Curves.easeInOutCubic,
          // 禁用触摸事件 - 由GestureDetector处理
          disableTouchEvent: false,
          // 选中行自动恢复模式 - 停止选择后再恢复
          selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
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
                      // 延迟恢复到播放行
                      Future.delayed(const Duration(seconds: 3), () {
                        _lyricController.isSelectingNotifier.value = false;
                      });
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
