import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_music_player/common.dart';
import 'package:flutter_music_player/common_widgets/desktop_lyrics_widget.dart';
import 'package:flutter_music_player/desktop/extensions/window_controller_extension.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initDesktopLyrics() async {
  // 检查是否已经创建过桌面歌词窗口
  if (lyricsWindowController != null) {
    return;
  }

  lyricsWindowController = await WindowController.create(
    WindowConfiguration(hiddenAtLaunch: true, arguments: 'desktop_lyrics'),
  );
}

class DesktopLyrics extends StatefulWidget {
  const DesktopLyrics({super.key});

  @override
  State<DesktopLyrics> createState() => _DesktopLyricsState();
}

class _DesktopLyricsState extends State<DesktopLyrics> {
  final ValueNotifier<bool> _isTransparentNotifier = ValueNotifier(false);
  bool _isHoveringPrevious = false;
  bool _isHoveringNext = false;
  bool _isHoveringLock = false;
  bool _isHoveringPlay = false;
  bool _isHoveringClose = false;
  bool _isLocked = false;
  int _retryCount = 0;
  bool _isDisposed = false; // 添加标志来跟踪是否已销毁

  @override
  void initState() {
    super.initState();
    // 请求主窗口同步播放状态
    _requestPlayingState();
  }

  @override
  void dispose() {
    _isDisposed = true; // 设置标志，取消所有异步操作
    _isTransparentNotifier.dispose();
    super.dispose();
  }

  Future<void> _requestPlayingState() async {
    if (_isDisposed) return; // 如果已销毁，不再执行
    if (_retryCount >= 5) {
      return;
    }

    try {
      final controllers = await WindowController.getAll();
      if (_isDisposed) return; // 检查是否已销毁
      for (final controller in controllers) {
        if (controller.arguments.isEmpty) {
          await controller.invokeMethod('get_playing_state');
          if (_isDisposed) return; // 检查是否已销毁
          _retryCount = 0; // 重置重试计数
          break;
        }
      }
    } catch (e) {
      if (_isDisposed) return; // 检查是否已销毁
      _retryCount++;
      // 如果请求失败，延迟后重试
      if (_retryCount < 5) {
        await Future.delayed(const Duration(seconds: 1));
        _requestPlayingState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          Platform.isWindows ? ThemeData(fontFamily: 'Microsoft YaHei') : null,
      home: ValueListenableBuilder(
        valueListenable: _isTransparentNotifier,
        builder: (context, isTransparent, child) {
          bool isDragging = false;
          return Stack(
            children: [
              // 主内容区域
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: _isLocked
                    ? null
                    : (details) async {
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
                  child: Material(
                    color: (isTransparent || _isLocked)
                        ? Colors.transparent
                        : Colors.black45,
                    shape: SmoothRectangleBorder(
                      smoothness: 1,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // 锁定状态下的解锁按钮区域
                          if (_isLocked)
                            SizedBox(
                              height: 50,
                              child: MouseRegion(
                                onEnter: (_) {
                                  setState(() => _isHoveringLock = true);
                                },
                                onExit: (_) {
                                  setState(() => _isHoveringLock = false);
                                },
                                child: AnimatedOpacity(
                                  opacity: _isHoveringLock ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(5),
                                      child: InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _isLocked = false;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(5),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        child: AnimatedScale(
                                          scale: _isHoveringLock ? 1.1 : 1.0,
                                          duration:
                                              const Duration(milliseconds: 150),
                                          child: Icon(
                                            Icons.lock_open_rounded,
                                            color: Colors.grey.shade50,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 非锁定状态下的控制按钮
                          if (!_isLocked)
                            SizedBox(
                              height: 50,
                              child: isTransparent
                                  ? const SizedBox.shrink()
                                  : controlsRow(),
                            ),
                          Expanded(
                            child: Center(
                              child: DesktopLyricsWidget(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 窗口边缘的调整大小手柄
              if (!_isLocked)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      // 左边缘
                      _buildResizeEdge(ResizeEdge.left),
                      Expanded(child: Container()),
                      // 右边缘
                      _buildResizeEdge(ResizeEdge.right),
                    ],
                  ),
                ),
              if (!_isLocked)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      // 上边缘
                      _buildResizeEdge(ResizeEdge.top),
                      Expanded(child: Container()),
                      // 下边缘
                      _buildResizeEdge(ResizeEdge.bottom),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResizeEdge(ResizeEdge edge) {
    final isHorizontal = edge == ResizeEdge.left || edge == ResizeEdge.right;
    return MouseRegion(
      cursor: isHorizontal
          ? (edge == ResizeEdge.left
              ? SystemMouseCursors.resizeLeft
              : SystemMouseCursors.resizeRight)
          : (edge == ResizeEdge.top
              ? SystemMouseCursors.resizeUp
              : SystemMouseCursors.resizeDown),
      child: GestureDetector(
        onPanStart: (_) async {
          _isTransparentNotifier.value = false;
          await windowManager.startResizing(edge);
        },
        child: Container(
          width: isHorizontal ? 10 : double.infinity,
          height: isHorizontal ? double.infinity : 10,
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget controlsRow() {
    return Row(
      children: [
        Spacer(),
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringLock = true),
          onExit: (_) => setState(() => _isHoveringLock = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () async {
                setState(() {
                  _isLocked = !_isLocked;
                });
              },
              borderRadius: BorderRadius.circular(5),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedScale(
                  scale: _isHoveringLock ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: Colors.grey.shade50,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) => _isHoveringPrevious = true,
          onExit: (_) => _isHoveringPrevious = false,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () async {
                final controllers = await WindowController.getAll();
                for (final controller in controllers) {
                  if (controller.arguments.isEmpty) {
                    await controller.skipToPrevious();
                    break;
                  }
                }
              },
              borderRadius: BorderRadius.circular(5),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedScale(
                  scale: _isHoveringPrevious ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.backward_end_fill,
                    color: Colors.grey.shade50,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringPlay = true),
          onExit: (_) => setState(() => _isHoveringPlay = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () async {
                final controllers = await WindowController.getAll();
                for (final controller in controllers) {
                  if (controller.arguments.isEmpty) {
                    await controller.togglePlay();
                    break;
                  }
                }
              },
              borderRadius: BorderRadius.circular(5),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedScale(
                  scale: _isHoveringPlay ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: ValueListenableBuilder(
                    valueListenable: isPlayingNotifier,
                    builder: (_, isPlaying, __) {
                      return Icon(
                        isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: Colors.grey.shade50,
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) => _isHoveringNext = true,
          onExit: (_) => _isHoveringNext = false,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () async {
                final controllers = await WindowController.getAll();
                for (final controller in controllers) {
                  if (controller.arguments.isEmpty) {
                    await controller.skipToNext();
                    break;
                  }
                }
              },
              borderRadius: BorderRadius.circular(5),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedScale(
                  scale: _isHoveringNext ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.forward_end_fill,
                    color: Colors.grey.shade50,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringClose = true),
          onExit: (_) => setState(() => _isHoveringClose = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () async {
                final controllers = await WindowController.getAll();
                for (final controller in controllers) {
                  if (controller.arguments.isEmpty) {
                    controller.hideDesktopLyrics();
                  }
                }
                windowManager.hide();
              },
              borderRadius: BorderRadius.circular(5),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedScale(
                  scale: _isHoveringClose ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade50,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }
}
