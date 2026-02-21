import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';

class AlbumCoverWidget extends StatefulWidget {
  const AlbumCoverWidget({Key? key}) : super(key: key);

  @override
  State<AlbumCoverWidget> createState() => _AlbumCoverWidgetState();
}

class _AlbumCoverWidgetState extends State<AlbumCoverWidget> with TickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500), // 固定为0.5秒一转
      vsync: this,
    );
    if (settings.coverShape == CoverShape.circle && settings.circleCoverState == CircleCoverState.rotating) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AlbumCoverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // 更新旋转速度
    // 根据形状设置控制旋转
    if (settings.coverShape == CoverShape.circle && settings.circleCoverState == CircleCoverState.rotating && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if ((settings.coverShape != CoverShape.circle || settings.circleCoverState != CircleCoverState.rotating) && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, SettingsProvider>(
      builder: (context, playerProvider, settings, child) {
        final currentMusic = playerProvider.currentMusic;
        final size = settings.coverSize;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: settings.coverShape == CoverShape.square
                ? BorderRadius.circular(settings.coverBorderRadius)
                : BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: settings.coverShape == CoverShape.square
                ? BorderRadius.circular(settings.coverBorderRadius)
                : BorderRadius.circular(size / 2),
            child: currentMusic?.coverArt != null
                ? (settings.coverShape == CoverShape.circle && settings.circleCoverState == CircleCoverState.rotating
                    ? RotationTransition(
                        turns: _rotationController,
                        child: Image.memory(
                          currentMusic!.coverArt!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.memory(
                        currentMusic!.coverArt!,
                        fit: BoxFit.cover,
                      ))
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      AppIcons.musicNote,
                      size: size * 0.23,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
