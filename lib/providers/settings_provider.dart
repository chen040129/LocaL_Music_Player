
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置类别枚举
enum SettingsCategory {
  ui,           // 用户界面
  lyrics,       // 歌词
  player,       // 播放器
}

/// 歌曲页面背景类型枚举
enum SongPageBackgroundType {
  transparent,  // 透明背景
  fluid,        // 流体背景
  blur,         // 模糊背景
  gradient,     // 渐变背景
  solid,        // 纯色背景
  customImage,  // 自定义图片背景
}

/// 图片布局方式枚举
enum ImageFitType {
  fill,         // 填充（拉伸）
  cover,        // 覆盖（保持比例）
  contain,      // 包含（保持比例）
  fitWidth,     // 适应宽度
  fitHeight,    // 适应高度
  none,         // 原始大小
}

/// 用户界面背景类型枚举
enum UIBackgroundType {
  normal,       // 默认背景
  fluid,        // 流体背景（当前播放歌曲）
  gradient,     // 渐变背景（当前播放歌曲）
  customImage,  // 自定义图片背景
}

/// 渐变类型枚举
enum GradientType {
  static,       // 静态渐变
  dynamic,      // 动态渐变
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
  double _cardOpacity = 0.85;           // 音乐卡片透明度
  UIBackgroundType _uiBackgroundType = UIBackgroundType.normal;  // 用户界面背景类型
  String _uiCustomImagePath = '';       // 用户界面自定义背景图片路径
  ImageFitType _uiImageFitType = ImageFitType.fill;  // 用户界面自定义背景图片布局方式
  bool _syncBackgroundImages = false;  // 是否同步用户界面和歌曲界面的背景图片
  bool _syncGradientSettings = false;  // 是否同步用户界面和歌曲界面的渐变设置
  GradientType _uiGradientType = GradientType.static;  // 用户界面渐变类型
  double _uiGradientSongColorRatio = 0.7;  // 用户界面渐变中歌曲主题色占比（0.0-1.0）

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

  // 歌曲页面设置
  SongPageBackgroundType _songPageBackgroundType = SongPageBackgroundType.fluid;  // 歌曲页面背景类型
  GradientType _gradientType = GradientType.static;  // 渐变类型
  bool _isFluidDynamic = false;        // 流体背景是否动态
  double _blurAmount = 30.0;          // 模糊程度
  double _pageOpacity = 1.0;          // 页面透明度
  double _gradientSongColorRatio = 0.7;  // 渐变中歌曲主题色占比（0.0-1.0）
  String _customImagePath = '';       // 自定义背景图片路径
  ImageFitType _imageFitType = ImageFitType.cover;  // 图片布局方式

  // 流体背景参数
  double _fluidBubblesSize = 400.0;          // 流体气泡大小
  double _fluidVelocity = 120.0;              // 流体速度
  int _fluidAnimationDuration = 2000;         // 流体动画持续时间（毫秒）
  double _fluidOffsetAmount = 20.0;           // 流体偏移量
  double _fluidLayerOpacity = 0.3;            // 流体层透明度

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
  double get cardOpacity => _cardOpacity;
  UIBackgroundType get uiBackgroundType => _uiBackgroundType;
  String get uiCustomImagePath => _uiCustomImagePath;
  ImageFitType get uiImageFitType => _uiImageFitType;
  bool get syncBackgroundImages => _syncBackgroundImages;
  bool get syncGradientSettings => _syncGradientSettings;
  GradientType get uiGradientType => _uiGradientType;
  double get uiGradientSongColorRatio => _uiGradientSongColorRatio;

  // 歌词设置 getters
  LyricsAlignment get lyricsAlignment => _lyricsAlignment;
  double get lyricsFontSize => _lyricsFontSize;
  double get activeLyricsFontSize => _activeLyricsFontSize;
  bool get showTranslation => _showTranslation;
  bool get enableLyricsBlur => _enableLyricsBlur;
  double get lyricsOpacity => _lyricsOpacity;
  int get lyricsLineGap => _lyricsLineGap;

  // 歌曲页面设置 getters
  SongPageBackgroundType get songPageBackgroundType => _songPageBackgroundType;
  GradientType get gradientType => _gradientType;
  bool get isFluidDynamic => _isFluidDynamic;
  double get blurAmount => _blurAmount;
  double get pageOpacity => _pageOpacity;
  double get gradientSongColorRatio => _gradientSongColorRatio;
  String get customImagePath => _customImagePath;
  ImageFitType get imageFitType => _imageFitType;

  // 流体背景参数 getters
  double get fluidBubblesSize => _fluidBubblesSize;
  double get fluidVelocity => _fluidVelocity;
  int get fluidAnimationDuration => _fluidAnimationDuration;
  double get fluidOffsetAmount => _fluidOffsetAmount;
  double get fluidLayerOpacity => _fluidLayerOpacity;

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
    _cardOpacity = prefs.getDouble('card_opacity') ?? 0.85;
    final uiBackgroundTypeIndex = prefs.getInt('ui_background_type') ?? 0;
    _uiBackgroundType = UIBackgroundType.values[uiBackgroundTypeIndex];
    _uiCustomImagePath = prefs.getString('ui_custom_image_path') ?? '';
    final uiImageFitTypeIndex = prefs.getInt('ui_image_fit_type') ?? 0;
    _uiImageFitType = ImageFitType.values[uiImageFitTypeIndex];
    _syncBackgroundImages = prefs.getBool('sync_background_images') ?? false;
    _syncGradientSettings = prefs.getBool('sync_gradient_settings') ?? false;
    final uiGradientTypeIndex = prefs.getInt('ui_gradient_type') ?? 0;
    _uiGradientType = GradientType.values[uiGradientTypeIndex];
    _uiGradientSongColorRatio = prefs.getDouble('ui_gradient_song_color_ratio') ?? 0.7;

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

    // 加载歌曲页面设置
    final backgroundTypeIndex = prefs.getInt('song_page_background_type') ?? 0;
    _songPageBackgroundType = SongPageBackgroundType.values[backgroundTypeIndex];
    final gradientTypeIndex = prefs.getInt('gradient_type') ?? 0;
    _gradientType = GradientType.values[gradientTypeIndex];
    _isFluidDynamic = prefs.getBool('is_fluid_dynamic') ?? false;
    _blurAmount = prefs.getDouble('blur_amount') ?? 30.0;
    _pageOpacity = prefs.getDouble('page_opacity') ?? 1.0;
    _gradientSongColorRatio = prefs.getDouble('gradient_song_color_ratio') ?? 0.7;
    _customImagePath = prefs.getString('custom_image_path') ?? '';
    final imageFitTypeIndex = prefs.getInt('image_fit_type') ?? 1;
    _imageFitType = ImageFitType.values[imageFitTypeIndex];

    // 加载流体背景参数
    _fluidBubblesSize = prefs.getDouble('fluid_bubbles_size') ?? 400.0;
    _fluidVelocity = prefs.getDouble('fluid_velocity') ?? 120.0;
    _fluidAnimationDuration = prefs.getInt('fluid_animation_duration') ?? 2000;
    _fluidOffsetAmount = prefs.getDouble('fluid_offset_amount') ?? 20.0;
    _fluidLayerOpacity = prefs.getDouble('fluid_layer_opacity') ?? 0.3;

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
    _glassOpacity = value.clamp(0.0, 1.0);
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
    _windowOpacity = value.clamp(0.0, 1.0);
    await _saveSetting('window_opacity', _windowOpacity);
    notifyListeners();
  }

  Future<void> setCardOpacity(double value) async {
    _cardOpacity = value.clamp(0.0, 1.0);
    await _saveSetting('card_opacity', _cardOpacity);
    notifyListeners();
  }

  Future<void> setUIBackgroundType(UIBackgroundType value) async {
    _uiBackgroundType = value;
    await _saveSetting('ui_background_type', _uiBackgroundType.index);
    notifyListeners();
  }

  Future<void> setUICustomImagePath(String value) async {
    _uiCustomImagePath = value;
    await _saveSetting('ui_custom_image_path', _uiCustomImagePath);
    // 如果启用了同步，同时更新歌曲界面的背景图片
    if (_syncBackgroundImages) {
      _customImagePath = value;
      await _saveSetting('custom_image_path', _customImagePath);
    }
    notifyListeners();
  }

  Future<void> setSyncBackgroundImages(bool value) async {
    _syncBackgroundImages = value;
    await _saveSetting('sync_background_images', _syncBackgroundImages);
    notifyListeners();
  }

  Future<void> setSyncGradientSettings(bool value) async {
    _syncGradientSettings = value;
    await _saveSetting('sync_gradient_settings', _syncGradientSettings);
    // 如果启用同步，将用户界面的渐变设置同步到歌曲页面
    if (value) {
      _gradientType = _uiGradientType;
      await _saveSetting('gradient_type', _gradientType.index);
      _gradientSongColorRatio = _uiGradientSongColorRatio;
      await _saveSetting('gradient_song_color_ratio', _gradientSongColorRatio);
    }
    notifyListeners();
  }

  Future<void> setUIImageFitType(ImageFitType value) async {
    _uiImageFitType = value;
    await _saveSetting('ui_image_fit_type', _uiImageFitType.index);
    notifyListeners();
  }

  Future<void> setUIGradientType(GradientType value) async {
    _uiGradientType = value;
    await _saveSetting('ui_gradient_type', _uiGradientType.index);
    // 如果启用了同步，同时更新歌曲页面的渐变类型
    if (_syncGradientSettings) {
      _gradientType = value;
      await _saveSetting('gradient_type', _gradientType.index);
    }
    notifyListeners();
  }

  Future<void> setUIGradientSongColorRatio(double value) async {
    _uiGradientSongColorRatio = value.clamp(0.0, 1.0);
    await _saveSetting('ui_gradient_song_color_ratio', _uiGradientSongColorRatio);
    // 如果启用了同步，同时更新歌曲页面的歌曲主题色占比
    if (_syncGradientSettings) {
      _gradientSongColorRatio = value;
      await _saveSetting('gradient_song_color_ratio', _gradientSongColorRatio);
    }
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

  // 歌曲页面设置 setters
  Future<void> setSongPageBackgroundType(SongPageBackgroundType value) async {
    _songPageBackgroundType = value;
    await _saveSetting('song_page_background_type', value.index);
    notifyListeners();
  }

  Future<void> setGradientType(GradientType value) async {
    _gradientType = value;
    await _saveSetting('gradient_type', value.index);
    // 如果启用了同步，同时更新用户界面的渐变类型
    if (_syncGradientSettings) {
      _uiGradientType = value;
      await _saveSetting('ui_gradient_type', _uiGradientType.index);
    }
    notifyListeners();
  }

  Future<void> setIsFluidDynamic(bool value) async {
    _isFluidDynamic = value;
    await _saveSetting('is_fluid_dynamic', value);
    notifyListeners();
  }

  Future<void> setBlurAmount(double value) async {
    _blurAmount = value.clamp(0.0, 50.0);
    await _saveSetting('blur_amount', _blurAmount);
    notifyListeners();
  }

  Future<void> setPageOpacity(double value) async {
    _pageOpacity = value.clamp(0.0, 1.0);
    await _saveSetting('page_opacity', _pageOpacity);
    notifyListeners();
  }

  Future<void> setGradientSongColorRatio(double value) async {
    _gradientSongColorRatio = value.clamp(0.0, 1.0);
    await _saveSetting('gradient_song_color_ratio', _gradientSongColorRatio);
    // 如果启用了同步，同时更新用户界面的歌曲主题色占比
    if (_syncGradientSettings) {
      _uiGradientSongColorRatio = value;
      await _saveSetting('ui_gradient_song_color_ratio', _uiGradientSongColorRatio);
    }
    notifyListeners();
  }

  Future<void> setCustomImagePath(String value) async {
    _customImagePath = value;
    await _saveSetting('custom_image_path', _customImagePath);
    // 如果启用了同步，同时更新用户界面的背景图片
    if (_syncBackgroundImages) {
      _uiCustomImagePath = value;
      await _saveSetting('ui_custom_image_path', _uiCustomImagePath);
    }
    notifyListeners();
  }

  Future<void> setImageFitType(ImageFitType value) async {
    _imageFitType = value;
    await _saveSetting('image_fit_type', _imageFitType.index);
    notifyListeners();
  }

  // 流体背景参数 setters
  Future<void> setFluidBubblesSize(double value) async {
    _fluidBubblesSize = value.clamp(100.0, 1000.0);
    await _saveSetting('fluid_bubbles_size', _fluidBubblesSize);
    notifyListeners();
  }

  Future<void> setFluidVelocity(double value) async {
    _fluidVelocity = value.clamp(0.0, 500.0);
    await _saveSetting('fluid_velocity', _fluidVelocity);
    notifyListeners();
  }

  Future<void> setFluidAnimationDuration(int value) async {
    _fluidAnimationDuration = value.clamp(500, 10000);
    await _saveSetting('fluid_animation_duration', _fluidAnimationDuration);
    notifyListeners();
  }

  Future<void> setFluidOffsetAmount(double value) async {
    _fluidOffsetAmount = value.clamp(0.0, 100.0);
    await _saveSetting('fluid_offset_amount', _fluidOffsetAmount);
    notifyListeners();
  }

  Future<void> setFluidLayerOpacity(double value) async {
    _fluidLayerOpacity = value.clamp(0.1, 1.0);
    await _saveSetting('fluid_layer_opacity', _fluidLayerOpacity);
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
    await prefs.remove('card_opacity');

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

    // 重置歌曲页面设置
    await prefs.remove('song_page_background_type');
    await prefs.remove('gradient_type');
    await prefs.remove('is_fluid_dynamic');
    await prefs.remove('blur_amount');
    await prefs.remove('page_opacity');
    await prefs.remove('gradient_song_color_ratio');

    // 重置流体背景参数
    await prefs.remove('fluid_bubbles_size');
    await prefs.remove('fluid_velocity');
    await prefs.remove('fluid_animation_duration');
    await prefs.remove('fluid_offset_amount');
    await prefs.remove('fluid_layer_opacity');

    // 重新加载设置
    await _loadSettings();
  }

  /// 导出设置为JSON字符串
  Future<String> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsMap = {};

    // 获取所有设置项
    settingsMap['ui_background_type'] = prefs.getInt('ui_background_type') ?? 0;
    settingsMap['ui_gradient_type'] = prefs.getInt('ui_gradient_type') ?? 0;
    settingsMap['ui_gradient_song_color_ratio'] = prefs.getDouble('ui_gradient_song_color_ratio') ?? 0.5;
    settingsMap['ui_custom_image_path'] = prefs.getString('ui_custom_image_path') ?? '';
    settingsMap['ui_image_fit_type'] = prefs.getInt('ui_image_fit_type') ?? 0;
    settingsMap['glass_opacity'] = prefs.getDouble('glass_opacity') ?? 0.7;
    settingsMap['card_opacity'] = prefs.getDouble('card_opacity') ?? 0.85;
    settingsMap['window_opacity'] = prefs.getDouble('window_opacity') ?? 0.85;
    settingsMap['window_border_radius'] = prefs.getDouble('window_border_radius') ?? 12.0;
    settingsMap['border_radius'] = prefs.getDouble('border_radius') ?? 8.0;

    settingsMap['song_page_background_type'] = prefs.getInt('song_page_background_type') ?? 0;
    settingsMap['page_opacity'] = prefs.getDouble('page_opacity') ?? 0.85;
    settingsMap['custom_image_path'] = prefs.getString('custom_image_path') ?? '';
    settingsMap['image_fit_type'] = prefs.getInt('image_fit_type') ?? 1;
    settingsMap['gradient_type'] = prefs.getInt('gradient_type') ?? 0;
    settingsMap['gradient_song_color_ratio'] = prefs.getDouble('gradient_song_color_ratio') ?? 0.5;
    settingsMap['blur_amount'] = prefs.getDouble('blur_amount') ?? 30.0;

    settingsMap['lyrics_alignment'] = prefs.getInt('lyrics_alignment') ?? 1;
    settingsMap['lyrics_font_size'] = prefs.getDouble('lyrics_font_size') ?? 24.0;
    settingsMap['active_lyrics_font_size'] = prefs.getDouble('active_lyrics_font_size') ?? 22.0;
    settingsMap['lyrics_line_height'] = prefs.getDouble('lyrics_line_height') ?? 1.5;
    settingsMap['lyrics_opacity'] = prefs.getDouble('lyrics_opacity') ?? 1.0;
    settingsMap['lyrics_line_gap'] = prefs.getInt('lyrics_line_gap') ?? 8;

    settingsMap['fluid_bubbles_size'] = prefs.getDouble('fluid_bubbles_size') ?? 150.0;
    settingsMap['fluid_velocity'] = prefs.getDouble('fluid_velocity') ?? 0.5;
    settingsMap['fluid_animation_duration'] = prefs.getInt('fluid_animation_duration') ?? 2000;
    settingsMap['fluid_offset_amount'] = prefs.getDouble('fluid_offset_amount') ?? 0.3;
    settingsMap['fluid_layer_opacity'] = prefs.getDouble('fluid_layer_opacity') ?? 0.7;

    settingsMap['fade_duration'] = prefs.getDouble('fade_duration') ?? 2.0;
    settingsMap['default_volume'] = prefs.getInt('default_volume') ?? 70;

    return jsonEncode(settingsMap);
  }

  /// 从JSON字符串导入设置
  Future<void> importSettings(String settingsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);

    // 导入所有设置项
    if (settingsMap.containsKey('ui_background_type')) {
      await prefs.setInt('ui_background_type', settingsMap['ui_background_type']);
    }
    if (settingsMap.containsKey('ui_gradient_type')) {
      await prefs.setInt('ui_gradient_type', settingsMap['ui_gradient_type']);
    }
    if (settingsMap.containsKey('ui_gradient_song_color_ratio')) {
      await prefs.setDouble('ui_gradient_song_color_ratio', settingsMap['ui_gradient_song_color_ratio']);
    }
    if (settingsMap.containsKey('ui_custom_image_path')) {
      await prefs.setString('ui_custom_image_path', settingsMap['ui_custom_image_path']);
    }
    if (settingsMap.containsKey('ui_image_fit_type')) {
      await prefs.setInt('ui_image_fit_type', settingsMap['ui_image_fit_type']);
    }
    if (settingsMap.containsKey('glass_opacity')) {
      await prefs.setDouble('glass_opacity', settingsMap['glass_opacity']);
    }
    if (settingsMap.containsKey('card_opacity')) {
      await prefs.setDouble('card_opacity', settingsMap['card_opacity']);
    }
    if (settingsMap.containsKey('window_opacity')) {
      await prefs.setDouble('window_opacity', settingsMap['window_opacity']);
    }
    if (settingsMap.containsKey('window_border_radius')) {
      await prefs.setDouble('window_border_radius', settingsMap['window_border_radius']);
    }
    if (settingsMap.containsKey('border_radius')) {
      await prefs.setDouble('border_radius', settingsMap['border_radius']);
    }

    if (settingsMap.containsKey('song_page_background_type')) {
      await prefs.setInt('song_page_background_type', settingsMap['song_page_background_type']);
    }
    if (settingsMap.containsKey('page_opacity')) {
      await prefs.setDouble('page_opacity', settingsMap['page_opacity']);
    }
    if (settingsMap.containsKey('custom_image_path')) {
      await prefs.setString('custom_image_path', settingsMap['custom_image_path']);
    }
    if (settingsMap.containsKey('image_fit_type')) {
      await prefs.setInt('image_fit_type', settingsMap['image_fit_type']);
    }
    if (settingsMap.containsKey('gradient_type')) {
      await prefs.setInt('gradient_type', settingsMap['gradient_type']);
    }
    if (settingsMap.containsKey('gradient_song_color_ratio')) {
      await prefs.setDouble('gradient_song_color_ratio', settingsMap['gradient_song_color_ratio']);
    }
    if (settingsMap.containsKey('blur_amount')) {
      await prefs.setDouble('blur_amount', settingsMap['blur_amount']);
    }

    if (settingsMap.containsKey('lyrics_alignment')) {
      await prefs.setInt('lyrics_alignment', settingsMap['lyrics_alignment']);
    }
    if (settingsMap.containsKey('lyrics_font_size')) {
      await prefs.setDouble('lyrics_font_size', settingsMap['lyrics_font_size']);
    }
    if (settingsMap.containsKey('active_lyrics_font_size')) {
      await prefs.setDouble('active_lyrics_font_size', settingsMap['active_lyrics_font_size']);
    }
    if (settingsMap.containsKey('lyrics_line_height')) {
      await prefs.setDouble('lyrics_line_height', settingsMap['lyrics_line_height']);
    }
    if (settingsMap.containsKey('lyrics_line_gap')) {
      await prefs.setInt('lyrics_line_gap', settingsMap['lyrics_line_gap']);
    }
    if (settingsMap.containsKey('lyrics_opacity')) {
      await prefs.setDouble('lyrics_opacity', settingsMap['lyrics_opacity']);
    }

    if (settingsMap.containsKey('fluid_bubbles_size')) {
      await prefs.setDouble('fluid_bubbles_size', settingsMap['fluid_bubbles_size']);
    }
    if (settingsMap.containsKey('fluid_velocity')) {
      await prefs.setDouble('fluid_velocity', settingsMap['fluid_velocity']);
    }
    if (settingsMap.containsKey('fluid_animation_duration')) {
      await prefs.setInt('fluid_animation_duration', settingsMap['fluid_animation_duration']);
    }
    if (settingsMap.containsKey('fluid_offset_amount')) {
      await prefs.setDouble('fluid_offset_amount', settingsMap['fluid_offset_amount']);
    }
    if (settingsMap.containsKey('fluid_layer_opacity')) {
      await prefs.setDouble('fluid_layer_opacity', settingsMap['fluid_layer_opacity']);
    }
    if (settingsMap.containsKey('fade_duration')) {
      await prefs.setDouble('fade_duration', settingsMap['fade_duration']);
    }
    if (settingsMap.containsKey('default_volume')) {
      await prefs.setInt('default_volume', settingsMap['default_volume']);
    }

    // 重新加载设置
    await _loadSettings();
  }
}
