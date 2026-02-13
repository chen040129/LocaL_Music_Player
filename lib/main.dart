import 'package:flutter/material.dart';
import 'package:flutter_music_player/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'models/playlist_model.dart';
import 'package:flutter_music_player/pages/artists_page.dart';
import 'package:flutter_music_player/pages/albums_page.dart';
import 'providers/navigation_provider.dart';
import 'widgets/animated_theme.dart';

// 全局变量保存Provider引用
MusicProvider? globalMusicProvider;
PlayerProvider? globalPlayerProvider;
bool _hasRestoredPlayProgress = false; // 标记是否已恢复播放进度
final globalLiquidGlassViewController = LiquidGlassViewController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent, // 使用透明背景，避免主题切换时出现白色边框
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 监听窗口关闭事件
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
    }
    // 窗口透明度现在由背景层控制，不需要单独初始化
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 应用退出时保存数据
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      musicProvider.saveData();
    }
  }

  @override
  void onWindowClose() async {
    // 先隐藏窗口，让用户感觉立即关闭
    await windowManager.hide();
    // 保存播放进度
    if (globalPlayerProvider != null) {
      await globalPlayerProvider!.savePlayProgress();
      globalPlayerProvider!.stop();
    }
    // 然后在后台保存数据
    if (globalMusicProvider != null) {
      await globalMusicProvider!.saveData();
    }
    // 最后彻底关闭窗口
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) {
          final provider = MusicProvider();
          globalMusicProvider = provider;
          return provider;
        }),
        ChangeNotifierProvider(create: (context) => PlaylistService()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider2<MusicProvider, SettingsProvider, PlayerProvider>(
          create: (context) {
            final provider = PlayerProvider();
            globalPlayerProvider = provider;
            return provider;
          },
          update: (context, musicProvider, settingsProvider, playerProvider) {
            playerProvider ??= PlayerProvider();
            playerProvider.setMusicProvider(musicProvider);
            playerProvider.setSettingsProvider(settingsProvider);
            globalPlayerProvider = playerProvider;
            // 只在首次初始化且音乐列表已加载时恢复播放进度
            if (!_hasRestoredPlayProgress && musicProvider.musicList.isNotEmpty) {
              _hasRestoredPlayProgress = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                playerProvider?.restorePlayProgress();
              });
            }
            return playerProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Music Player',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: ThemeTransition(
              themeMode: themeProvider.themeMode,
              child: Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Stack(
                    children: [
                      // 背景层 - 根据背景类型应用透明度
                      Positioned.fill(
                        child: Container(
                          color: settings.uiBackgroundType == UIBackgroundType.fluid
                              ? Colors.transparent
                              : (settings.windowOpacity < 0.01
                                  ? Colors.transparent
                                  : Theme.of(context).colorScheme.surface.withOpacity(settings.windowOpacity)),
                        ),
                      ),
                      // 液态玻璃背景捕获层
                      if (settings.playerBarStyle == PlayerBarStyle.liquidGlass)
                        Positioned.fill(
                          child: LiquidGlassView(
                            controller: globalLiquidGlassViewController,
                            pixelRatio: 1.0,
                            realTimeCapture: true,
                            refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
                            useSync: true,
                            backgroundWidget: const SizedBox.expand(),
                            children: const [],
                          ),
                        ),
                      // 内容层
                      const HomeScreen(),
                    ],
                  );
                },
              ),
            ),
            routes: {
              '/artists': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return ArtistsPage(navigateToArtist: args?['artist'] as String?);
              },
              '/albums': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return AlbumsPage(navigateToAlbum: args?['album'] as String?);
              },
            },
          );
        },
      ),
    );
  }
}
