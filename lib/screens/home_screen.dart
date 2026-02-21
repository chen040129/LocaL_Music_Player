import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:flutter_music_player/widgets/sidebar.dart';
import 'package:flutter_music_player/widgets/playlist_area.dart';
import 'package:flutter_music_player/widgets/player_control_bar.dart';
import 'package:flutter_music_player/widgets/player_control_bar_liquid_glass.dart';
import 'package:flutter_music_player/providers/settings_provider.dart'
    show PlayerBarStyle, PlayerBarLength;
import 'package:flutter_music_player/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform, File;
import 'package:provider/provider.dart';
import 'package:flutter_music_player/theme/theme_provider.dart';
import 'package:flutter_music_player/services/music_scanner_service.dart';
import 'package:flutter_music_player/providers/music_provider.dart';
import 'package:flutter_music_player/providers/player_provider.dart';
import 'package:flutter_music_player/providers/navigation_provider.dart';
import 'package:flutter_music_player/providers/settings_provider.dart';
import 'package:flutter_music_player/constants/app_pages.dart';
import 'package:flutter_music_player/pages/songs_page.dart';
import 'package:flutter_music_player/pages/albums_page.dart';
import 'package:flutter_music_player/pages/artists_page.dart';
import 'package:flutter_music_player/pages/folders_page.dart';
import 'package:flutter_music_player/pages/playlists_page.dart';
import 'package:flutter_music_player/pages/scanner_page.dart';
import 'package:flutter_music_player/pages/library_page.dart';
import 'package:flutter_music_player/pages/statistics_page.dart';
import 'package:flutter_music_player/pages/settings_page.dart';
import 'package:flutter_music_player/pages/about_page.dart';
import 'package:flutter_music_player/models/playlist_model.dart';
import 'package:fluid_background/fluid_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarExpanded = true;
  int _currentPlayingIndex = 0;
  bool _isPlaying = false;
  bool _isAlwaysOnTop = false;
  List<Map<String, dynamic>> _songs = [];
  Size? _windowSize;
  Timer? _resizeDebounceTimer;
  final LiquidGlassViewController _liquidGlassViewController =
      LiquidGlassViewController();
  final LiquidGlassController _playerBarGlassController =
      LiquidGlassController();
  final GlobalKey _contentKey = GlobalKey();
  double _lastGlassOpacity = 0.2;
  ThemeMode _lastThemeMode = ThemeMode.system;

  // 当前页面
  AppPage _currentPage = AppPage.songs;

  // 窗口事件监听器
  late final _WindowEventListener _windowListener = _WindowEventListener(this);

  @override
  void initState() {
    super.initState();
    _updateWindowSize();
    // 添加窗口大小变化监听器
    windowManager.addListener(_windowListener);
    // 设置主题切换回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      themeProvider.onThemeChanged = _onThemeChanged;

      // 保存初始透明度和主题
      _lastGlassOpacity = settingsProvider.glassOpacity;
      _lastThemeMode = themeProvider.themeMode;

      // 初始化音乐数据，从本地加载
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      musicProvider.initialize();

      // 初始化歌单数据，从本地加载
      final playlistService =
          Provider.of<PlaylistService>(context, listen: false);
      playlistService.loadPlaylists();

      // 初始化内容区域尺寸
      _updateContentDimensions();
    });

    // 添加渲染回调，监听布局变化
    WidgetsBinding.instance.addPersistentFrameCallback(_onFrameCallback);
  }

  // 帧回调，用于监听布局变化
  void _onFrameCallback(Duration timestamp) {
    if (mounted) {
      // 检查内容区域尺寸是否变化
      final currentWidth = _getContentWidth();
      if (currentWidth != null && _lastContentWidth != null && currentWidth != _lastContentWidth) {
        _updateContentDimensions();
      }
      _lastContentWidth = currentWidth;
    }
    // 继续监听下一帧
    WidgetsBinding.instance.scheduleFrame();
  }

  double? _lastContentWidth;

  @override
  void dispose() {
    _resizeDebounceTimer?.cancel();
    // 移除窗口事件监听器
    windowManager.removeListener(_windowListener);
    super.dispose();
  }

  Future<void> _updateWindowSize() async {
    _windowSize = await windowManager.getSize();
    if (mounted) {
      setState(() {});
      // 延迟更新内容区域尺寸，等待窗口调整完成
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _updateContentDimensions();
        }
      });
    }
  }

  // 防抖方法：延迟执行窗口大小调整
  void _debouncedResize(Size newSize) {
    _resizeDebounceTimer?.cancel();
    _resizeDebounceTimer = Timer(const Duration(milliseconds: 16), () async {
      await windowManager.setSize(newSize);
      _windowSize = newSize;
    });
  }

  // 窗口控制功能
  void _minimizeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.minimize();
    }
  }

  void _maximizeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      bool isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
      // 窗口大小变化后，更新窗口大小并触发液态玻璃重新捕获
      await _updateWindowSize();
      if (mounted) {
        _liquidGlassViewController.captureOnce();
        // 延迟更新内容区域尺寸，确保窗口调整完成
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _updateContentDimensions();
          }
        });
      }
    }
  }

  void _closeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.close();
    }
  }

  void _toggleAlwaysOnTop() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _isAlwaysOnTop = !_isAlwaysOnTop;
      });
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
    // 延迟更新内容区域尺寸，等待侧边栏动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateContentDimensions();
      }
    });
  }

  // 获取内容区域的实际位置
  Offset? _getContentPosition() {
    try {
      final RenderBox? renderBox =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        return renderBox.localToGlobal(Offset.zero);
      }
    } catch (e) {
      // 忽略错误，返回null
    }
    return null;
  }

  // 获取内容区域的实际宽度
  double? _getContentWidth() {
    try {
      final RenderBox? renderBox =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final width = renderBox.size.width;
        // 如果宽度发生变化，更新缓存并触发重新构建
        if (_cachedContentWidth != null && _cachedContentWidth != width) {
          _cachedContentWidth = width;
          // 使用WidgetsBinding.instance.addPostFrameCallback确保在下一帧更新UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        } else if (_cachedContentWidth == null) {
          _cachedContentWidth = width;
        }
        return width;
      }
    } catch (e) {
      // 忽略错误，返回null
    }
    return null;
  }

  // 强制更新内容区域尺寸
  void _updateContentDimensions() {
    try {
      final RenderBox? renderBox =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        // 清除缓存，强制重新计算
        _cachedContentWidth = null;
        setState(() {
          // 触发重新构建，更新液态玻璃宽度
        });
      }
    } catch (e) {
      // 忽略错误
    }
  }

  double? _cachedContentWidth;

  void _forceWindowRedraw() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setSize(await windowManager.getSize());
    }
  }

  void _onThemeChanged() async {
    // 主题变化时重新加载液态玻璃
    await _liquidGlassViewController.captureOnce();
    _forceWindowRedraw();
  }

  void _onGlassOpacityChanged(double newOpacity) async {
    // 透明度变化时重新加载液态玻璃
    await _liquidGlassViewController.captureOnce();
  }

  void _updateWindowBorderRadius(double borderRadius) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 触发窗口重绘以应用新的圆角
      await windowManager.setSize(await windowManager.getSize());
    }
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _selectSong(int index) {
    setState(() {
      _currentPlayingIndex = index;
      _isPlaying = true;
    });
  }

  /// 切换页面
  void _changePage(AppPage page) {
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.changePage(page);
  }

  /// 构建流体背景
  Widget _buildFluidBackground(
      PlayerProvider playerProvider, SettingsProvider settings) {
    // 获取歌曲封面颜色
    final music = playerProvider.currentMusic;
    Color? primaryColor;
    Color? secondaryColor;
    Color? tertiaryColor;

    try {
      if (music?.coverColor != null &&
          music!.coverColor! >= 0 &&
          music.coverColor! <= 0xFFFFFFFF) {
        primaryColor = Color(music.coverColor!);
      }
      if (music?.secondaryColor != null &&
          music!.secondaryColor! >= 0 &&
          music.secondaryColor! <= 0xFFFFFFFF) {
        secondaryColor = Color(music.secondaryColor!);
      }
      if (music?.tertiaryColor != null &&
          music!.tertiaryColor! >= 0 &&
          music.tertiaryColor! <= 0xFFFFFFFF) {
        tertiaryColor = Color(music.tertiaryColor!);
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }

    // 使用歌曲封面颜色，如果没有则使用默认颜色
    final colors = [
      primaryColor ?? Colors.blue,
      secondaryColor ?? Colors.purple,
      tertiaryColor ?? Colors.indigo,
      Colors.black,
    ];

    return FluidBackground(
      key: ValueKey('fluid_${music?.id ?? 0}'),
      initialPositions: InitialOffsets.custom([
        const Offset(0.3, 0.5),
        const Offset(0.7, 0.3),
        const Offset(0.2, 0.8),
        const Offset(0.8, 0.7),
      ]),
      initialColors: InitialColors.custom(colors),
      bubblesSize: settings.fluidBubblesSize,
      velocity: settings.isFluidDynamic ? settings.fluidVelocity : 0,
      bubbleMutationDuration: settings.isFluidDynamic
          ? Duration(milliseconds: settings.fluidAnimationDuration)
          : null,
      allowColorChanging: true,
      child: const SizedBox.expand(),
    );
  }

  /// 构建渐变背景
  Widget _buildGradientBackground(PlayerProvider playerProvider,
      SettingsProvider settings, ColorScheme colorScheme) {
    // 获取歌曲主题色
    Color? songColor;
    try {
      final coverColor = playerProvider.currentMusic?.coverColor;
      if (coverColor != null && coverColor.isFinite) {
        if (coverColor >= 0 && coverColor <= 0xFFFFFFFF) {
          final color = Color(coverColor);
          if (color.alpha >= 0 &&
              color.alpha <= 255 &&
              color.red >= 0 &&
              color.red <= 255 &&
              color.green >= 0 &&
              color.green <= 255 &&
              color.blue >= 0 &&
              color.blue <= 255) {
            songColor = color;
          }
        }
      }
    } catch (e) {
      debugPrint('获取封面颜色失败: $e');
    }

    // 如果歌曲没有主题色，使用黑色
    final topLeftColor = songColor ?? Colors.black;

    // 软件主题色：根据深色/浅色模式自动切换黑色或白色
    final bottomRightColor =
        colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white;

    // 使用用户界面独立的渐变类型和歌曲主题色占比
    if (settings.uiGradientType == GradientType.dynamic) {
      // 动态渐变
      return Opacity(
        opacity: settings.windowOpacity,
        child: AnimatedContainer(
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topLeftColor,
                Color.lerp(topLeftColor, bottomRightColor,
                    1 - settings.uiGradientSongColorRatio)!,
                bottomRightColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
    } else {
      // 静态渐变
      return Opacity(
        opacity: settings.windowOpacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topLeftColor,
                Color.lerp(topLeftColor, bottomRightColor,
                    1 - settings.uiGradientSongColorRatio)!,
                bottomRightColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
    }
  }

  /// 根据当前页面返回不同的页面组件
  Widget _buildCurrentPage() {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentPage = navigationProvider.currentPage;

    // 直接更新当前页面状态，不调用setState
    _currentPage = currentPage;

    // 使用ValueKey确保页面切换时重新创建
    switch (currentPage) {
      case AppPage.songs:
        return SongsPage(key: ValueKey('songs_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.albums:
        return AlbumsPage(
            key: ValueKey('albums_$_currentPage'),
            navigateToAlbum: navigationProvider.navigateToAlbumName,
            onSidebarToggle: _toggleSidebar);
      case AppPage.artists:
        return ArtistsPage(
            key: ValueKey('artists_$_currentPage'),
            navigateToArtist: navigationProvider.navigateToArtistName,
            onSidebarToggle: _toggleSidebar);
      case AppPage.folders:
        return FoldersPage(key: ValueKey('folders_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.playlists:
        return PlaylistsPage(key: ValueKey('playlists_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.scanner:
        return ScannerPage(key: ValueKey('scanner_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.library:
        return LibraryPage(key: ValueKey('library_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.statistics:
        return StatisticsPage(key: ValueKey('statistics_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.settings:
        return SettingsPage(key: ValueKey('settings_$_currentPage'), onSidebarToggle: _toggleSidebar);
      case AppPage.about:
        return AboutPage(key: ValueKey('about_$_currentPage'), onSidebarToggle: _toggleSidebar);
      default:
        return SongsPage(key: ValueKey('songs_$_currentPage'), onSidebarToggle: _toggleSidebar);
    }
  }

  /// 处理音乐扫描完成
  void _onMusicScanned(List<dynamic> scannedMusic) {
    setState(() {
      // 将MusicInfo对象转换为Map
      _songs = scannedMusic.map((music) {
        return {
          'id': music.id,
          'filePath': music.filePath,
          'title': music.title,
          'artist': music.artist,
          'album': music.album,
          'duration': music.duration,
          'quality': music.quality,
        };
      }).toList();

      // 如果有音乐被扫描到，设置第一首为当前播放
      if (_songs.isNotEmpty) {
        _currentPlayingIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // 移除强制设置窗口不透明度的代码，允许窗口透明度由背景层控制

        // 构建背景内容（不包含播放栏）
        // 液态玻璃的背景需要提供一个实际的背景色，避免显示LiquidGlassView的黑色背景
        // 使用主题的surface颜色，并根据窗口透明度调整
        Widget backgroundContent = Material(
          color: Theme.of(context).colorScheme.surface.withOpacity(settings.windowOpacity),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // 背景层
                Positioned.fill(
                  child: Consumer2<PlayerProvider, SettingsProvider>(
                    builder: (context, player, settings, child) {
                      final theme = Theme.of(context);
                      final colorScheme = theme.colorScheme;
                      switch (settings.uiBackgroundType) {
                        case UIBackgroundType.normal:
                          return Container(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.surface.withOpacity(settings.windowOpacity),
                          );
                        case UIBackgroundType.fluid:
                          return Stack(
                            children: [
                              // 添加一个半透明的背景层以支持模糊效果
                              Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(settings.windowOpacity),
                              ),
                              // 流体背景
                              _buildFluidBackground(player, settings),
                            ],
                          );
                        case UIBackgroundType.gradient:
                          return _buildGradientBackground(
                              player, settings, colorScheme);
                        case UIBackgroundType.customImage:
                          if (settings.uiCustomImagePath.isNotEmpty) {
                            BoxFit boxFit;
                            switch (settings.uiImageFitType) {
                              case ImageFitType.fill:
                                boxFit = BoxFit.fill;
                                break;
                              case ImageFitType.cover:
                                boxFit = BoxFit.cover;
                                break;
                              case ImageFitType.contain:
                                boxFit = BoxFit.contain;
                                break;
                              case ImageFitType.fitWidth:
                                boxFit = BoxFit.fitWidth;
                                break;
                              case ImageFitType.fitHeight:
                                boxFit = BoxFit.fitHeight;
                                break;
                              case ImageFitType.none:
                                boxFit = BoxFit.none;
                                break;
                            }
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(0), // 强制设置为0，无弧度
                              child: Image.file(
                                File(settings.uiCustomImagePath),
                                fit: boxFit,
                              ),
                            );
                          }
                          return _buildFluidBackground(player, settings);
                      }
                    },
                  ),
                ),
                // 内容层
                Padding(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      // 主内容
                      Column(
                        children: [
                          // 自定义标题栏
                          if (Platform.isWindows)
                            CustomTitleBar(
                              title: '音乐播放器',
                              onMinimize: _minimizeWindow,
                              onMaximize: _maximizeWindow,
                              onClose: _closeWindow,
                              onAlwaysOnTop: _toggleAlwaysOnTop,
                              isAlwaysOnTop: _isAlwaysOnTop,
                              onToggleSidebar: _toggleSidebar,
                            ),
                          // 主内容区域
                          Expanded(
                            child: Row(
                              children: [
                                // 左侧导航栏 - 只在展开时显示
                                if (_isSidebarExpanded)
                                  Sidebar(
                                    isExpanded: _isSidebarExpanded,
                                    onToggle: _toggleSidebar,
                                    onMusicScanned: _onMusicScanned,
                                    currentPage:
                                        Provider.of<NavigationProvider>(context)
                                            .currentPage,
                                    onPageChanged: _changePage,
                                  ),
                                // 右侧内容区域
                                Expanded(
                                  key: _contentKey,
                                  child: Column(
                                    children: [
                                      // 主内容区域
                                      Expanded(
                                        child: _buildCurrentPage(),
                                      ),
                                      // 播放栏 - 放在主内容区域内
                                      // 注意：液态玻璃样式的播放栏由 LiquidGlassView 处理
                                      // 只有在内容宽度模式下才在这里显示播放栏
                                      if (settings.playerBarStyle == PlayerBarStyle.normal &&
                                          settings.playerBarLength == PlayerBarLength.contentWidth)
                                        const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: PlayerControlBar(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // 默认模式下的全宽播放栏 - 放在 Stack 顶层以覆盖导航栏
                      if (settings.playerBarStyle == PlayerBarStyle.normal &&
                          settings.playerBarLength == PlayerBarLength.fullWidth)
                        const Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: PlayerControlBar(),
                        ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // 根据播放栏样式决定是否使用 LiquidGlassView
        // 只要使用液态玻璃样式就使用 LiquidGlassView
        if (settings.playerBarStyle == PlayerBarStyle.liquidGlass) {
          // 获取内容区域的位置和宽度
          final contentPosition = _getContentPosition();
          final contentWidth = _getContentWidth() ?? 
              MediaQuery.of(context).size.width - (_isSidebarExpanded ? 240 : 0);

          // 根据播放栏长度决定宽度和位置
          final playerBarWidth = settings.playerBarLength == PlayerBarLength.fullWidth
              ? MediaQuery.of(context).size.width - 32
              : contentWidth - 32;

          // 计算左边距：内容宽度模式下需要加上侧边栏的宽度
          final double leftMargin = settings.playerBarLength == PlayerBarLength.fullWidth
              ? 16
              : (contentPosition?.dx ?? 0) + 16;

          return LiquidGlassView(
            controller: _liquidGlassViewController,
            pixelRatio: 1.0,
            realTimeCapture: true,
            refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
            useSync: true,
            backgroundWidget: backgroundContent,
            children: [
              // 播放栏的液态玻璃效果
              LiquidGlass(
                controller: _playerBarGlassController,
                position: LiquidGlassAlignPosition(
                  alignment: Alignment.bottomCenter,
                  margin: EdgeInsets.only(
                    bottom: 16,
                    left: leftMargin,
                    right: 16,
                  ),
                ),
                width: playerBarWidth,
                height: 80,
                magnification: settings.liquidGlassMagnification,
                refractionMode: LiquidGlassRefractionMode.shapeRefraction,
                enableInnerRadiusTransparent: false,
                diagonalFlip: 0,
                distortion: settings.liquidGlassDistortion,
                distortionWidth: settings.liquidGlassDistortionWidth,
                chromaticAberration: settings.liquidGlassChromaticAberration,
                saturation: settings.liquidGlassSaturation,
                draggable: false,
                blur: LiquidGlassBlur(
                  sigmaX: settings.liquidGlassBlurSigma,
                  sigmaY: settings.liquidGlassBlurSigma,
                ),
                shape: RoundedRectangleShape(
                  cornerRadius: settings.borderRadius,
                  borderWidth: 1.0,
                  borderSoftness: 2.5,
                  lightIntensity: 1.5,
                  oneSideLightIntensity: 0.4,
                  lightDirection: 39.0,
                  lightMode: LiquidGlassLightMode.edge,
                ),
                visibility: true,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha((settings.glassOpacity * 60).round())
                    : Colors.grey.withAlpha((settings.glassOpacity * 60).round()),
                child: const PlayerControlBarLiquidGlass(),
              ),
            ],
          );
        } else {
          // 普通模式，直接返回页面内容
          // 播放栏已经在右侧内容区域的Column中处理了
          return backgroundContent;
        }
      },
    );
  }

  // 监听设置变化
  void _listenToSettingsChanges(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // 检查透明度是否变化
    if (settingsProvider.glassOpacity != _lastGlassOpacity) {
      _lastGlassOpacity = settingsProvider.glassOpacity;
      _onGlassOpacityChanged(_lastGlassOpacity);
    }

    // 检查主题是否变化
    if (themeProvider.themeMode != _lastThemeMode) {
      _lastThemeMode = themeProvider.themeMode;
      _onThemeChanged();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToSettingsChanges(context);
  }
}

/// 窗口事件监听器
class _WindowEventListener extends WindowListener {
  final _HomeScreenState _state;

  _WindowEventListener(this._state);

  @override
  void onWindowResize() {
    // 当窗口大小变化时，更新窗口大小并触发液态玻璃重新捕获
    _state._updateWindowSize().then((_) {
      if (_state.mounted) {
        _state._liquidGlassViewController.captureOnce();
      }
    });
  }

  @override
  void onWindowMaximize() {
    // 当窗口最大化时，更新窗口大小并触发液态玻璃重新捕获
    _state._updateWindowSize().then((_) {
      if (_state.mounted) {
        _state._liquidGlassViewController.captureOnce();
      }
    });
  }

  @override
  void onWindowUnmaximize() {
    // 当窗口恢复时，更新窗口大小并触发液态玻璃重新捕获
    _state._updateWindowSize().then((_) {
      if (_state.mounted) {
        _state._liquidGlassViewController.captureOnce();
      }
    });
  }

  @override
  void onWindowRestore() {
    // 当窗口恢复时，更新窗口大小并触发液态玻璃重新捕获
    _state._updateWindowSize().then((_) {
      if (_state.mounted) {
        _state._liquidGlassViewController.captureOnce();
      }
    });
  }

  @override
  void onWindowFocus() {
    // 当窗口获得焦点时，更新窗口大小并触发液态玻璃重新捕获
    _state._updateWindowSize().then((_) {
      if (_state.mounted) {
        _state._liquidGlassViewController.captureOnce();
      }
    });
  }

  @override
  void onWindowEvent(String eventName) {
    // 监听所有窗口事件，包括拖动标题栏
    if (eventName == 'onWindowResize' || 
        eventName == 'onWindowMaximize' || 
        eventName == 'onWindowUnmaximize' ||
        eventName == 'onWindowRestore') {
      _state._updateWindowSize().then((_) {
        if (_state.mounted) {
          _state._liquidGlassViewController.captureOnce();
        }
      });
    }
  }
}
