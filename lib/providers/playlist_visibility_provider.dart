
import 'package:flutter/foundation.dart';

/// 播放列表可见性Provider
class PlaylistVisibilityProvider with ChangeNotifier {
  bool _isVisible = false;

  /// 播放列表是否可见
  bool get isVisible => _isVisible;

  /// 切换播放列表可见性
  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  /// 设置播放列表可见性
  void setVisible(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      notifyListeners();
    }
  }
}
