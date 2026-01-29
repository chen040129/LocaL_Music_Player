
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
        return SongsPage();
      case AppPage.albums:
        return AlbumsPage();
      case AppPage.artists:
        return ArtistsPage();
      case AppPage.folders:
        return FoldersPage();
      case AppPage.playlists:
        return PlaylistsPage();
      case AppPage.scanner:
        return ScannerPage();
      case AppPage.library:
        return LibraryPage();
      case AppPage.statistics:
        return StatisticsPage();
      case AppPage.settings:
        return SettingsPage();
      case AppPage.about:
        return AboutPage();
      default:
        return SongsPage();
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
          // 主内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                Sidebar(
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
                      PlayerControlBar(
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
