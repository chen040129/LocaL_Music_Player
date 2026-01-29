
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({Key? key}) : super(key: key);

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(AppIcons.playlist, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '歌单',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 创建歌单按钮
                IconButton(
                  icon: Icon(
                    AppIcons.add,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  onPressed: () {
                    _createPlaylist();
                  },
                  tooltip: '创建歌单',
                ),
              ],
            ),
          ),
          // 歌单列表
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.playlist,
                    size: 64,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无歌单',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角的"+"按钮创建新歌单',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 创建歌单
  void _createPlaylist() {
    // TODO: 实现创建歌单功能
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String playlistName = '';
        return AlertDialog(
          title: const Text('创建新歌单'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入歌单名称',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              playlistName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (playlistName.isNotEmpty) {
                  // TODO: 保存歌单
                  Navigator.of(context).pop();
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
}
