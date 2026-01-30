// 优化后的主屏幕 - 减少不必要的重建
import 'package:flutter/material.dart';
import 'package:flutter_music_player/widgets/sidebar_optimized.dart';
import 'package:flutter_music_player/widgets/playlist_area_optimized.dart';
import 'package:flutter_music_player/widgets/player_control_bar_optimized.dart';
import 'package:flutter_music_player/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:flutter_music_player/theme/theme_provider.dart';
import 'package:flutter_music_player/providers/music_provider.dart';
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

class HomeScreenOptimized extends StatefulWidget {
  const HomeScreenOptimized({Key? key}) : super(key: key);

  @override
  State<HomeScreenOptimized> createState() => _HomeScreenOptimizedState();
}

class _HomeScreenOptimizedState extends State<HomeScreenOptimized> {
  bool _isSidebarExpanded = true;
  int _currentPlayingIndex = 0;
  bool _isPlaying = false;
  bool _isAlwaysOnTop = false;
  List<Map<String, dynamic>> _songs = [];
  AppPage _currentPage = AppPage.songs;

  @override
  void initState() {
    super.initState();
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

  // 窗口控制功能
  Future<void> _minimizeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.minimize();
    }
  }

  Future<void> _maximizeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      bool isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    }
  }

  Future<void> _closeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.close();
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
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

  Future<void> _forceWindowRedraw() async {
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
    setState(() {
      _currentPage = page;
    });
  }

  /// 根据当前页面返回不同的页面组件
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.songs:
        return const SongsPage();
      case AppPage.albums:
        return const AlbumsPage();
      case AppPage.artists:
        return const ArtistsPage();
      case AppPage.folders:
        return const FoldersPage();
      case AppPage.playlists:
        return const PlaylistsPage();
      case AppPage.scanner:
        return const ScannerPage();
      case AppPage.library:
        return const LibraryPage();
      case AppPage.statistics:
        return const StatisticsPage();
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.about:
        return const AboutPage();
      default:
        return const SongsPage();
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
      body: Column(
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
            ),
          // 加载进度条（非模态，不遮挡界面）
          _LoadingIndicator(),
          // 主内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                SidebarOptimized(
                  isExpanded: _isSidebarExpanded,
                  onToggle: _toggleSidebar,
                  onMusicScanned: _onMusicScanned,
                  currentPage: _currentPage,
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
                      PlayerControlBarOptimized(
                        isPlaying: _isPlaying,
                        onPlayPauseToggle: _togglePlay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载指示器组件 - 使用Selector减少重建
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, bool>(
      selector: (context, musicProvider) => musicProvider.isLoading,
      builder: (context, isLoading, child) {
        if (!isLoading) {
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
                child: Selector<MusicProvider, double>(
                  selector: (context, musicProvider) => musicProvider.loadingProgress,
                  builder: (context, progress, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '正在加载音乐库... ${(progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
