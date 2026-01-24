
import 'package:flutter/material.dart';
import 'package:flutter_music_player/widgets/sidebar.dart';
import 'package:flutter_music_player/widgets/playlist_area.dart';
import 'package:flutter_music_player/widgets/player_control_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarExpanded = true;
  int _currentPlayingIndex = 0;
  bool _isPlaying = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          Sidebar(
            isExpanded: _isSidebarExpanded,
            onToggle: _toggleSidebar,
          ),
          // 右侧内容区域
          Expanded(
            child: Column(
              children: [
                // 播放列表区域
                Expanded(
                  child: PlaylistArea(
                    isSidebarExpanded: _isSidebarExpanded,
                    currentPlayingIndex: _currentPlayingIndex,
                    onSongTap: _selectSong,
                  ),
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
    );
  }
}
