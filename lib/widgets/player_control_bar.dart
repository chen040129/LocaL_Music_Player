
import 'package:flutter/material.dart';

class PlayerControlBar extends StatelessWidget {
  static const IconData skipPreviousIcon = Icons.skip_previous;
  static const IconData playArrowIcon = Icons.play_arrow;
  static const IconData pauseIcon = Icons.pause;
  static const IconData skipNextIcon = Icons.skip_next;
  static const IconData playlistPlayIcon = Icons.playlist_play;
  static const IconData musicNoteIcon = Icons.music_note;

  final bool isPlaying;
  final VoidCallback onPlayPauseToggle;

  const PlayerControlBar({
    Key? key,
    required this.isPlaying,
    required this.onPlayPauseToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 专辑封面
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Icon(
                musicNoteIcon,
                color: Colors.grey[600],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 歌曲信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 播放控制按钮
          Row(
            children: [
              IconButton(
                icon: const Icon(skipPreviousIcon),
                color: Colors.grey[700],
                onPressed: () {},
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? pauseIcon : playArrowIcon,
                    color: Colors.white,
                  ),
                  onPressed: onPlayPauseToggle,
                ),
              ),
              IconButton(
                icon: const Icon(skipNextIcon),
                color: Colors.grey[700],
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(width: 16),
          // 播放列表按钮
          IconButton(
            icon: const Icon(playlistPlayIcon),
            color: Colors.grey[700],
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
