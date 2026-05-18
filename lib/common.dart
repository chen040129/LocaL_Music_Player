import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'models/lyrics_model.dart';
import 'providers/music_provider.dart';
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
WindowController? lyricsWindowControllerFlutterLyric;
bool lyricsWindowVisible = false;
bool lyricsWindowFlutterLyricVisible = false;

// ===================================== Global Providers =====================================

MusicProvider? globalMusicProvider;
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
String desktopLyricsFontPath = '';
String desktopLyricsFontName = '';

// Flutter Lyric 桌面歌词相关
String? desktopLyricsFullLrc; // 完整的 LRC 歌词字符串
List<LyricLine>? desktopLyricsLines; // 完整的歌词行列表

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

// ===================================== Exit App =====================================

bool _isExiting = false; // 防止重复退出的标志

/// 安全退出应用
/// 参照 ParticleMusic 的关闭流程：先关闭桌面歌词窗口，再关闭主窗口
///
/// 之前的问题：直接调用 exit(0) 终止主进程，但桌面歌词窗口是独立进程
/// （由 desktop_multi_window 创建），不会随主进程终止而立即关闭，
/// 需要等待 Flutter 引擎超时或被系统回收，导致延迟关闭。
///
/// 修复方案：退出前先通过 invokeMethod('window_close') 通知歌词窗口
/// 执行 windowManager.close()，主动关闭歌词窗口后再关闭主窗口。
void exitApp() async {
  if (_isExiting) return;
  _isExiting = true;

  // 1. 保存数据（fire-and-forget，不阻塞退出流程）
  _saveDataOnExitSync();

  // 2. 主动关闭桌面歌词窗口
  //    必须等待 invokeMethod 完成，确保关闭消息已送达歌词窗口，
  //    否则主窗口先关闭会导致 IPC 通道断开，歌词窗口收不到关闭指令。
  //    invokeMethod 只是发送消息并等待送达确认，不等待歌词窗口完全关闭，所以很快。
  if (lyricsWindowController != null) {
    try {
      await lyricsWindowController!.invokeMethod('window_close');
    } catch (_) {}
  }
  if (lyricsWindowControllerFlutterLyric != null) {
    try {
      await lyricsWindowControllerFlutterLyric!.invokeMethod('window_close');
    } catch (_) {}
  }

  // 3. 关闭主窗口
  //    在 Windows 上，setPreventClose(false) + windowManager.close()
  //    是最快的退出方式（参考 ParticleMusic）
  if (Platform.isWindows) {
    await windowManager.setPreventClose(false);
    windowManager.close();
    return;
  }

  exit(0);
}

/// 退出时同步保存数据（fire-and-forget）
void _saveDataOnExitSync() {
  try {
    final musicProvider = globalMusicProvider;
    if (musicProvider != null) {
      musicProvider.saveData(); // 不 await
    }
    final playerProvider = globalPlayerProvider;
    if (playerProvider != null) {
      playerProvider.savePlayProgress(); // 不 await
    }
  } catch (e) {
    // 保存失败不影响退出
  }
}
