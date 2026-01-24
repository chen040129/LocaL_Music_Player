
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  static const IconData musicNoteIcon = Icons.music_note;
  static const IconData albumIcon = Icons.album;
  static const IconData micIcon = Icons.mic;
  static const IconData folderIcon = Icons.folder;
  static const IconData playlistPlayIcon = Icons.playlist_play;
  static const IconData scannerIcon = Icons.scanner;
  static const IconData libraryMusicIcon = Icons.library_music;
  static const IconData barChartIcon = Icons.bar_chart;
  static const IconData settingsIcon = Icons.settings;
  static const IconData infoIcon = Icons.info;
  static const IconData menuOpenIcon = Icons.menu_open;
  static const IconData menuIcon = Icons.menu;

  final bool isExpanded;
  final VoidCallback onToggle;

  const Sidebar({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 240 : 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部展开/收起按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isExpanded)
                  const Text(
                    '音乐播放器',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isExpanded ? menuOpenIcon : menuIcon,
                    color: Colors.white,
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // 导航菜单项
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: musicNoteIcon,
                  iconColor: Colors.green,
                  title: '歌曲',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: albumIcon,
                  iconColor: Colors.red,
                  title: '专辑',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: micIcon,
                  iconColor: Colors.yellow,
                  title: '艺术家',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: folderIcon,
                  iconColor: Colors.purple,
                  title: '文件夹',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: playlistPlayIcon,
                  iconColor: Colors.blue,
                  title: '歌单',
                  isExpanded: isExpanded,
                ),
                const Divider(height: 24, color: Colors.grey),
                _buildMenuItem(
                  icon: scannerIcon,
                  iconColor: Colors.orange,
                  title: '扫描音乐',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: libraryMusicIcon,
                  iconColor: Colors.teal,
                  title: '音乐库',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: barChartIcon,
                  iconColor: Colors.indigo,
                  title: '统计',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: settingsIcon,
                  iconColor: Colors.grey,
                  title: '设置',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  icon: infoIcon,
                  iconColor: Colors.cyan,
                  title: '关于',
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
