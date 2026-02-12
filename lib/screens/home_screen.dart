import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_music_player/widgets/sidebar.dart';
import 'package:flutter_music_player/widgets/playlist_area.dart';
import 'package:flutter_music_player/widgets/player_control_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _updateWindowSize();
    // 设置主题切换回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.onThemeChanged = _forceWindowRedraw;

      // 初始化音乐数据，从本地加载
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      musicProvider.initialize();

      // 初始化歌单数据，从本地加载
      final playlistService =
          Provider.of<PlaylistService>(context, listen: false);
      playlistService.loadPlaylists();
    });
  }

  @override
  void dispose() {
    _resizeDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateWindowSize() async {
    _windowSize = await windowManager.getSize();
    if (mounted) {
      setState(() {});
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
  }

  void _forceWindowRedraw() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setSize(await windowManager.getSize());
    }
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
  Widget _buildGradientBackground(
      PlayerProvider playerProvider, SettingsProvider settings, ColorScheme colorScheme) {
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
      return AnimatedContainer(
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
      );
    } else {
      // 静态渐变
      return Container(
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
      );
    }
  }

  /// 根据当前页面返回不同的页面组件
  Widget _buildCurrentPage() {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    switch (navigationProvider.currentPage) {
      case AppPage.songs:
        return SongsPage(onSidebarToggle: _toggleSidebar);
      case AppPage.albums:
        return AlbumsPage(
            navigateToAlbum: navigationProvider.navigateToAlbumName,
            onSidebarToggle: _toggleSidebar);
      case AppPage.artists:
        return ArtistsPage(
            navigateToArtist: navigationProvider.navigateToArtistName,
            onSidebarToggle: _toggleSidebar);
      case AppPage.folders:
        return FoldersPage(onSidebarToggle: _toggleSidebar);
      case AppPage.playlists:
        return PlaylistsPage(onSidebarToggle: _toggleSidebar);
      case AppPage.scanner:
        return ScannerPage(onSidebarToggle: _toggleSidebar);
      case AppPage.library:
        return LibraryPage(onSidebarToggle: _toggleSidebar);
      case AppPage.statistics:
        return StatisticsPage(onSidebarToggle: _toggleSidebar);
      case AppPage.settings:
        return SettingsPage(onSidebarToggle: _toggleSidebar);
      case AppPage.about:
        return AboutPage(onSidebarToggle: _toggleSidebar);
      default:
        return SongsPage(onSidebarToggle: _toggleSidebar);
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
        // 始终保持窗口完全不透明，透明度由背景层控制
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            windowManager.setOpacity(1.0);
          }
        });

        return Material(
          color: Colors.transparent,
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
                            color: Colors.transparent,
                          );
                        case UIBackgroundType.fluid:
                          return _buildFluidBackground(player, settings);
                        case UIBackgroundType.gradient:
                          return _buildGradientBackground(player, settings, colorScheme);
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
                              borderRadius: BorderRadius.circular(settings.borderRadius),
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
                  padding: EdgeInsets.all(settings.borderRadius > 0
                      ? settings.borderRadius * 0.3
                      : 0),
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
                                  child: Stack(
                                    children: [
                                      // 主内容区域
                                      Column(
                                        children: [
                                          // 根据当前页面显示不同的内容
                                          Expanded(
                                            child: _buildCurrentPage(),
                                          ),
                                        ],
                                      ),
                                      // 底部播放控制栏 - 使用Positioned定位在底部
                                      Positioned(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                        child: const PlayerControlBar(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // 窗口边缘调整大小区域
                      if (Platform.isWindows) ...[
                        // 左边缘
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 5,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeLeft,
                            child: GestureDetector(
                              onPanUpdate: (details) async {
                                final size = _windowSize ??
                                    await windowManager.getSize();
                                windowManager.setAspectRatio(0.0);
                                final newSize = Size(
                                  size.width + details.delta.dx,
                                  size.height,
                                );
                                _debouncedResize(newSize);
                              },
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                        ),
                        // 右边缘
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 5,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeRight,
                            child: GestureDetector(
                              onPanUpdate: (details) async {
                                final size = _windowSize ??
                                    await windowManager.getSize();
                                windowManager.setAspectRatio(0.0);
                                final newSize = Size(
                                  size.width + details.delta.dx,
                                  size.height,
                                );
                                _debouncedResize(newSize);
                              },
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                        ),
                        // 下边缘
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 5,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeDown,
                            child: GestureDetector(
                              onPanUpdate: (details) async {
                                final size = _windowSize ??
                                    await windowManager.getSize();
                                windowManager.setAspectRatio(0.0);
                                final newSize = Size(
                                  size.width,
                                  size.height + details.delta.dy,
                                );
                                _debouncedResize(newSize);
                              },
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                        ),
                        // 左下角
                        Positioned(
                          left: 0,
                          bottom: 0,
                          width: 10,
                          height: 10,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeDownLeft,
                            child: GestureDetector(
                              onPanUpdate: (details) async {
                                final size = _windowSize ??
                                    await windowManager.getSize();
                                windowManager.setAspectRatio(0.0);
                                final newSize = Size(
                                  size.width + details.delta.dx,
                                  size.height + details.delta.dy,
                                );
                                _debouncedResize(newSize);
                              },
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                        ),
                        // 右下角
                        Positioned(
                          right: 0,
                          bottom: 0,
                          width: 10,
                          height: 10,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeDownRight,
                            child: GestureDetector(
                              onPanUpdate: (details) async {
                                final size = _windowSize ??
                                    await windowManager.getSize();
                                windowManager.setAspectRatio(0.0);
                                final newSize = Size(
                                  size.width + details.delta.dx,
                                  size.height + details.delta.dy,
                                );
                                _debouncedResize(newSize);
                              },
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
