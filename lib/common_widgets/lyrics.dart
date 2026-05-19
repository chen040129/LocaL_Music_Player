import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_music_player/common.dart';

class KaraokeText extends StatefulWidget {
  final LyricLine line;
  final Duration position;
  final double fontSize;
  final String? fontFamily;
  final bool expanded;
  final bool isDesktopLyrics;

  const KaraokeText({
    super.key,
    required this.line,
    required this.position,
    required this.fontSize,
    this.fontFamily,
    required this.expanded,
    this.isDesktopLyrics = false,
  });

  @override
  State<KaraokeText> createState() => KaraokeTextState();
}

class KaraokeTextState extends State<KaraokeText>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;

  Duration displayPosition = Duration.zero;
  DateTime lastSyncTime = DateTime.now();

  late final VoidCallback _playStateListener;

  @override
  void initState() {
    super.initState();

    displayPosition = widget.position;

    ticker = createTicker((_) {
      final now = DateTime.now();
      final elapsed = now.difference(lastSyncTime);
      lastSyncTime = now;

      displayPosition += elapsed;
      setState(() {});
    });

    _playStateListener = () {
      if (isPlayingNotifier.value) {
        lastSyncTime = DateTime.now();
        if (!ticker.isActive) {
          ticker.start();
        }
      } else {
        if (ticker.isActive) {
          ticker.stop();
        }
      }
    };

    isPlayingNotifier.addListener(_playStateListener);

    if (isPlayingNotifier.value) {
      ticker.start();
    }
  }

  @override
  void dispose() {
    isPlayingNotifier.removeListener(_playStateListener);
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: widget.expanded ? TextAlign.left : TextAlign.center,
      overflow: TextOverflow.visible,
      maxLines: 1,
      text: TextSpan(children: widget.line.tokens.map(buildTokenSpan).toList()),
    );
  }

  InlineSpan buildTokenSpan(LyricToken token) {
    final start = token.start;
    final end = token.end;

    double progress;
    if (displayPosition <= start) {
      progress = 0;
    } else if (end == null || displayPosition >= end) {
      progress = 1;
    } else {
      progress =
          (displayPosition - start).inMilliseconds /
          (end - start).inMilliseconds;
    }

    final style = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: widget.fontSize,
      fontWeight: isMobile ? FontWeight.bold : null,
      color: Colors.white,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Stack(
        children: [
          Text(
            token.text,
            style: TextStyle(
              fontFamily: widget.fontFamily,
              fontSize: widget.fontSize,
              color: Colors.transparent,
              shadows: widget.isDesktopLyrics
                  ? [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: isMobile ? 5 : 1,
                        color: isMobile ? Colors.black87 : Colors.black54,
                      ),
                    ]
                  : null,
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final p = progress.clamp(0.0, 1.0);
              return LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withAlpha(128),
                ],
                stops: [0, p, p],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
            },
            child: Text(token.text, style: style),
          ),
        ],
      ),
    );
  }
}
