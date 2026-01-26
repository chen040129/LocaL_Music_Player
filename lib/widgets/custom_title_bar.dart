import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../constants/app_icons.dart';

class CustomTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;
  final VoidCallback onAlwaysOnTop;
  final bool isAlwaysOnTop;

  const CustomTitleBar({
    Key? key,
    required this.title,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    required this.onAlwaysOnTop,
    this.isAlwaysOnTop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // 拖动区域
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                  windowManager.startDragging();
                }
              },
              child: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          // 窗口控制按钮
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isAlwaysOnTop ? AppIcons.pinFill : AppIcons.pin,
                  size: 16,
                  color: isAlwaysOnTop ? Colors.blue : null,
                ),
                onPressed: onAlwaysOnTop,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.minus, 
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: onMinimize,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.fullscreen, 
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: onMaximize,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.xmark, 
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
