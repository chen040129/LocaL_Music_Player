import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../pages/lyrics_page_new.dart';
import 'playlist_popup.dart';

class PlayerControlBarLiquidGlass extends StatefulWidget {
  const PlayerControlBarLiquidGlass({
    Key? key,
  }) : super(key: key);

  @override
  State<PlayerControlBarLiquidGlass> createState() =>
      _PlayerControlBarLiquidGlassState();
}

class _PlayerControlBarLiquidGlassState
    extends State<PlayerControlBarLiquidGlass> with TickerProviderStateMixin {
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
                                  BorderRadius.circular(settings.borderRadius),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius:
                          BorderRadius.circular(settings.borderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: settings.liquidGlassBlurSigma,
                          sigmaY: settings.liquidGlassBlurSigma,
                        ),
                        child: Container(
                          width: constraints.maxWidth,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(settings.borderRadius),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 48, vertical: 12),
                            child: Row(
                              children: [
                                // 专辑封面
                                Container(
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
                                ),
                                const SizedBox(width: 16),
                                // 歌曲信息
                                Expanded(
                                  child: Column(
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
                                      child: Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                          icon: AnimatedScale(
                                            scale: _isHoveringPrevious
                                                ? _hoverScale
                                                : _normalScale,
                                            duration: _animationDuration,
                                            child: Icon(
                                              CupertinoIcons.backward_fill,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          onPressed: () {
                                            playerProvider.playPrevious();
                                          },
                                          tooltip: '上一曲',
                                        ),
                                      ),
                                    ),
                                    // 播放/暂停
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                          () => _isHoveringPlay = true),
                                      onExit: (_) => setState(
                                          () => _isHoveringPlay = false),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                          icon: AnimatedScale(
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
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          onPressed: () {
                                            playerProvider.togglePlayPause();
                                          },
                                          tooltip: isPlaying ? '暂停' : '播放',
                                        ),
                                      ),
                                    ),
                                    // 下一曲
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                          () => _isHoveringNext = true),
                                      onExit: (_) => setState(
                                          () => _isHoveringNext = false),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                          icon: AnimatedScale(
                                            scale: _isHoveringNext
                                                ? _hoverScale
                                                : _normalScale,
                                            duration: _animationDuration,
                                            child: Icon(
                                              CupertinoIcons.forward_fill,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          onPressed: () {
                                            playerProvider.playNext();
                                          },
                                          tooltip: '下一曲',
                                        ),
                                      ),
                                    ),
                                    // 播放列表
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                          () => _isHoveringPlaylist = true),
                                      onExit: (_) => setState(
                                          () => _isHoveringPlaylist = false),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                          icon: AnimatedScale(
                                            scale: _isHoveringPlaylist
                                                ? _hoverScale
                                                : _normalScale,
                                            duration: _animationDuration,
                                            child: Icon(
                                              CupertinoIcons.list_bullet,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          onPressed: () {
                                            _showPlaylistPopup(context);
                                          },
                                          tooltip: '播放列表',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
