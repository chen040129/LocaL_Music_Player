import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_music_player/common.dart';
import 'package:smooth_corner/smooth_corner.dart';

Future<void> initDesktopLyricsFlutterLyric() async {
  // 检查是否已经创建过桌面歌词窗口
  if (lyricsWindowControllerFlutterLyric != null) {
    return;
  }

  lyricsWindowControllerFlutterLyric = await WindowController.create(
    WindowConfiguration(hiddenAtLaunch: true, arguments: 'desktop_lyrics_flutter_lyric'),
  );
}

class DesktopLyricsFlutterLyric extends StatefulWidget {
  const DesktopLyricsFlutterLyric({super.key});

  @override
  State<DesktopLyricsFlutterLyric> createState() => _DesktopLyricsFlutterLyricState();
}

class _DesktopLyricsFlutterLyricState extends State<DesktopLyricsFlutterLyric> {
  final ValueNotifier<bool> _isTransparentNotifier = ValueNotifier(false);
  bool _isHoveringPrevious = false;
  bool _isHoveringNext = false;
  bool _isHoveringLock = false;
  bool _isHoveringPlay = false;
  bool _isHoveringClose = false;
  bool _isLocked = false;
  int _retryCount = 0;
  bool _isDisposed = false;
  bool _isDragging = false;
  bool _lyricsLoaded = false;
  String? _fontFamily;
  String _fontPath = '';
  String _fontName = '';

  late LyricController _lyricController;

  @override
  void initState() {
    super.initState();
    _lyricController = LyricController();
    _loadCustomFont();
    // 初始化窗口管理器
    _initWindowManager();
    // 请求主窗口同步播放状态
    _requestPlayingState();
    // 监听歌词更新
    updateDesktopLyricsNotifier.addListener(_onLyricsUpdate);
    // 监听播放状态变化
    isPlayingNotifier.addListener(_onPlayingStateChange);
  }

  @override
  void dispose() {
    updateDesktopLyricsNotifier.removeListener(_onLyricsUpdate);
    isPlayingNotifier.removeListener(_onPlayingStateChange);
    _isDisposed = true;
    _isTransparentNotifier.dispose();
    _lyricController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontPath = prefs.getString('font_path') ?? '';
      final fontName = prefs.getString('font_name') ?? '';
      if (fontPath.isNotEmpty && fontName.isNotEmpty) {
        _fontPath = fontPath;
        _fontName = fontName;
        // 同步设置全局变量
        desktopLyricsFontPath = fontPath;
        desktopLyricsFontName = fontName;
        await _reloadFont(fontPath, fontName);
      }
    } catch (e) {
      print('桌面歌词加载自定义字体失败: $e');
    }
  }

  Future<void> _reloadFont(String fontPath, String fontName) async {
    try {
      final fontFile = File(fontPath);
      if (await fontFile.exists()) {
        final fontLoader = FontLoader(fontName);
        final fontData = await fontFile.readAsBytes();
        fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
        await fontLoader.load();
        if (mounted) {
          setState(() {
            _fontFamily = fontName;
          });
        }
      }
    } catch (e) {
      print('桌面歌词重新加载字体失败: $e');
    }
  }

  void _onLyricsUpdate() {
    if (_isDisposed) return;

    // 检测字体变化（通过全局变量，由update_font消息设置）
    if (desktopLyricsFontPath.isNotEmpty && desktopLyricsFontName.isNotEmpty
        && desktopLyricsFontPath != _fontPath) {
      _fontPath = desktopLyricsFontPath;
      _fontName = desktopLyricsFontName;
      _reloadFont(desktopLyricsFontPath, desktopLyricsFontName);
    } else if (desktopLyricsFontName.isEmpty && _fontFamily != null && _fontPath.isNotEmpty) {
      // 字体被清除（收到空字体消息），恢复默认
      _fontPath = '';
      _fontName = '';
      setState(() {
        _fontFamily = null;
      });
    }

    print('[Flutter Lyric] _onLyricsUpdate called');
    print('[Flutter Lyric] desktopLyricsFullLrc: ${desktopLyricsFullLrc != null ? "present (${desktopLyricsFullLrc!.length} chars)" : "null"}');
    print('[Flutter Lyric] desktopLyricLine: ${desktopLyricLine != null ? "present" : "null"}');
    print('[Flutter Lyric] desktopLyricsCurrentPosition: $desktopLyricsCurrentPosition');

    // 如果有完整的 LRC 歌词，使用它
    if (desktopLyricsFullLrc != null && desktopLyricsFullLrc!.isNotEmpty) {
      print('[Flutter Lyric] Loading lyrics: ${desktopLyricsFullLrc!.substring(0, min(100, desktopLyricsFullLrc!.length))}...');
      _lyricController.loadLyric(desktopLyricsFullLrc!);
      _lyricsLoaded = true;
    } else if (desktopLyricLine != null) {
      // 回退到单行模式
      final position = desktopLyricLine!.start;
      final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
      final hundredths = (position.inMilliseconds.remainder(1000) ~/ 10)
          .toString()
          .padLeft(2, '0');
      final lyricString = '[$minutes:$seconds.$hundredths]${desktopLyricLine!.text}';
      print('[Flutter Lyric] Using fallback single line: $lyricString');
      _lyricController.loadLyric(lyricString);
      _lyricsLoaded = true;
    } else {
      print('[Flutter Lyric] No lyrics available');
      _lyricsLoaded = false;
    }

    // 设置当前进度
    if (_lyricsLoaded) {
      _lyricController.setProgress(desktopLyricsCurrentPosition);
      print('[Flutter Lyric] Set progress to: $desktopLyricsCurrentPosition');
    }
  }

  void _onPlayingStateChange() {
    if (_isDisposed) return;
    print('[Flutter Lyric] Playing state changed: ${isPlayingNotifier.value}');
    setState(() {}); // 触发UI更新
  }

  Future<void> _initWindowManager() async {
    try {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(true);
      print('[Flutter Lyric] Window manager initialized');
    } catch (e) {
      print('[Flutter Lyric] Failed to initialize window manager: $e');
    }
  }

  Future<void> _requestPlayingState() async {
    if (_isDisposed) return;
    if (_retryCount >= 5) {
      return;
    }

    try {
      final controllers = await WindowController.getAll();
      if (_isDisposed) return;
      for (final controller in controllers) {
        if (controller.arguments.isEmpty) {
          await controller.invokeMethod('get_playing_state');
          if (_isDisposed) return;
          _retryCount = 0;
          break;
        }
      }
    } catch (e) {
      if (_isDisposed) return;
      _retryCount++;
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
          return Stack(
            children: [
              // 主内容区域
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: _isLocked
                    ? null
                    : (details) async {
                        _isDragging = true;
                        await windowManager.startDragging();
                        _isDragging = false;
                      },
                child: MouseRegion(
                  onEnter: (_) {
                    _isTransparentNotifier.value = false;
                  },
                  onExit: (_) {
                    if (!_isDragging) {
                      _isTransparentNotifier.value = true;
                    }
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
                              child: controlsRow(),
                            ),
                          Expanded(
                            child: Center(
                              child: _lyricsLoaded
                                  ? LyricView(
                                      controller: _lyricController,
                                      width: double.infinity,
                                      height: double.infinity,
                                      style: LyricStyles.default1.copyWith(
                                        textStyle: TextStyle(
                                          fontFamily: _fontFamily,
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        activeStyle: TextStyle(
                                          fontFamily: _fontFamily,
                                          color: Colors.blue,
                                          fontSize: 35,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '暂无歌词',
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        color: Colors.white54,
                                        fontSize: 20,
                                      ),
                                    ),
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
                      // 左侧调整大小
                      Container(
                        width: 5,
                        color: Colors.transparent,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeft,
                          child: GestureDetector(
                            onPanUpdate: (details) async {
                              await windowManager.startResizing(ResizeEdge.left);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            // 顶部调整大小
                            Container(
                              height: 5,
                              color: Colors.transparent,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUp,
                                child: GestureDetector(
                                  onPanUpdate: (details) async {
                                    await windowManager.startResizing(ResizeEdge.top);
                                  },
                                ),
                              ),
                            ),
                            // 中间区域
                            Expanded(child: Container(color: Colors.transparent)),
                            // 底部调整大小
                            Container(
                              height: 5,
                              color: Colors.transparent,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDown,
                                child: GestureDetector(
                                  onPanUpdate: (details) async {
                                    await windowManager.startResizing(ResizeEdge.bottom);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 右侧调整大小
                      Container(
                        width: 5,
                        color: Colors.transparent,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeRight,
                          child: GestureDetector(
                            onPanUpdate: (details) async {
                              await windowManager.startResizing(ResizeEdge.right);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget controlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一首按钮
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringPrevious = true),
          onExit: (_) => setState(() => _isHoveringPrevious = false),
          child: AnimatedOpacity(
            opacity: _isHoveringPrevious ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () async {
                  print('[Flutter Lyric] Previous button tapped');
                  final controllers = await WindowController.getAll();
                  for (final controller in controllers) {
                    if (controller.arguments.isEmpty) {
                      print('[Flutter Lyric] Sending skip_to_previous to main window');
                      await controller.invokeMethod('skip_to_previous');
                      break;
                    }
                  }
                },
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: AnimatedScale(
                  scale: _isHoveringPrevious ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.backward_end_fill,
                    color: Colors.grey.shade50,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 播放/暂停按钮
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringPlay = true),
          onExit: (_) => setState(() => _isHoveringPlay = false),
          child: AnimatedOpacity(
            opacity: _isHoveringPlay ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () async {
                  print('[Flutter Lyric] Play/Pause button tapped, current playing: ${isPlayingNotifier.value}');
                  final controllers = await WindowController.getAll();
                  for (final controller in controllers) {
                    if (controller.arguments.isEmpty) {
                      print('[Flutter Lyric] Sending toggle_play to main window');
                      await controller.invokeMethod('toggle_play');
                      break;
                    }
                  }
                },
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: AnimatedScale(
                  scale: _isHoveringPlay ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    isPlayingNotifier.value
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: Colors.grey.shade50,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 下一首按钮
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringNext = true),
          onExit: (_) => setState(() => _isHoveringNext = false),
          child: AnimatedOpacity(
            opacity: _isHoveringNext ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () async {
                  print('[Flutter Lyric] Next button tapped');
                  final controllers = await WindowController.getAll();
                  for (final controller in controllers) {
                    if (controller.arguments.isEmpty) {
                      print('[Flutter Lyric] Sending skip_to_next to main window');
                      await controller.invokeMethod('skip_to_next');
                      break;
                    }
                  }
                },
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: AnimatedScale(
                  scale: _isHoveringNext ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.forward_end_fill,
                    color: Colors.grey.shade50,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 锁定按钮
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringLock = true),
          onExit: (_) => setState(() => _isHoveringLock = false),
          child: AnimatedOpacity(
            opacity: _isHoveringLock ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () async {
                  setState(() {
                    _isLocked = true;
                  });
                },
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: AnimatedScale(
                  scale: _isHoveringLock ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    color: Colors.grey.shade50,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 关闭按钮
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringClose = true),
          onExit: (_) => setState(() => _isHoveringClose = false),
          child: AnimatedOpacity(
            opacity: _isHoveringClose ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () async {
                  // 通知主窗口关闭桌面歌词并更新状态
                  try {
                    final controllers = await WindowController.getAll();
                    for (final controller in controllers) {
                      if (controller.arguments.isEmpty) {
                        await controller.invokeMethod('close_desktop_lyrics');
                        break;
                      }
                    }
                  } catch (e) {
                    print('[Flutter Lyric] Failed to notify main window: $e');
                  }
                  await windowManager.close();
                },
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: AnimatedScale(
                  scale: _isHoveringClose ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    CupertinoIcons.clear,
                    color: Colors.grey.shade50,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
