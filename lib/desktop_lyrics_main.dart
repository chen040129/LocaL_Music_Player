import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'desktop/desktop_lyrics.dart';
import 'common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查是否为桌面歌词窗口
  final windowIndex = await DesktopMultiWindow.getCurrentWindowIndex();
  if (windowIndex != 0) {
    // 这是桌面歌词窗口
    runApp(const DesktopLyricsApp());
  } else {
    // 这是主窗口，不需要处理
    return;
  }
}

class DesktopLyricsApp extends StatelessWidget {
  const DesktopLyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DesktopLyrics(),
    );
  }
}
