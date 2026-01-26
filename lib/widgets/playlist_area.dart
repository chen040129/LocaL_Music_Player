
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_icons.dart';

class PlaylistArea extends StatelessWidget {

  final bool isSidebarExpanded;
  final int currentPlayingIndex;
  final Function(int) onSongTap;

  const PlaylistArea({
    Key? key,
    required this.isSidebarExpanded,
    required this.currentPlayingIndex,
    required this.onSongTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 空的歌曲列表
    final List<Map<String, dynamic>> songs = [];

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部播放控制相关功能
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
                Icon(AppIcons.repeat, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '循环播放',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // 歌曲列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isPlaying = index == currentPlayingIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isPlaying ? 3 : 1,
                  color: isPlaying 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                      : Theme.of(context).colorScheme.surface,
                  child: InkWell(
                    onTap: () => onSongTap(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 专辑封面
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(
                                AppIcons.musicNote,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 歌曲信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                    color: isPlaying 
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      song['artist'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      song['album'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 音质标识
                          if (song['quality'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: song['quality'] == 'HR' 
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song['quality'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: song['quality'] == 'HR' 
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          // 播放状态图标
                          Icon(
                            AppIcons.playCircle,
                            color: isPlaying 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.4),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
