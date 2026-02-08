import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放器栏快照过渡动画组件
/// 用于实现从主窗口到独立窗口的平滑过渡效果
class PlayerBarSnapshotTransition extends StatefulWidget {
  final Widget child;

  const PlayerBarSnapshotTransition({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PlayerBarSnapshotTransition> createState() => _PlayerBarSnapshotTransitionState();
}

class _PlayerBarSnapshotTransitionState extends State<PlayerBarSnapshotTransition>
    with SingleTickerProviderStateMixin {
  bool _showSnapshot = true;
  String? _snapshotImage;
  Rect? _snapshotRect;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _loadSnapshot();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotImage = prefs.getString('player_bar_snapshot');
    final snapshotX = prefs.getDouble('player_bar_snapshot_x');
    final snapshotY = prefs.getDouble('player_bar_snapshot_y');
    final snapshotWidth = prefs.getDouble('player_bar_snapshot_width');
    final snapshotHeight = prefs.getDouble('player_bar_snapshot_height');

    if (snapshotImage != null && 
        snapshotX != null && snapshotY != null &&
        snapshotWidth != null && snapshotHeight != null) {
      setState(() {
        _snapshotImage = snapshotImage;
        _snapshotRect = Rect.fromLTWH(
          snapshotX,
          snapshotY,
          snapshotWidth,
          snapshotHeight,
        );
      });

      // 开始动画
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _showSnapshot = false;
            });
          }
        });
      });

      // 清除快照数据
      await prefs.remove('player_bar_snapshot');
      await prefs.remove('player_bar_snapshot_x');
      await prefs.remove('player_bar_snapshot_y');
      await prefs.remove('player_bar_snapshot_width');
      await prefs.remove('player_bar_snapshot_height');
    } else {
      setState(() {
        _showSnapshot = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 真实内容
        Opacity(
          opacity: _showSnapshot ? 0.0 : 1.0,
          child: widget.child,
        ),
        // 快照动画
        if (_showSnapshot && _snapshotImage != null && _snapshotRect != null)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final imageBytes = base64Decode(_snapshotImage!);
              return Positioned(
                left: _snapshotRect!.left,
                top: _snapshotRect!.top,
                width: _snapshotRect!.width,
                height: _snapshotRect!.height,
                child: Opacity(
                  opacity: 1.0 - _animation.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12 * _animation.value),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
