import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../../common.dart';
import '../../models/lyrics_model.dart';
import '../../providers/player_provider.dart';

// 桌面歌词窗口通信方法
void sendDesktopLyricMessage(Duration position, LyricLine? lyricLine, bool isKaraoke) async {
  if (lyricsWindowController == null) return;

  try {
    await lyricsWindowController!.updateLyric(position, lyricLine, isKaraoke);
  } catch (e) {
    print('Error sending lyric message to desktop lyrics: $e');
  }
}

void sendPlayingMessage(bool playing) async {
  if (lyricsWindowController == null) {
    print('sendPlayingMessage: lyricsWindowController is null');
    return;
  }

  try {
    print('sendPlayingMessage: sending playing=$playing to desktop lyrics');
    await lyricsWindowController!.sendPlaying(playing);
    print('sendPlayingMessage: message sent successfully');
  } catch (e) {
    print('Error sending playing message to desktop lyrics: $e');
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
    print('Setting up desktop lyrics custom method handler...');
    return await setWindowMethodHandler((call) async {
      print('Received method call: ${call.method}');
      switch (call.method) {
        case 'window_center':
          return await windowManager.center();
        case 'window_close':
          return await windowManager.close();
        case 'update_lyric':
          getDesktopLyricFromMap(call.arguments);
          break;
        case 'set_playing':
          print('set_playing called with value: ${call.arguments}');
          isPlayingNotifier.value = call.arguments as bool;
          print('isPlayingNotifier.value updated to: ${isPlayingNotifier.value}');
          break;
        case 'unlock':
          await windowManager.setIgnoreMouseEvents(false);
          break;
        case 'update_desktop_lyrics_font_size':
          print('update_desktop_lyrics_font_size called with value: ${call.arguments}');
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
    print('Setting up main window custom method handler...');
    return await setWindowMethodHandler((call) async {
      print('Main window received method call: ${call.method}');

      switch (call.method) {
        case 'hide_desktop_lyrics':
          print('Hiding desktop lyrics');
          // 调用PlayerProvider的hideDesktopLyrics方法来更新设置
          await playerProvider.hideDesktopLyrics();
          break;
        case 'skip_to_previous':
          print('Calling playPrevious');
          await playerProvider.playPrevious();
          break;
        case 'toggle_play':
          print('Calling togglePlayPause');
          await playerProvider.togglePlayPause();
          break;
        case 'skip_to_next':
          print('Calling playNext');
          await playerProvider.playNext();
          break;
        case 'get_playing_state':
          print('Sending playing state to desktop lyrics: ${playerProvider.isPlaying}');
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

  Future<void> hideDesktopLyrics() {
    return invokeMethod('hide_desktop_lyrics');
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
