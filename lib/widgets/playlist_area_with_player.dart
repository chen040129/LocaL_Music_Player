
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../services/music_scanner_service.dart';

class PlaylistAreaWithPlayer extends StatelessWidget {
  final bool isSidebarExpanded;

  const PlaylistAreaWithPlayer({
    Key? key,
    required this.isSidebarExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final playlist = playerProvider.playlist;
        final currentIndex = playerProvider.currentIndex;
        final playMode = playerProvider.playMode;

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
                    Icon(
                      _getPlayModeIcon(playMode),
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playerProvider.getPlayModeName(),
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (playlist.isNotEmpty)
                      Text(
                        '${playlist.length} 首歌曲',
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // 歌曲列表
              Expanded(
                child: playlist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.musicNote,
                              size: 64,
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '播放列表为空',
                              style: TextStyle(
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: playlist.length,
                        itemBuilder: (context, index) {
                          final music = playlist[index];
                          final isPlaying = index == currentIndex;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isPlaying ? 3 : 1,
                            color: isPlaying
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Theme.of(context).colorScheme.surface,
                            child: InkWell(
                              onTap: () {
                                playerProvider.playAtIndex(index);
                              },
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
                                        color: music.coverColor != null
                                            ? Color(music.coverColor!)
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: music.coverArt != null
                                            ? Image.memory(
                                                music.coverArt!,
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
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
                                            music.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                              color: isPlaying
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                music.artist,
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
                                                music.album,
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
                                    if (music.quality != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: music.quality == 'HR'
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          music.quality!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: music.quality == 'HR'
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
      },
    );
  }

  /// 根据播放模式获取图标
  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.play_circle_outline;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.loop:
        return Icons.repeat_one;
      case PlayMode.listLoop:
        return Icons.repeat;
    }
  }
}
