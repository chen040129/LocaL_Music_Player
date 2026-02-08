
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/player_bar_provider.dart';
import 'models/playlist_model.dart';
import 'widgets/player_control_bar_draggable.dart';
import 'widgets/player_bar_snapshot_transition.dart';
import 'services/player_bar_window_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载保存的窗口位置
  final prefs = await SharedPreferences.getInstance();
  final savedX = prefs.getDouble('player_bar_window_x') ?? 100.0;
  final savedY = prefs.getDouble('player_bar_window_y') ?? 100.0;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // 窗口配置 - 设置为无边框窗口
    const windowOptions = WindowOptions(
      size: Size(600, 80),
      minimumSize: Size(500, 70),
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

  runApp(const PlayerBarApp());
}

class PlayerBarApp extends StatefulWidget {
  const PlayerBarApp({Key? key}) : super(key: key);

  @override
  State<PlayerBarApp> createState() => _PlayerBarAppState();
}

class _PlayerBarAppState extends State<PlayerBarApp> with WindowListener {
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
    await prefs.setDouble('player_bar_x', position.dx);
    await prefs.setDouble('player_bar_y', position.dy);
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => MusicProvider()),
        ChangeNotifierProvider(create: (context) => PlaylistService()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider2<MusicProvider, SettingsProvider, PlayerProvider>(
          create: (context) {
            return PlayerProvider();
          },
          update: (context, musicProvider, settingsProvider, playerProvider) {
            playerProvider ??= PlayerProvider();
            playerProvider.setMusicProvider(musicProvider);
            playerProvider.setSettingsProvider(settingsProvider);
            return playerProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Music Player Bar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.transparent,
                child: PlayerBarSnapshotTransition(
                  child: const DraggablePlayerControlBar(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
