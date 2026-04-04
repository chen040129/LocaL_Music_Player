import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import 'package:flutter_music_player/common.dart';
import 'package:flutter_music_player/common_widgets/desktop_lyrics_widget.dart';
import 'package:flutter_music_player/desktop/extensions/window_controller_extension.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:window_manager/window_manager.dart';

class DesktopLyrics extends StatelessWidget {
  final ValueNotifier<bool> _isTransparentNotifier = ValueNotifier(false);

  DesktopLyrics({super.key});

  @override
  Widget build(BuildContext context) {
    print('[Desktop Lyrics] DesktopLyrics build called');
    print('[Desktop Lyrics] _isTransparentNotifier value: ${_isTransparentNotifier.value}');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Platform.isWindows
          ? ThemeData(fontFamily: 'Microsoft YaHei')
          : null,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            print('[Desktop Lyrics] Scaffold body builder called');
            return ValueListenableBuilder(
              valueListenable: _isTransparentNotifier,
              builder: (context, isTransparent, child) {
                print('[Desktop Lyrics] ValueListenableBuilder called with isTransparent: $isTransparent');
                bool isDragging = false;
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) async {
                    isDragging = true;
                    await windowManager.startDragging();
                    isDragging = false;
                  },
                  child: MouseRegion(
                    onEnter: (_) {
                      _isTransparentNotifier.value = false;
                    },
                    onExit: (_) {
                      if (isDragging) {
                        return;
                      }
                      _isTransparentNotifier.value = true;
                    },
                    child: Builder(
                      builder: (context) {
                        final bgColor = isTransparent ? Colors.transparent : Colors.black45;
                        print('[Desktop Lyrics] Material color: $bgColor, isTransparent: $isTransparent');
                        return Material(
                          color: bgColor,
                          elevation: 0,
                      shape: SmoothRectangleBorder(
                        smoothness: 1,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                              child: isTransparent ? null : controlsRow(),
                            ),
                            DesktopLyricsWidget(),
                            Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }

  Widget controlsRow() {
    return Row(
      children: [
        Spacer(),
        IconButton(
          color: Colors.grey.shade50,
          onPressed: () async {
            await windowManager.setIgnoreMouseEvents(true);
          },
          icon: Icon(Icons.lock_rounded, size: 20),
        ),
        IconButton(
          color: Colors.grey.shade50,
          icon: const Icon(Icons.skip_previous, size: 25),
          onPressed: () async {
            final controllers = await WindowController.getAll();
            for (final controller in controllers) {
              if (controller.arguments.isEmpty) {
                controller.skipToPrevious();
              }
            }
          },
        ),
        IconButton(
          color: Colors.grey.shade50,
          icon: ValueListenableBuilder(
            valueListenable: isPlayingNotifier,
            builder: (_, isPlaying, __) {
              return Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 30,
              );
            },
          ),
          onPressed: () async {
            final controllers = await WindowController.getAll();
            for (final controller in controllers) {
              if (controller.arguments.isEmpty) {
                controller.togglePlay();
              }
            }
          },
        ),
        IconButton(
          color: Colors.grey.shade50,
          icon: const Icon(Icons.skip_next, size: 25),
          onPressed: () async {
            final controllers = await WindowController.getAll();
            for (final controller in controllers) {
              if (controller.arguments.isEmpty) {
                controller.skipToNext();
              }
            }
          },
        ),
        IconButton(
          color: Colors.grey.shade50,
          onPressed: () async {
            final controllers = await WindowController.getAll();
            for (final controller in controllers) {
              if (controller.arguments.isEmpty) {
                controller.hideDesktopLyrics();
              }
            }
            windowManager.hide();
          },
          icon: Icon(Icons.close),
        ),
        Spacer(),
      ],
    );
  }
}
