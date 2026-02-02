
import 'package:flutter/material.dart';
import 'package:flutter_music_player/widgets/sidebar.dart';
import 'package:flutter_music_player/widgets/playlist_area.dart';
import 'package:flutter_music_player/widgets/player_control_bar.dart';
import 'package:flutter_music_player/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:flutter_music_player/theme/theme_provider.dart';
import 'package:flutter_music_player/services/music_scanner_service.dart';
import 'package:flutter_music_player/providers/music_provider.dart';
import 'package:flutter_music_player/providers/navigation_provider.dart';
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
      final playlistService = Provider.of<PlaylistService>(context, listen: false);
      playlistService.loadPlaylists();
    });
  }

  Future<void> _updateWindowSize() async {
    _windowSize = await windowManager.getSize();
    if (mounted) {
      setState(() {});
    }
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
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.changePage(page);
  }

  /// 根据当前页面返回不同的页面组件
  Widget _buildCurrentPage() {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    switch (navigationProvider.currentPage) {
      case AppPage.songs:
        return SongsPage(onSidebarToggle: _toggleSidebar);
      case AppPage.albums:
        return AlbumsPage(navigateToAlbum: navigationProvider.navigateToAlbumName, onSidebarToggle: _toggleSidebar);
      case AppPage.artists:
        return ArtistsPage(navigateToArtist: navigationProvider.navigateToArtistName, onSidebarToggle: _toggleSidebar);
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
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
              // 加载进度条（非模态，不遮挡界面）
              Consumer<MusicProvider>(
                builder: (context, musicProvider, child) {
                  if (!musicProvider.isLoading) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '正在加载音乐库...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                        currentPage: Provider.of<NavigationProvider>(context).currentPage,
                        onPageChanged: _changePage,
                      ),
                    // 右侧内容区域
                    Expanded(
                      child: Column(
                        children: [
                          // 根据当前页面显示不同的内容
                          Expanded(
                            child: _buildCurrentPage(),
                          ),
                          // 底部播放控制栏
                          const PlayerControlBar(),
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
                    final size = _windowSize ?? await windowManager.getSize();
                    windowManager.setAspectRatio(0.0);
                    final newSize = Size(
                      size.width + details.delta.dx,
                      size.height,
                    );
                    await windowManager.setSize(newSize);
                    _windowSize = newSize;
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
                    final size = _windowSize ?? await windowManager.getSize();
                    windowManager.setAspectRatio(0.0);
                    final newSize = Size(
                      size.width + details.delta.dx,
                      size.height,
                    );
                    await windowManager.setSize(newSize);
                    _windowSize = newSize;
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
                    final size = _windowSize ?? await windowManager.getSize();
                    windowManager.setAspectRatio(0.0);
                    final newSize = Size(
                      size.width,
                      size.height + details.delta.dy,
                    );
                    await windowManager.setSize(newSize);
                    _windowSize = newSize;
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
                    final size = _windowSize ?? await windowManager.getSize();
                    windowManager.setAspectRatio(0.0);
                    final newSize = Size(
                      size.width + details.delta.dx,
                      size.height + details.delta.dy,
                    );
                    await windowManager.setSize(newSize);
                    _windowSize = newSize;
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
                    final size = _windowSize ?? await windowManager.getSize();
                    windowManager.setAspectRatio(0.0);
                    final newSize = Size(
                      size.width + details.delta.dx,
                      size.height + details.delta.dy,
                    );
                    await windowManager.setSize(newSize);
                    _windowSize = newSize;
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
