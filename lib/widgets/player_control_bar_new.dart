import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_provider.dart';
import '../pages/lyrics_page_new.dart';
import 'playlist_popup.dart';

class PlayerControlBarNew extends StatefulWidget {
  const PlayerControlBarNew({
    Key? key,
  }) : super(key: key);

  @override
  State<PlayerControlBarNew> createState() => _PlayerControlBarNewState();
}

class _PlayerControlBarNewState extends State<PlayerControlBarNew>
    with TickerProviderStateMixin {
  bool _isHoveringPrevious = false;
  bool _isHoveringPlay = false;
  bool _isHoveringNext = false;
  bool _isHoveringPlaylist = false;

  // LiquidGlass控制器
  final viewController = LiquidGlassViewController();
  final lensController = LiquidGlassController();

  // Start with realtime capturing ON
  final bool _realtime = true;

  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _hoverScale = 1.2;
  static const double _normalScale = 1.0;

  // 构建背景歌曲列表
  Widget _buildBackground() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final musicList = musicProvider.musicList;

        return Container(
          color: Colors.white,
          child: ListView.builder(
            itemCount: musicList.length,
            itemBuilder: (context, index) {
              final music = musicList[index];

              return ListTile(
                leading: music.coverArt != null
                    ? Image.memory(
                        music.coverArt!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            CupertinoIcons.music_note,
                            size: 56,
                          );
                        },
                      )
                    : const Icon(
                        CupertinoIcons.music_note,
                        size: 56,
                      ),
                title: Text(
                  music.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.artist,
                      style: TextStyle(
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      music.album,
                      style: TextStyle(
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
                              borderRadius: BorderRadius.circular(
                                  settings.windowBorderRadius),
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LiquidGlassView(
                        controller: viewController,
                        backgroundWidget: _buildBackground(),
                        pixelRatio: 1,
                        useSync: true,
                        realTimeCapture: _realtime,
                        refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
                        children: [
                          LiquidGlass(
                            controller: lensController,
                            position: const LiquidGlassAlignPosition(
                                alignment: Alignment.center),
                            width: 400,
                            height: 60,
                            magnification: 1,
                            enableInnerRadiusTransparent: false,
                            diagonalFlip: 0,
                            distortion: 0.1125,
                            distortionWidth: 50,
                            chromaticAberration: 0.002,
                            draggable: true,
                            outOfBoundaries: true,
                            blur: LiquidGlassBlur(sigmaX: 0.75, sigmaY: 0.75),
                            shape: RoundedRectangleShape(
                                cornerRadius: 30,
                                borderWidth: 1,
                                borderSoftness: 2.5,
                                lightIntensity: 1.5,
                                lightDirection: 39.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const SizedBox(
                                height: 60,
                                width: 400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
