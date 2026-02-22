import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../pages/lyrics_page_new.dart';
import 'playlist_popup.dart';
import 'liquid_glass_widget.dart';

class PlayerControlBar extends StatefulWidget {
  const PlayerControlBar({
    Key? key,
  }) : super(key: key);

  @override
  State<PlayerControlBar> createState() => _PlayerControlBarState();
}

class _PlayerControlBarState extends State<PlayerControlBar>
    with TickerProviderStateMixin {
  bool _isHoveringPrevious = false;
  bool _isHoveringPlay = false;
  bool _isHoveringNext = false;
  bool _isHoveringPlaylist = false;

  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _hoverScale = 1.2;
  static const double _normalScale = 1.0;

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

        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Material(
              color: Colors.transparent,
              elevation: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return Consumer<SettingsProvider>(
                          builder: (context, settings, child) {
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(0),
                              child: const LyricsPage(),
                            );
                          },
                        );
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: LiquidGlassWidget(
                  enabled: settings.usePlayerGlass,
                  borderRadius: settings.borderRadius,
                  opacity: settings.glassOpacity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(settings.borderRadius),
                    child: BackdropFilter(
                      filter: settings.usePlayerGlass
                          ? ImageFilter.blur(sigmaX: 30, sigmaY: 30)
                          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 12),
                        decoration: BoxDecoration(
                          color: settings.usePlayerGlass
                              ? Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(settings.glassOpacity)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(settings.borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
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
                                    borderRadius: BorderRadius.circular(
                                        settings.borderRadius),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        settings.borderRadius),
                                    child: currentMusic?.coverArt != null
                                        ? Image.memory(
                                            currentMusic!.coverArt!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                AppIcons.musicNote,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                                size: 28,
                                              );
                                            },
                                          )
                                        : Icon(
                                            AppIcons.musicNote,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentMusic?.artist ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
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
                                MouseRegion(
                                  onEnter: (_) => setState(
                                      () => _isHoveringPrevious = true),
                                  onExit: (_) => setState(
                                      () => _isHoveringPrevious = false),
                                  child: Consumer<SettingsProvider>(
                                    builder: (context, settings, child) {
                                      return Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                            settings.borderRadius),
                                        child: InkWell(
                                          onTap: () =>
                                              playerProvider.playPrevious(),
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: AnimatedScale(
                                              scale: _isHoveringPrevious
                                                  ? _hoverScale
                                                  : _normalScale,
                                              duration: _animationDuration,
                                              child: Icon(
                                                CupertinoIcons
                                                    .backward_end_fill,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // 播放/暂停
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _isHoveringPlay = true),
                                  onExit: (_) =>
                                      setState(() => _isHoveringPlay = false),
                                  child: Consumer<SettingsProvider>(
                                    builder: (context, settings, child) {
                                      return Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                            settings.borderRadius),
                                        child: InkWell(
                                          onTap: () {
                                            final wasPlaying =
                                                playerProvider.isPlaying;
                                            playerProvider.togglePlayPause();

                                            // 处理倒计时
                                            if (playerProvider.timerMinutes !=
                                                null) {
                                              if (wasPlaying) {
                                                // 暂停播放时，暂停倒计时
                                                playerProvider.pauseTimer();
                                              } else {
                                                // 恢复播放时，恢复倒计时
                                                playerProvider.resumeTimer();
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: AnimatedScale(
                                              scale: _isHoveringPlay
                                                  ? _hoverScale
                                                  : _normalScale,
                                              duration: _animationDuration,
                                              child: Icon(
                                                isPlaying
                                                    ? CupertinoIcons.pause_fill
                                                    : CupertinoIcons.play_fill,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // 下一曲
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _isHoveringNext = true),
                                  onExit: (_) =>
                                      setState(() => _isHoveringNext = false),
                                  child: Consumer<SettingsProvider>(
                                    builder: (context, settings, child) {
                                      return Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                            settings.borderRadius),
                                        child: InkWell(
                                          onTap: () =>
                                              playerProvider.playNext(),
                                          borderRadius: BorderRadius.circular(
                                              settings.borderRadius),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: AnimatedScale(
                                              scale: _isHoveringNext
                                                  ? _hoverScale
                                                  : _normalScale,
                                              duration: _animationDuration,
                                              child: Icon(
                                                CupertinoIcons.forward_end_fill,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // 播放列表按钮
                            MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _isHoveringPlaylist = true),
                              onExit: (_) =>
                                  setState(() => _isHoveringPlaylist = false),
                              child: Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                                  return Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                        settings.borderRadius),
                                    child: InkWell(
                                      onTap: () => _showPlaylistPopup(context),
                                      borderRadius: BorderRadius.circular(
                                          settings.borderRadius),
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: AnimatedScale(
                                          scale: _isHoveringPlaylist
                                              ? _hoverScale
                                              : _normalScale,
                                          duration: _animationDuration,
                                          child: Icon(
                                            AppIcons.playlist,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color
                                                ?.withOpacity(0.7),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
