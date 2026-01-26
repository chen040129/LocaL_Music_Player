
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_icons.dart';

class PlayerControlBar extends StatelessWidget {

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
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Icon(
                AppIcons.musicNote,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // 播放控制按钮
          Row(
            children: [
              IconButton(
                icon: const Icon(AppIcons.skipPrevious),
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                onPressed: () {},
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? AppIcons.pause : AppIcons.playArrow,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: onPlayPauseToggle,
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.skipNext),
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(width: 16),
          // 播放列表按钮
          IconButton(
            icon: const Icon(AppIcons.playlist),
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
