import 'dart:io';
import 'package:window_manager/window_manager.dart';

class WindowCornerService {


  /// 设置窗口圆角半径
  /// 
  /// [radius] 圆角半径，单位为像素
  /// 仅在Windows平台上有效
  static Future<void> setWindowCornerRadius(int radius) async {
    if (Platform.isWindows) {
      try {
        // 使用window_manager插件设置窗口圆角
        // 注意：window_manager可能不直接支持圆角设置
        // 这里我们暂时不做任何操作，因为window_manager不支持直接设置窗口圆角
        // 如果需要设置窗口圆角，需要使用原生插件
      } catch (e) {
        print('Failed to set window corner radius: $e');
      }
    }
  }
}
