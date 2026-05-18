import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'models/lyrics_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载保存的窗口位置
  final prefs = await SharedPreferences.getInstance();
  final savedX = prefs.getDouble('lyrics_window_x') ?? 100.0;
  final savedY = prefs.getDouble('lyrics_window_y') ?? 100.0;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // 窗口配置 - 设置为无边框窗口
    const windowOptions = WindowOptions(
      size: Size(400, 200),
      minimumSize: Size(300, 150),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
      center: false,
      decorations: WindowDecorations(
        borderColor: Colors.transparent,
        borderWidth: 0,
      ),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setSkipTaskbar(false);
      await windowManager.setPosition(Offset(savedX, savedY));
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setIgnoreMouseEvents(false);
    });
  }

  runApp(const LyricsWindowApp());
}

class LyricsWindowApp extends StatefulWidget {
  const LyricsWindowApp({Key? key}) : super(key: key);

  @override
  State<LyricsWindowApp> createState() => _LyricsWindowAppState();
}

class _LyricsWindowAppState extends State<LyricsWindowApp> with WindowListener {
  Offset _position = Offset(100, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // 保存窗口位置
    final position = await windowManager.getPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lyrics_window_x', position.dx);
    await prefs.setDouble('lyrics_window_y', position.dy);
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider2<MusicProvider, SettingsProvider, PlayerProvider>(
          create: (context) => PlayerProvider(),
          update: (context, musicProvider, settingsProvider, playerProvider) {
            playerProvider ??= PlayerProvider();
            playerProvider.setMusicProvider(musicProvider);
            playerProvider.setSettingsProvider(settingsProvider);
            return playerProvider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, child) {
          final fontFamily = settings.fontName.isNotEmpty ? settings.fontName : null;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(fontFamily: fontFamily),
            darkTheme: AppTheme.darkTheme(fontFamily: fontFamily),
            themeMode: themeProvider.themeMode,
            home: const LyricsWindow(),
          );
        },
      ),
    );
  }
}

class LyricsWindow extends StatefulWidget {
  const LyricsWindow({Key? key}) : super(key: key);

  @override
  State<LyricsWindow> createState() => _LyricsWindowState();
}

class _LyricsWindowState extends State<LyricsWindow> {
  bool _isLocked = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Consumer2<SettingsProvider, PlayerProvider>(
        builder: (context, settings, player, child) {
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onPanUpdate: _isLocked
                  ? null
                  : (details) async {
                      final position = await windowManager.getPosition();
                      await windowManager.setPosition(
                        Offset(position.dx + details.delta.dx, position.dy + details.delta.dy),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isHovering && settings.showBackgroundOnHover
                      ? Colors.black.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: settings.showBackgroundOnHover
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 歌词内容
                      _buildLyricsContent(settings, player),
                      // 控制按钮
                      if (_isHovering) _buildControlButtons(settings, player),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建歌词内容
  Widget _buildLyricsContent(
    SettingsProvider settings,
    PlayerProvider player,
  ) {
    final parsedLyrics = player.parsedLyrics;
    final currentLyricIndex = player.currentLyricIndex;

    final fontFamily = settings.fontName.isNotEmpty ? settings.fontName : null;

    if (parsedLyrics == null || parsedLyrics.lines.isEmpty) {
      return Text(
        '暂无歌词',
        style: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white.withOpacity(0.6),
          fontSize: settings.desktopLyricsFontSize,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前歌词
        if (currentLyricIndex >= 0 && currentLyricIndex < parsedLyrics.lines.length)
          Text(
            parsedLyrics.lines[currentLyricIndex].text,
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontSize: settings.desktopLyricsFontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        // 下一句歌词（如果存在）
        if (currentLyricIndex + 1 < parsedLyrics.lines.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              parsedLyrics.lines[currentLyricIndex + 1].text,
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white.withOpacity(0.4),
                fontSize: settings.desktopLyricsFontSize - 4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(
    SettingsProvider settings,
    PlayerProvider player,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 锁定按钮
          if (settings.showLockButton)
            IconButton(
              icon: Icon(
                _isLocked ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isLocked = !_isLocked;
                });
              },
              tooltip: _isLocked ? '解锁' : '锁定',
            ),
          // 播放/暂停按钮
          if (settings.showControlButtons)
            IconButton(
              icon: Icon(
                player.isPlaying ? CupertinoIcons.pause_circle : CupertinoIcons.play_circle,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                player.togglePlayPause();
              },
              tooltip: player.isPlaying ? '暂停' : '播放',
            ),
          // 上一首按钮
          if (settings.showControlButtons)
            IconButton(
              icon: Icon(
                CupertinoIcons.backward_end,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                player.playPrevious();
              },
              tooltip: '上一首',
            ),
          // 下一首按钮
          if (settings.showControlButtons)
            IconButton(
              icon: Icon(
                CupertinoIcons.forward_end,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                player.playNext();
              },
              tooltip: '下一首',
            ),
        ],
      ),
    );
  }
}
