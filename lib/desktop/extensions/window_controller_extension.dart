import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../../common.dart';
import '../../models/lyrics_model.dart';
import '../../providers/player_provider.dart';

// 桌面歌词窗口通信方法
void sendDesktopLyricMessage(Duration position, LyricLine? lyricLine, bool isKaraoke) async {
  if (lyricsWindowController == null) {
    return;
  }

  try {
    await lyricsWindowController!.updateLyric(position, lyricLine, isKaraoke);
  } catch (e) {
    // 发送歌词消息失败
  }
}

void sendPlayingMessage(bool playing) async {
  if (lyricsWindowController == null) {
    return;
  }

  try {
    await lyricsWindowController!.sendPlaying(playing);
  } catch (e) {
    // 发送播放状态消息失败
  }
}

void getDesktopLyricFromMap(Map? arguments) {
  if (arguments == null) return;

  desktopLyricsCurrentPosition = Duration(
    milliseconds: arguments['position'] as int,
  );

  final lyricLineMap = arguments['lyric_line'] as Map?;
  if (lyricLineMap != null) {
    desktopLyricLine = LyricLine.fromMap(lyricLineMap);
  } else {
    desktopLyricLine = null;
  }

  desktopLyricsIsKaraoke = arguments['isKaraoke'] as bool;

  updateDesktopLyricsNotifier.value++;
}

extension WindowControllerExtension on WindowController {
  Future<void> desktopLyricsCustomInitialize() async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_center':
          return await windowManager.center();
        case 'window_close':
          return await windowManager.close();
        case 'update_lyric':
          getDesktopLyricFromMap(call.arguments);
          break;
        case 'set_playing':
          isPlayingNotifier.value = call.arguments as bool;
          break;
        case 'unlock':
          await windowManager.setIgnoreMouseEvents(false);
          break;
        case 'update_desktop_lyrics_font_size':
          if (call.arguments is double) {
            desktopLyricsFontSize = call.arguments as double;
            updateDesktopLyricsNotifier.value++;
          }
          break;
        default:
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });
  }

  Future<void> mainCustomInitialize(PlayerProvider playerProvider) async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'hide_desktop_lyrics':
          // 直接关闭桌面歌词窗口，不再调用PlayerProvider的hideDesktopLyrics方法
          if (lyricsWindowController != null) {
            try {
              await lyricsWindowController!.hide();
              lyricsWindowVisible = false;
            } catch (e) {
              // 关闭桌面歌词窗口失败
            }
          }
          break;
        case 'skip_to_previous':
          await playerProvider.playPrevious();
          break;
        case 'toggle_play':
          await playerProvider.togglePlayPause();
          break;
        case 'skip_to_next':
          await playerProvider.playNext();
          break;
        case 'get_playing_state':
          sendPlayingMessage(playerProvider.isPlaying);
          break;
        default:
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });
  }

  Future<void> center() {
    return invokeMethod('window_center');
  }

  Future<void> close() {
    return invokeMethod('window_close');
  }

  Future<void> updateLyric(
    Duration postion,
    LyricLine? lyricline,
    bool isKaraoke,
  ) {
    return invokeMethod('update_lyric', {
      'position': postion.inMilliseconds,
      'lyric_line': lyricline?.toMap(),
      'isKaraoke': isKaraoke,
    });
  }

  Future<void> sendPlaying(bool playing) {
    return invokeMethod('set_playing', playing);
  }

  Future<void> hideDesktopLyrics() async {
    // 直接关闭桌面歌词窗口控制器
    if (lyricsWindowController != null) {
      try {
        await lyricsWindowController!.hide();
        lyricsWindowVisible = false;
      } catch (e) {
        // 关闭桌面歌词窗口失败
      }
    }
  }

  Future<void> skipToPrevious() {
    return invokeMethod('skip_to_previous');
  }

  Future<void> togglePlay() {
    return invokeMethod('toggle_play');
  }

  Future<void> skipToNext() {
    return invokeMethod('skip_to_next');
  }

  Future<void> updateDesktopLyricsFontSize(double fontSize) {
    return invokeMethod('update_desktop_lyrics_font_size', fontSize);
  }

  Future<void> unlock() {
    return invokeMethod('unlock');
  }
}
