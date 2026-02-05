
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
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

        return Material(
          elevation: 8,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LyricsPage()),
              );
            },
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
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
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(settings.borderRadius),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(settings.borderRadius),
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
                  );
                },
              ),
              const SizedBox(width: 16),
              // 歌曲信息
              Expanded(
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentMusic?.title ?? '未播放',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 显示播放次数（如果设置中启用）
                            if (settings.showPlayCount && currentMusic != null)
                              Text(
                                '  ${currentMusic!.playCount}次',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                          ],
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
                    );
                  },
                ),
              ),
              // 播放控制按钮
              Row(
                children: [
                  // 上一曲
                  InkWell(
                    onTap: () => playerProvider.playPrevious(),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Icon(
                      CupertinoIcons.backward_end_fill,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 播放/暂停
                  InkWell(
                    onTap: () {
                      final wasPlaying = playerProvider.isPlaying;
                      playerProvider.togglePlayPause();

                      // 处理倒计时
                      if (playerProvider.timerMinutes != null) {
                        if (wasPlaying) {
                          // 暂停播放时，暂停倒计时
                          playerProvider.pauseTimer();
                        } else {
                          // 恢复播放时，恢复倒计时
                          playerProvider.resumeTimer();
                        }
                      }
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Icon(
                      isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 下一曲
                  InkWell(
                    onTap: () => playerProvider.playNext(),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Icon(
                      CupertinoIcons.forward_end_fill,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 24,
                    ),
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
      ),
      );
      },
    );
  }
}
