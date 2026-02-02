import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/core/lyric_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: _styleNotifier,
      builder: (context, style, child) {
        // 根据主题调整歌词样式，增强动态效果
        final adjustedStyle = LyricStyle(
          // 非激活歌词样式
          textStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
            fontSize: 16,
            height: 1.8,
          ),
          // 激活歌词样式（当前演唱的歌词）
          activeStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(1.0)
                : Colors.black.withOpacity(1.0),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.8,
          ),
          // 翻译歌词样式
          translationStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.35)
                : Colors.black.withOpacity(0.35),
            fontSize: 14,
            height: 1.5,
          ),
          // 选中歌词样式
          selectedColor: isDark ? Colors.white : Colors.black,
          selectedTranslationColor: isDark ? Colors.white : Colors.black,
          // 歌词对齐方式
          lineTextAlign: TextAlign.center,
          // 歌词行间距
          lineGap: 8.0,
          // 翻译歌词行间距
          translationLineGap: 4.0,
          // 内容对齐方式
          contentAlignment: CrossAxisAlignment.center,
          // 选中锚点位置
          selectionAnchorPosition: 0.5,
          // 选中锚点对齐方式
          selectionAlignment: MainAxisAlignment.center,
          // 滚动动画时长 - 使用更短的时长提高响应速度
          scrollDuration: const Duration(milliseconds: 300),
          // 选中行自动恢复时长 - 使用更短的时长提高响应速度
          selectionAutoResumeDuration: const Duration(milliseconds: 300),
          // 播放行自动恢复时长 - 使用更短的时长提高响应速度
          activeAutoResumeDuration: const Duration(milliseconds: 2000),
          // 滚动动画曲线 - 使用更平滑的曲线
          scrollCurve: Curves.easeInOut,
          // 禁用触摸事件 - 由GestureDetector处理
          disableTouchEvent: false,
          // 选中行自动恢复模式 - 停止选择后再恢复
          selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: LyricView(
            controller: _lyricController,
            style: adjustedStyle,
          ),
        );
      },
    );
  }
}
