
import 'package:flutter/material.dart';

class PlaylistArea extends StatelessWidget {
  static const IconData repeatIcon = Icons.repeat;
  static const IconData musicNoteIcon = Icons.music_note;
  static const IconData playCircleFilledIcon = Icons.play_circle_filled;
  static const IconData playCircleOutlineIcon = Icons.play_circle_outline;

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
      color: Colors.grey[100],
      child: Column(
        children: [
          // 顶部播放控制相关功能
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                const Icon(repeatIcon, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  '循环播放',
                  style: TextStyle(
                    color: Colors.grey,
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
                  color: isPlaying ? Colors.blue[50] : Colors.white,
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
                              color: Colors.grey[300],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(
                                musicNoteIcon,
                                color: Colors.grey[600],
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
                                    color: isPlaying ? Colors.blue[700] : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      song['artist'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      song['album'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
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
                            isPlaying ? playCircleFilledIcon : playCircleOutlineIcon,
                            color: isPlaying ? Colors.blue : Colors.grey[400],
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
