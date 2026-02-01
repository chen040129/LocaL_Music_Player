
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../pages/lyrics_page_new.dart';
import 'playlist_popup.dart';

class PlayerControlBar extends StatelessWidget {
  const PlayerControlBar({
    Key? key,
  }) : super(key: key);

  void _showPlaylistPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(bottom: 80, right: 20),
          child: PlaylistPopup(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentMusic = playerProvider.currentMusic;
        final isPlaying = playerProvider.isPlaying;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LyricsPage()),
            );
          },
          child: Container(
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
                  child: currentMusic?.coverArt != null
                      ? Image.memory(
                          currentMusic!.coverArt!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              AppIcons.musicNote,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: 28,
                            );
                          },
                        )
                      : Icon(
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
                      currentMusic?.title ?? '未播放',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentMusic?.artist ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    onPressed: () => playerProvider.playPrevious(),
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
                      onPressed: () => playerProvider.togglePlayPause(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.skipNext),
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    onPressed: () => playerProvider.playNext(),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // 播放列表按钮
              IconButton(
                icon: const Icon(AppIcons.playlist),
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                onPressed: () => _showPlaylistPopup(context),
                tooltip: '播放列表',
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}
