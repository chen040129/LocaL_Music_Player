import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_music_player/common.dart';
import 'package:flutter_music_player/common_widgets/lyrics.dart';

class DesktopLyricsWidget extends StatefulWidget {
  const DesktopLyricsWidget({super.key});

  @override
  State<DesktopLyricsWidget> createState() => _DesktopLyricsWidgetState();
}

class _DesktopLyricsWidgetState extends State<DesktopLyricsWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late DateTime _lastTickTime;
  Duration _displayPosition = Duration.zero;
  Duration _lineStart = Duration.zero;
  Duration _lineDuration = const Duration(milliseconds: 1);
  double _scrollOffset = 0.0;
  double _maxScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    isPlayingNotifier.addListener(_onPlayStateChanged);
    updateDesktopLyricsNotifier.addListener(_onLyricsUpdate);
    _resetScrollState();
    if (isPlayingNotifier.value) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    isPlayingNotifier.removeListener(_onPlayStateChanged);
    updateDesktopLyricsNotifier.removeListener(_onLyricsUpdate);
    _ticker.dispose();
    super.dispose();
  }

  void _onPlayStateChanged() {
    if (isPlayingNotifier.value) {
      _lastTickTime = DateTime.now();
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  void _onLyricsUpdate() {
    if (!mounted) return;
    _resetScrollState();
    setState(() {});
  }

  void _onTick(Duration timeStamp) {
    if (!mounted) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTickTime);
    _lastTickTime = now;
    _displayPosition += elapsed;
    setState(() {});
  }

  void _resetScrollState() {
    _displayPosition = desktopLyricsCurrentPosition;
    _lastTickTime = DateTime.now();
    _lineStart = desktopLyricLine?.start ?? Duration.zero;
    _lineDuration = _computeLineDuration();
    _scrollOffset = 0.0;
    _maxScrollOffset = 0.0;
  }

  Duration _computeLineDuration() {
    if (desktopLyricLine == null) return const Duration(milliseconds: 1);

    Duration duration = const Duration(milliseconds: 5000);
    final lines = desktopLyricsLines;
    if (lines != null && lines.isNotEmpty) {
      final index = lines.indexWhere((line) =>
          line.start == desktopLyricLine!.start &&
          line.text == desktopLyricLine!.text);
      if (index != -1 && index + 1 < lines.length) {
        final nextStart = lines[index + 1].start;
        final computed = nextStart - lines[index].start;
        if (computed > Duration.zero) {
          duration = computed;
        }
      }
    }

    final lastToken = desktopLyricLine!.tokens.isNotEmpty
        ? desktopLyricLine!.tokens.last
        : null;
    if (duration == const Duration(milliseconds: 5000) &&
        lastToken?.end != null) {
      final computed = lastToken!.end! - desktopLyricLine!.start;
      if (computed > Duration.zero) {
        duration = computed;
      }
    }

    final holdDuration = Duration(
        milliseconds: min(400, (duration.inMilliseconds * 0.3).round()));
    final scrollDuration = duration - holdDuration;
    return scrollDuration > Duration.zero
        ? scrollDuration
        : const Duration(milliseconds: 1);
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return painter.width;
  }

  void _updateScrollMetrics(double maxWidth, String text, TextStyle style) {
    if (maxWidth <= 0) {
      _scrollOffset = 0.0;
      _maxScrollOffset = 0.0;
      return;
    }

    final textWidth = _measureTextWidth(text, style);
    _maxScrollOffset = max(0, textWidth - maxWidth);

    if (_maxScrollOffset <= 0 || _lineDuration <= Duration.zero) {
      _scrollOffset = 0.0;
      return;
    }

    final elapsed = _displayPosition - _lineStart;
    final progress = (elapsed.inMilliseconds / _lineDuration.inMilliseconds).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(progress);
    _scrollOffset = _maxScrollOffset * eased;
  }

  Widget _buildContent(TextStyle style) {
    if (desktopLyricLine == null) {
      return Text(
        'Music Player',
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      );
    }

    if (desktopLyricsIsKaraoke) {
      return KaraokeText(
        key: ValueKey(desktopLyricLine),
        line: desktopLyricLine!,
        position: _displayPosition,
        fontSize: style.fontSize ?? desktopLyricsFontSize,
        fontFamily: style.fontFamily,
        expanded: false,
        isDesktopLyrics: true,
      );
    }

    return Text(
      desktopLyricLine!.text,
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: updateDesktopLyricsNotifier,
      builder: (context, value, child) {
        final fontFamily =
            desktopLyricsFontName.isNotEmpty ? desktopLyricsFontName : null;
        final fontSize = isMobile ? 20.0 : desktopLyricsFontSize;
        final style = TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: Colors.white,
          shadows: [
            const Shadow(
              offset: Offset(0, 1),
              blurRadius: 1,
              color: Colors.black87,
            ),
          ],
        );

        if (desktopLyricLine == null) {
          return Text(
            'Music Player',
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            _updateScrollMetrics(maxWidth, desktopLyricLine!.text, style);
            final alignment =
                _maxScrollOffset > 0 ? Alignment.centerLeft : Alignment.center;

            return ClipRect(
              child: SizedBox(
                width: maxWidth,
                child: Align(
                  alignment: alignment,
                  child: Transform.translate(
                    offset: Offset(-_scrollOffset, 0),
                    child: _buildContent(style),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
