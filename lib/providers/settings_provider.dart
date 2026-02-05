
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置类别枚举
enum SettingsCategory {
  ui,           // 用户界面
  lyrics,       // 歌词
  player,       // 播放器
}

/// 歌词对齐方式枚举
enum LyricsAlignment {
  left,         // 左对齐
  center,       // 居中对齐
  right,        // 右对齐
}

/// 设置提供者
class SettingsProvider with ChangeNotifier {
  // 用户界面设置
  bool _useBlurBackground = true;      // 是否使用模糊背景
  bool _showAlbumArt = true;           // 是否显示专辑封面
  bool _useSidebarGlass = true;         // 是否使用侧边栏玻璃材质
  bool _usePlayerGlass = true;         // 是否使用播放栏玻璃材质
  double _glassOpacity = 0.2;         // 玻璃材质透明度
  double _borderRadius = 8.0;          // 主页面边框弧度值
  double _windowBorderRadius = 12.0;   // 窗口边框弧度值
  double _windowOpacity = 0.85;        // 窗口背景透明度

  // 歌词设置
  LyricsAlignment _lyricsAlignment = LyricsAlignment.center;  // 歌词对齐方式
  double _lyricsFontSize = 16.0;       // 歌词字体大小
  double _activeLyricsFontSize = 22.0; // 当前歌词字体大小
  bool _showTranslation = true;        // 是否显示翻译
  bool _enableLyricsBlur = true;       // 是否启用歌词模糊
  double _lyricsOpacity = 1.0;         // 歌词不透明度
  int _lyricsLineGap = 8;              // 歌词行间距

  // 播放器设置
  bool _autoPlayNext = true;           // 是否自动播放下一首
  bool _savePlayProgress = true;       // 是否保存播放进度
  bool _showPlayCount = true;          // 是否显示播放次数
  bool _enableFadeEffect = true;       // 是否启用淡入淡出效果
  double _fadeDuration = 2.0;          // 淡入淡出时长(秒)
  int _defaultVolume = 70;             // 默认音量(0-100)
  bool _showLyricsInPlayer = true;     // 播放器中是否显示歌词

  // 播放器设置
  bool get autoPlayNext => _autoPlayNext;
  bool get savePlayProgress => _savePlayProgress;
  bool get showPlayCount => _showPlayCount;
  bool get enableFadeEffect => _enableFadeEffect;
  double get fadeDuration => _fadeDuration;
  int get defaultVolume => _defaultVolume;
  bool get showLyricsInPlayer => _showLyricsInPlayer;

  // 用户界面设置 getters
  bool get useBlurBackground => _useBlurBackground;
  bool get showAlbumArt => _showAlbumArt;
  bool get useSidebarGlass => _useSidebarGlass;
  bool get usePlayerGlass => _usePlayerGlass;
  double get glassOpacity => _glassOpacity;
  double get borderRadius => _borderRadius;
  double get windowBorderRadius => _windowBorderRadius;
  double get windowOpacity => _windowOpacity;

  // 歌词设置 getters
  LyricsAlignment get lyricsAlignment => _lyricsAlignment;
  double get lyricsFontSize => _lyricsFontSize;
  double get activeLyricsFontSize => _activeLyricsFontSize;
  bool get showTranslation => _showTranslation;
  bool get enableLyricsBlur => _enableLyricsBlur;
  double get lyricsOpacity => _lyricsOpacity;
  int get lyricsLineGap => _lyricsLineGap;

  SettingsProvider() {
    _loadSettings();
  }

  /// 从SharedPreferences加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载用户界面设置
    _useBlurBackground = prefs.getBool('use_blur_background') ?? true;
    _showAlbumArt = prefs.getBool('show_album_art') ?? true;
    _useSidebarGlass = prefs.getBool('use_sidebar_glass') ?? true;
    _usePlayerGlass = prefs.getBool('use_player_glass') ?? true;
    _glassOpacity = prefs.getDouble('glass_opacity') ?? 0.2;
    _borderRadius = prefs.getDouble('border_radius') ?? 8.0;
    _windowBorderRadius = prefs.getDouble('window_border_radius') ?? 12.0;
    _windowOpacity = prefs.getDouble('window_opacity') ?? 0.85;

    // 加载歌词设置
    final alignmentIndex = prefs.getInt('lyrics_alignment') ?? 1;
    _lyricsAlignment = LyricsAlignment.values[alignmentIndex];
    _lyricsFontSize = prefs.getDouble('lyrics_font_size') ?? 16.0;
    _activeLyricsFontSize = prefs.getDouble('active_lyrics_font_size') ?? 22.0;
    _showTranslation = prefs.getBool('show_translation') ?? true;
    _enableLyricsBlur = prefs.getBool('enable_lyrics_blur') ?? true;
    _lyricsOpacity = prefs.getDouble('lyrics_opacity') ?? 1.0;
    _lyricsLineGap = prefs.getInt('lyrics_line_gap') ?? 8;

    // 加载播放器设置
    _autoPlayNext = prefs.getBool('auto_play_next') ?? true;
    _savePlayProgress = prefs.getBool('save_play_progress') ?? true;
    _showPlayCount = prefs.getBool('show_play_count') ?? true;
    _enableFadeEffect = prefs.getBool('enable_fade_effect') ?? true;
    _fadeDuration = prefs.getDouble('fade_duration') ?? 2.0;
    _defaultVolume = prefs.getInt('default_volume') ?? 70;
    _showLyricsInPlayer = prefs.getBool('show_lyrics_in_player') ?? true;

    notifyListeners();
  }

  /// 保存设置到SharedPreferences
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // 用户界面设置 setters
  Future<void> setUseBlurBackground(bool value) async {
    _useBlurBackground = value;
    await _saveSetting('use_blur_background', value);
    notifyListeners();
  }

  Future<void> setShowAlbumArt(bool value) async {
    _showAlbumArt = value;
    await _saveSetting('show_album_art', value);
    notifyListeners();
  }

  Future<void> setUseSidebarGlass(bool value) async {
    _useSidebarGlass = value;
    await _saveSetting('use_sidebar_glass', value);
    notifyListeners();
  }

  Future<void> setUsePlayerGlass(bool value) async {
    _usePlayerGlass = value;
    await _saveSetting('use_player_glass', value);
    notifyListeners();
  }

  Future<void> setGlassOpacity(double value) async {
    _glassOpacity = value.clamp(0.0, 0.8);
    await _saveSetting('glass_opacity', _glassOpacity);
    notifyListeners();
  }

  Future<void> setBorderRadius(double value) async {
    _borderRadius = value.clamp(0.0, 20.0);
    await _saveSetting('border_radius', _borderRadius);
    notifyListeners();
  }

  Future<void> setWindowBorderRadius(double value) async {
    _windowBorderRadius = value.clamp(0.0, 30.0);
    await _saveSetting('window_border_radius', _windowBorderRadius);
    notifyListeners();
  }

  Future<void> setWindowOpacity(double value) async {
    _windowOpacity = value.clamp(0.3, 1.0);
    await _saveSetting('window_opacity', _windowOpacity);
    notifyListeners();
  }

  // 歌词设置 setters

  // 歌词设置 setters
  Future<void> setLyricsAlignment(LyricsAlignment value) async {
    _lyricsAlignment = value;
    await _saveSetting('lyrics_alignment', value.index);
    notifyListeners();
  }

  Future<void> setLyricsFontSize(double value) async {
    _lyricsFontSize = value.clamp(12.0, 24.0);
    await _saveSetting('lyrics_font_size', _lyricsFontSize);
    notifyListeners();
  }

  Future<void> setActiveLyricsFontSize(double value) async {
    _activeLyricsFontSize = value.clamp(16.0, 32.0);
    await _saveSetting('active_lyrics_font_size', _activeLyricsFontSize);
    notifyListeners();
  }

  Future<void> setShowTranslation(bool value) async {
    _showTranslation = value;
    await _saveSetting('show_translation', value);
    notifyListeners();
  }

  Future<void> setEnableLyricsBlur(bool value) async {
    _enableLyricsBlur = value;
    await _saveSetting('enable_lyrics_blur', value);
    notifyListeners();
  }

  Future<void> setLyricsOpacity(double value) async {
    _lyricsOpacity = value.clamp(0.3, 1.0);
    await _saveSetting('lyrics_opacity', _lyricsOpacity);
    notifyListeners();
  }

  Future<void> setLyricsLineGap(int value) async {
    _lyricsLineGap = value.clamp(4, 16);
    await _saveSetting('lyrics_line_gap', _lyricsLineGap);
    notifyListeners();
  }

  // 播放器设置 setters
  Future<void> setAutoPlayNext(bool value) async {
    _autoPlayNext = value;
    await _saveSetting('auto_play_next', value);
    notifyListeners();
  }

  Future<void> setSavePlayProgress(bool value) async {
    _savePlayProgress = value;
    await _saveSetting('save_play_progress', value);
    notifyListeners();
  }

  Future<void> setShowPlayCount(bool value) async {
    _showPlayCount = value;
    await _saveSetting('show_play_count', value);
    notifyListeners();
  }

  Future<void> setEnableFadeEffect(bool value) async {
    _enableFadeEffect = value;
    await _saveSetting('enable_fade_effect', value);
    notifyListeners();
  }

  Future<void> setFadeDuration(double value) async {
    _fadeDuration = value.clamp(0.5, 5.0);
    await _saveSetting('fade_duration', _fadeDuration);
    notifyListeners();
  }

  Future<void> setDefaultVolume(int value) async {
    _defaultVolume = value.clamp(0, 100);
    await _saveSetting('default_volume', _defaultVolume);
    notifyListeners();
  }

  Future<void> setShowLyricsInPlayer(bool value) async {
    _showLyricsInPlayer = value;
    await _saveSetting('show_lyrics_in_player', value);
    notifyListeners();
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // 重置用户界面设置
    await prefs.remove('use_blur_background');
    await prefs.remove('show_album_art');
    await prefs.remove('use_sidebar_glass');
    await prefs.remove('use_player_glass');
    await prefs.remove('glass_opacity');
    await prefs.remove('border_radius');
    await prefs.remove('window_border_radius');
    await prefs.remove('window_opacity');

    // 重置歌词设置
    await prefs.remove('lyrics_alignment');
    await prefs.remove('lyrics_font_size');
    await prefs.remove('active_lyrics_font_size');
    await prefs.remove('show_translation');
    await prefs.remove('enable_lyrics_blur');
    await prefs.remove('lyrics_opacity');
    await prefs.remove('lyrics_line_gap');

    // 重置播放器设置
    await prefs.remove('auto_play_next');
    await prefs.remove('save_play_progress');
    await prefs.remove('show_play_count');
    await prefs.remove('enable_fade_effect');
    await prefs.remove('fade_duration');
    await prefs.remove('default_volume');
    await prefs.remove('show_lyrics_in_player');

    // 重新加载设置
    await _loadSettings();
  }
}
