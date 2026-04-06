import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'models/lyrics_model.dart';
import 'providers/player_provider.dart';

// ===================================== App =====================================

final isMobile = Platform.isAndroid || Platform.isIOS;

// ===================================== Assets =====================================

const AssetImage previousButtonImage = AssetImage(
  'assets/images/previous_button.png',
);
const AssetImage nextButtonImage = AssetImage('assets/images/next_button.png');

// ===================================== DesktopLyrics =====================================

WindowController? mainWindowController;
WindowController? lyricsWindowController;
bool lyricsWindowVisible = false;

// ===================================== Global Providers =====================================

PlayerProvider? globalPlayerProvider;

class LyricLine {
  final Duration start;
  final String text;
  final List<LyricToken> tokens;

  LyricLine(this.start, this.text, this.tokens);

  Map<String, dynamic> toMap() {
    return {
      'start': start.inMilliseconds,
      'text': text,
      'tokens': tokens.map((t) => t.toMap()).toList(),
    };
  }

  factory LyricLine.fromMap(Map raw) {
    final map = Map<String, dynamic>.from(raw);

    return LyricLine(
      Duration(milliseconds: map['start'] as int),
      map['text'] as String,
      (map['tokens'] as List).map((e) => LyricToken.fromMap(e as Map)).toList(),
    );
  }
}

class LyricToken {
  final Duration start;
  final String text;
  Duration? end;

  LyricToken(this.start, this.text, [this.end]);

  Map<String, dynamic> toMap() {
    return {
      'start': start.inMilliseconds,
      'end': end?.inMilliseconds,
      'text': text,
    };
  }

  factory LyricToken.fromMap(Map raw) {
    final map = Map<String, dynamic>.from(raw);

    return LyricToken(
      Duration(milliseconds: map['start'] as int),
      map['text'] as String,
      map['end'] != null ? Duration(milliseconds: map['end'] as int) : null,
    );
  }
}

LyricLine? desktopLyricLine;
Duration desktopLyricsCurrentPosition = Duration.zero;
bool desktopLyricsIsKaraoke = false;
double desktopLyricsFontSize = 30.0;

final updateDesktopLyricsNotifier = ValueNotifier(0);

final isPlayingNotifier = ValueNotifier(false);

/// 将 LocaL_Music_Player 的 Lyrics 模型转换为 ParticleMusic 的 LyricLine 格式
LyricLine? convertToLyricLine(Lyrics? lyrics, int currentTimeMs) {
  if (lyrics == null || !lyrics.hasLyrics) return null;

  final currentLine = lyrics.getCurrentLine(currentTimeMs);
  if (currentLine == null) return null;

  // 将整行歌词作为一个 token
  final token = LyricToken(
    Duration(milliseconds: currentLine.time),
    currentLine.text,
    null, // 非卡拉OK模式，不需要结束时间
  );

  return LyricLine(
    Duration(milliseconds: currentLine.time),
    currentLine.text,
    [token],
  );
}
