import 'package:flutter/material.dart';
import 'package:flutter_music_player/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform, exit;
import 'package:provider/provider.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
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
import 'services/global_hotkey_service.dart';
import 'desktop/desktop_lyrics.dart';
import 'desktop/extensions/window_controller_extension.dart';
import 'widgets/desktop_lyrics_window.dart';
import 'desktop/my_tray_listener.dart';
import 'common.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';

// 全局变量保存Provider引用
MusicProvider? globalMusicProvider;
PlayerProvider? globalPlayerProvider;
bool _hasRestoredPlayProgress = false; // 标记是否已恢复播放进度
final globalLiquidGlassViewController = LiquidGlassViewController();
final globalHotkeyService = GlobalHotkeyService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化桌面多窗口
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // 检查是否是桌面歌词窗口
    final windowController = await WindowController.fromCurrentEngine();
    print('Window arguments: ${windowController.arguments}');
    if (windowController.arguments == 'desktop_lyrics') {
      print('Initializing desktop lyrics window...');
      await windowController.desktopLyricsCustomInitialize();

      WindowOptions windowOptions = WindowOptions(
        title: "Desktop Lyrics",
        size: Platform.isLinux ? Size(850, 200) : Size(800, 150),
        minimumSize: const Size(300, 80),
        maximumSize: const Size(1920, 300),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
        skipTaskbar: Platform.isMacOS ? false : true,
        alwaysOnTop: true,
      );

      print('Window options: ${windowOptions.toString()}');

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        print('Setting up frameless window...');
        await windowManager.setAsFrameless();
        print('Setting minimum and maximum size...');
        await windowManager.setMinimumSize(const Size(300, 120));
        await windowManager.setMaximumSize(const Size(1920, 300));
        print('Desktop lyrics window setup complete, but not showing yet');
        // 不在这里显示窗口，等待主窗口发送显示命令
      });

      print('Running DesktopLyrics app...');
      runApp(DesktopLyrics());
      return; // 桌面歌词窗口直接返回，不执行后面的代码
    }

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1000, 700), // 增加最小尺寸，确保所有UI元素都能正常显示
      center: true,
      backgroundColor: Colors.transparent, // 使用透明背景，避免主题切换时出现白色边框
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();

      // 初始化主窗口控制器
      mainWindowController = await WindowController.fromCurrentEngine();
      print('主窗口控制器初始化完成');

      // 初始化托盘图标（但不设置菜单）
      await _setupTrayIcon();
    });

    // 添加窗口监听器
    windowManager.addListener(_MyWindowListener());

    runApp(const MyApp());
  }

  // 初始化桌面歌词窗口（在主窗口中）
  if (!isMobile) {
    await initDesktopLyrics();
  }
}

/// 初始化托盘图标
Future<void> _setupTrayIcon() async {
  print('开始初始化托盘图标...');
  try {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
      isTemplate: true,
    );
    print('托盘图标设置成功');

    if (!Platform.isLinux) {
      await trayManager.setToolTip('Music Player');
      print('托盘提示设置成功');
    }

    // 使用单例模式，确保只添加一个监听器
    if (_trayListener == null) {
      _trayListener = MyTrayListener();
      trayManager.addListener(_trayListener!);
      print('托盘监听器添加成功');
    } else {
      print('托盘监听器已存在，跳过添加');
    }

    print('托盘图标初始化完成');
  } catch (e) {
    print('托盘图标初始化失败: $e');
  }
}

/// 初始化托盘菜单
Future<void> _setupTrayMenu() async {
  // 防止重复初始化托盘菜单
  if (_isTrayMenuInitialized) {
    print('托盘菜单已初始化，跳过重复初始化');
    return;
  }
  
  print('开始初始化托盘菜单...');
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
    print('托盘菜单设置成功');
  } catch (e) {
    print('托盘菜单设置失败: $e');
  }
}

// 全局托盘监听器实例
MyTrayListener? _trayListener;

// 托盘菜单初始化标志
bool _isTrayMenuInitialized = false;

/// 窗口监听器
class _MyWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    // 关闭窗口时隐藏到托盘
    windowManager.hide();
  }
}

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
    // 窗口透明度现在由背景层控制，不需要单独初始化
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    // 释放全局热键服务资源
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
    print('onWindowClose called');
    // 隐藏窗口到托盘
    await windowManager.hide();
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
        ChangeNotifierProxyProvider2<MusicProvider, SettingsProvider,
            PlayerProvider>(
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
                // 初始化托盘菜单（在PlayerProvider初始化之后）
                _setupTrayMenu();
              }
            });
            // 只在首次初始化且音乐列表已加载完成时恢复播放进度
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
              final windowController =
                  await WindowController.fromCurrentEngine();
              print('Initializing main window custom methods...');
              print('playerProvider is null: ${playerProvider == null}');

              if (playerProvider != null) {
                print(
                    'playerProvider is initialized, setting up method handler...');
                await windowController.mainCustomInitialize(playerProvider);
                _isWindowMethodsInitialized = true;
                _isInitializing = false;
              } else {
                print('Error: playerProvider is null');
                _isInitializing = false;
              }
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
                      // 背景层 - 根据背景类型应用透明度
                      Positioned.fill(
                        child: Container(
                          color: settings.uiBackgroundType ==
                                  UIBackgroundType.normal
                              ? (settings.windowOpacity < 0.01
                                  ? Colors.transparent
                                  : Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(settings.windowOpacity))
                              : Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(1.0),
                        ),
                      ),
                      // 液态玻璃背景捕获层
                      if (settings.playerBarStyle == PlayerBarStyle.liquidGlass)
                        Positioned.fill(
                          child: LiquidGlassView(
                            controller: globalLiquidGlassViewController,
                            pixelRatio: 1.0,
                            realTimeCapture: true,
                            refreshRate:
                                LiquidGlassRefreshRate.deviceRefreshRate,
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
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return ArtistsPage(
                    navigateToArtist: args?['artist'] as String?);
              },
              '/albums': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return AlbumsPage(navigateToAlbum: args?['album'] as String?);
              },
            },
          );
        },
      ),
    );
  }
}
