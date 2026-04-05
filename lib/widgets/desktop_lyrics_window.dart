import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../desktop/extensions/window_controller_extension.dart';
import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';

class DesktopLyricsWindow extends StatefulWidget {
  const DesktopLyricsWindow({Key? key}) : super(key: key);

  @override
  State<DesktopLyricsWindow> createState() => _DesktopLyricsWindowState();
}

class _DesktopLyricsWindowState extends State<DesktopLyricsWindow> {
  WindowController? _lyricsWindowController;

  @override
  void initState() {
    super.initState();
    // 延迟检查，确保 Provider 已经初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCreateLyricsWindow();
    });
  }

  @override
  void dispose() {
    _closeLyricsWindow();
    super.dispose();
  }

  Future<void> _checkAndCreateLyricsWindow() async {
    if (!mounted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    // 只在设置已加载、音乐列表已初始化且启用桌面歌词时创建窗口
    if (settings.hasLoadedSettings && 
        settings.enableDesktopLyrics && 
        _lyricsWindowController == null && 
        musicProvider.hasInitialized) {
      await _createLyricsWindow();
    } else if (!settings.enableDesktopLyrics && _lyricsWindowController != null) {
      await _closeLyricsWindow();
    }
  }

  Future<void> _createLyricsWindow() async {
    if (_lyricsWindowController != null) return;

    try {
      // 创建独立的歌词窗口
      _lyricsWindowController = await WindowController.create(
        const WindowConfiguration(
          hiddenAtLaunch: false,
          arguments: 'desktop_lyrics',
        ),
      );

      // 显示窗口
      await _lyricsWindowController!.show();

      debugPrint('桌面歌词窗口已创建');
    } catch (e) {
      debugPrint('创建桌面歌词窗口失败: $e');
    }
  }

  Future<void> _closeLyricsWindow() async {
    if (_lyricsWindowController != null) {
      try {
        await _lyricsWindowController!.close();
        _lyricsWindowController = null;
        debugPrint('桌面歌词窗口已关闭');
      } catch (e) {
        debugPrint('关闭桌面歌词窗口失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, MusicProvider>(
      builder: (context, settings, musicProvider, child) {
        // 监听设置和音乐列表变化
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndCreateLyricsWindow();
        });

        return const SizedBox.shrink();
      },
    );
  }
}
