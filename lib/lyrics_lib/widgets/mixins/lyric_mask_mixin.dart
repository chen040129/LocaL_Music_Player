import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

/// 负责歌词遮罩/渐变效果的 Mixin
mixin LyricMaskMixin<T extends StatefulWidget> on State<T> {
  LyricStyle get style;
  Size get lyricSize;

  /// 如果需要，包装遮罩效果
  Widget wrapMaskIfNeed(Widget child) {
    if (style.fadeRange == null) {
      return child;
    }

    // 获取设置
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final fadeDirection = settings.fadeDirection;
    final fadeOpacity = settings.fadeOpacity;
    final blendMode = settings.blendMode;

    var top = style.fadeRange!.top;
    var bottom = style.fadeRange!.bottom;
    if (top > 1) {
      top = top / lyricSize.height;
    }
    if (bottom > 1) {
      bottom = (bottom / lyricSize.height);
    }
    top = top.clamp(0, 1);
    bottom = bottom.clamp(0, 1);

    // 根据方向设置渐变起始和结束点
    Alignment beginAlignment;
    Alignment endAlignment;
    List<Color> colors;
    List<double> stops;

    switch (fadeDirection) {
      case 0: // 上下渐变
        beginAlignment = Alignment.topCenter;
        endAlignment = Alignment.bottomCenter;
        colors = [
          Colors.transparent, // 顶部渐隐
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.transparent, // 底部渐隐
        ];
        stops = [
          0.0, // 顶部开始透明
          top, // 渐变到完全显示
          1 - bottom, // 开始向底部渐隐
          1.0, // 底部完全透明
        ];
        break;
      case 1: // 左右渐变
        beginAlignment = Alignment.centerLeft;
        endAlignment = Alignment.centerRight;
        colors = [
          Colors.transparent, // 左侧渐隐
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.transparent, // 右侧渐隐
        ];
        stops = [
          0.0, // 左侧开始透明
          top, // 渐变到完全显示
          1 - bottom, // 开始向右侧渐隐
          1.0, // 右侧完全透明
        ];
        break;
      case 2: // 对角线渐变
        beginAlignment = Alignment.topLeft;
        endAlignment = Alignment.bottomRight;
        colors = [
          Colors.transparent, // 左上角渐隐
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.black.withOpacity(fadeOpacity), // 中间正常显示
          Colors.transparent, // 右下角渐隐
        ];
        stops = [
          0.0, // 左上角开始透明
          top, // 渐变到完全显示
          1 - bottom, // 开始向右下角渐隐
          1.0, // 右下角完全透明
        ];
        break;
      default:
        beginAlignment = Alignment.topCenter;
        endAlignment = Alignment.bottomCenter;
        colors = [
          Colors.transparent,
          Colors.black.withOpacity(fadeOpacity),
          Colors.black.withOpacity(fadeOpacity),
          Colors.transparent,
        ];
        stops = [0.0, top, 1 - bottom, 1.0];
    }

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: beginAlignment,
          end: endAlignment,
          colors: colors,
          stops: stops,
        ).createShader(bounds);
      },
      blendMode: blendMode,
      child: child,
    );
  }
}
