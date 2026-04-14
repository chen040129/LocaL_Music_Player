import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'common.dart';
import 'desktop/desktop_lyrics.dart';
import 'desktop/extensions/window_controller_extension.dart';
import 'desktop/my_tray_listener.dart';
import 'models/playlist_model.dart';
import 'package:flutter_music_player/pages/albums_page.dart';
import 'package:flutter_music_player/pages/artists_page.dart';
import 'package:flutter_music_player/screens/home_screen.dart';
import 'providers/music_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'services/global_hotkey_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/animated_theme.dart';

// ==================== 全局变量 ====================

// Provider 全局引用
MusicProvider? globalMusicProvider;
PlayerProvider? globalPlayerProvider;
SettingsProvider? globalSettingsProvider;

// 服务全局实例
final globalLiquidGlassViewController = LiquidGlassViewController();
final globalHotkeyService = GlobalHotkeyService();

// 状态标志
bool _hasRestoredPlayProgress = false; // 标记是否已恢复播放进度
bool _isTrayMenuInitialized = false;    // 托盘菜单初始化标志
MyTrayListener? _trayListener;          // 全局托盘监听器实例

// ==================== 应用入口 ====================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 只在桌面平台初始化窗口
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    final windowController = await WindowController.fromCurrentEngine();
    
    // 检查是否是桌面歌词窗口
    if (windowController.arguments == 'desktop_lyrics') {
      await _initDesktopLyricsWindow(windowController);
      return;
    }

    // 初始化主窗口
    await _initMainWindow();
    runApp(const MyApp());
  }
}

/// 初始化桌面歌词窗口
Future<void> _initDesktopLyricsWindow(WindowController windowController) async {
  await windowController.desktopLyricsCustomInitialize();

  final windowOptions = WindowOptions(
    title: "Desktop Lyrics",
    size: Platform.isLinux ? const Size(850, 200) : const Size(800, 150),
    minimumSize: const Size(300, 120),
    maximumSize: const Size(1920, 300),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: Platform.isMacOS ? false : true,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setMinimumSize(const Size(300, 120));
    await windowManager.setMaximumSize(const Size(1920, 300));
  });

  runApp(const DesktopLyrics());
}

/// 初始化主窗口
Future<void> _initMainWindow() async {
  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(1000, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
    
    // 初始化主窗口控制器和托盘
    mainWindowController = await WindowController.fromCurrentEngine();
    await _setupTrayIcon();
  });
}

// ==================== 托盘管理 ====================

/// 初始化托盘图标
Future<void> _setupTrayIcon() async {
  try {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
      isTemplate: true,
    );

    if (!Platform.isLinux) {
      await trayManager.setToolTip('Music Player');
    }

    // 使用单例模式，确保只添加一个监听器
    if (_trayListener == null) {
      _trayListener = MyTrayListener();
      trayManager.addListener(_trayListener!);
    }
  } catch (e) {
    // 托盘图标初始化失败，但不影响应用运行
  }
}

/// 初始化托盘菜单
Future<void> _setupTrayMenu() async {
  if (_isTrayMenuInitialized) return;

  try {
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: '显示窗口'),
          MenuItem.separator(),
          MenuItem(key: 'skipToPrevious', label: '上一首'),
          MenuItem(key: 'togglePlay', label: '播放/暂停'),
          MenuItem(key: 'skipToNext', label: '下一首'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
    _isTrayMenuInitialized = true;
  } catch (e) {
    // 托盘菜单设置失败，但不影响应用运行
  }
}

// ==================== 应用主类 ====================

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, WindowListener {
  static bool _isWindowMethodsInitialized = false;
  static bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 监听窗口关闭事件
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      // 初始化主窗口自定义方法
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final windowController = await WindowController.fromCurrentEngine();
        if (globalPlayerProvider != null) {
          await windowController.mainCustomInitialize(globalPlayerProvider!);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    globalHotkeyService.dispose();
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
    print('[${DateTime.now().toIso8601String()}] onWindowClose started');
    // 1. 关闭桌面歌词窗口（不等待完成）
    if (lyricsWindowController != null) {
      try {
        print('[${DateTime.now().toIso8601String()}] Closing desktop lyrics window');
        lyricsWindowController!.close().then((_) {
          lyricsWindowVisible = false;
          print('[${DateTime.now().toIso8601String()}] Desktop lyrics window closed');
        });
      } catch (e) {
        // 关闭桌面歌词窗口失败，继续执行
      }
    }
    
    // 2. 跳过更新桌面歌词设置，因为应用即将关闭，不需要保存这个状态
    // 直接设置标志位，避免延迟
    lyricsWindowVisible = false;
    print('[${DateTime.now().toIso8601String()}] Desktop lyrics settings updated');

    // 3. 保存播放进度
    print('[${DateTime.now().toIso8601String()}] About to save play progress');
    if (globalPlayerProvider != null) {
      try {
        await globalPlayerProvider!.savePlayProgress();
        print('[${DateTime.now().toIso8601String()}] Play progress saved');
      } catch (e) {
        // 保存播放进度失败，继续执行
      }
    }

    // 4. 保存音乐数据
    print('[${DateTime.now().toIso8601String()}] About to save music data');
    if (globalMusicProvider != null) {
      try {
        await globalMusicProvider!.saveData();
        print('[${DateTime.now().toIso8601String()}] Music data saved');
      } catch (e) {
        // 保存音乐数据失败，继续执行
      }
    }

    // 5. 真正退出应用
    print('[${DateTime.now().toIso8601String()}] About to destroy window');
    if (Platform.isWindows) {
      // 移除监听器，防止重复触发
      print('[${DateTime.now().toIso8601String()}] Removing window listener');
      windowManager.removeListener(this);
      print('[${DateTime.now().toIso8601String()}] About to destroy window');
      await windowManager.destroy();
      print('[${DateTime.now().toIso8601String()}] Window destroyed');
    } else {
      print('[${DateTime.now().toIso8601String()}] Exiting application');
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 主题提供者
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // 音乐提供者
        ChangeNotifierProvider(create: (context) {
          final provider = MusicProvider();
          globalMusicProvider = provider;
          return provider;
        }),
        // 播放列表服务
        ChangeNotifierProvider(create: (context) => PlaylistService()),
        // 导航提供者
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        // 设置提供者
        ChangeNotifierProvider(create: (context) {
          final provider = SettingsProvider();
          globalSettingsProvider = provider;
          return provider;
        }),
        // 播放器提供者（依赖音乐和设置提供者）
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
            
            // 初始化全局热键服务
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (playerProvider != null) {
                globalHotkeyService.initialize(
                  context: context,
                  playerProvider: playerProvider!,
                  settingsProvider: settingsProvider,
                );
                _setupTrayMenu();
              }
            });
            
            // 恢复播放进度
            if (!_hasRestoredPlayProgress &&
                musicProvider.hasInitialized &&
                musicProvider.musicList.isNotEmpty) {
              _hasRestoredPlayProgress = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                playerProvider?.restorePlayProgress();
              });
            }
            
            return playerProvider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, PlayerProvider>(
        builder: (context, themeProvider, playerProvider, child) {
          // 初始化窗口方法处理器（只初始化一次）
          if (!_isWindowMethodsInitialized && !_isInitializing) {
            _isInitializing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final windowController = await WindowController.fromCurrentEngine();
              if (playerProvider != null) {
                await windowController.mainCustomInitialize(playerProvider);
                _isWindowMethodsInitialized = true;
              }
              _isInitializing = false;
            });
          }

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
                      // 背景层
                      Positioned.fill(
                        child: Container(
                          color: settings.uiBackgroundType == UIBackgroundType.normal
                              ? Theme.of(context).colorScheme.surface.withOpacity(
                                  settings.windowOpacity.clamp(0.1, 1.0))
                              : Theme.of(context).colorScheme.surface,
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
