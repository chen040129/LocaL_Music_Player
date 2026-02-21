
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

/// 播放栏样式枚举
enum PlayerBarStyle {
  normal,       // 默认样式
  liquidGlass,  // 液态玻璃样式
}

/// 播放栏长度枚举
enum PlayerBarLength {
  fullWidth,    // 全宽（占据整个窗口底部）
  contentWidth, // 内容宽度（不占据导航栏）
}

/// 歌词对齐方式枚举
enum LyricsAlignment {
  left,         // 左对齐
  center,       // 居中对齐
  right,        // 右对齐
}

/// 封面形状枚举
enum CoverShape {
  square,       // 方形
  circle,       // 圆形
}

/// 圆形封面状态枚举
enum CircleCoverState {
  static,       // 静态
  rotating,     // 旋转
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
  double _savedNormalWindowOpacity = 0.85;  // 保存默认背景类型的窗口透明度
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
  int _scrollDuration = 500;          // 滚动动画时长(毫秒)
  int _selectionAutoResumeDuration = 400;  // 选中行自动恢复时长(毫秒)
  int _activeAutoResumeDuration = 3500;    // 播放行自动恢复时长(毫秒)
  String _scrollCurve = 'easeInOutCubic';  // 滚动动画曲线

  // 播放器设置
  bool _autoPlayNext = true;           // 是否自动播放下一首
  bool _savePlayProgress = true;       // 是否保存播放进度
  bool _showPlayCount = true;          // 是否显示播放次数
  bool _enableFadeEffect = true;       // 是否启用淡入淡出效果
  double _fadeDuration = 2.0;          // 淡入淡出时长(秒)
  int _defaultVolume = 70;             // 默认音量(0-100)
  bool _showLyricsInPlayer = true;     // 播放器中是否显示歌词
  PlayerBarStyle _playerBarStyle = PlayerBarStyle.normal;  // 播放栏样式
  PlayerBarLength _playerBarLength = PlayerBarLength.fullWidth;  // 播放栏长度

  // 液态玻璃参数
  double _liquidGlassDistortion = 0.075;          // 扭曲强度
  double _liquidGlassDistortionWidth = 70.0;       // 扭曲宽度
  double _liquidGlassChromaticAberration = 0.002;  // 色差强度
  double _liquidGlassSaturation = 1.0;             // 饱和度
  double _liquidGlassBlurSigma = 0.5;              // 模糊强度
  double _liquidGlassMagnification = 1.0;           // 放大倍数

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
  
  // 封面设置
  CoverShape _coverShape = CoverShape.square;  // 封面形状
  CircleCoverState _circleCoverState = CircleCoverState.static;  // 圆形封面状态
  double _coverSize = 300.0;                  // 封面大小
  double _coverBorderRadius = 16.0;           // 封面方形时的圆角半径
  
  // 封面旋转速度（固定为0.5秒/圈）
  static const double coverRotationSpeed = 100;

  // 播放器设置
  bool get autoPlayNext => _autoPlayNext;
  bool get savePlayProgress => _savePlayProgress;
  bool get showPlayCount => _showPlayCount;
  bool get enableFadeEffect => _enableFadeEffect;
  double get fadeDuration => _fadeDuration;
  int get defaultVolume => _defaultVolume;
  bool get showLyricsInPlayer => _showLyricsInPlayer;
  PlayerBarStyle get playerBarStyle => _playerBarStyle;
  PlayerBarLength get playerBarLength => _playerBarLength;
  double get liquidGlassDistortion => _liquidGlassDistortion;
  double get liquidGlassDistortionWidth => _liquidGlassDistortionWidth;
  double get liquidGlassChromaticAberration => _liquidGlassChromaticAberration;
  double get liquidGlassSaturation => _liquidGlassSaturation;
  double get liquidGlassBlurSigma => _liquidGlassBlurSigma;
  double get liquidGlassMagnification => _liquidGlassMagnification;

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

  // 判断是否可以控制窗口透明度
  bool get canControlWindowOpacity => _playerBarStyle != PlayerBarStyle.liquidGlass;
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
  int get scrollDuration => _scrollDuration;
  int get selectionAutoResumeDuration => _selectionAutoResumeDuration;
  int get activeAutoResumeDuration => _activeAutoResumeDuration;
  String get scrollCurve => _scrollCurve;

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
  
  // 封面设置 getters
  CoverShape get coverShape => _coverShape;
  CircleCoverState get circleCoverState => _circleCoverState;
  double get coverSize => _coverSize;
  double get coverBorderRadius => _coverBorderRadius;

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
    _scrollDuration = prefs.getInt('scroll_duration') ?? 500;
    _selectionAutoResumeDuration = prefs.getInt('selection_auto_resume_duration') ?? 400;
    _activeAutoResumeDuration = prefs.getInt('active_auto_resume_duration') ?? 3500;
    _scrollCurve = prefs.getString('scroll_curve') ?? 'easeInOutCubic';

    // 加载播放器设置
    _autoPlayNext = prefs.getBool('auto_play_next') ?? true;
    _savePlayProgress = prefs.getBool('save_play_progress') ?? true;
    _showPlayCount = prefs.getBool('show_play_count') ?? true;
    _enableFadeEffect = prefs.getBool('enable_fade_effect') ?? true;
    _fadeDuration = prefs.getDouble('fade_duration') ?? 2.0;
    _defaultVolume = prefs.getInt('default_volume') ?? 70;
    _showLyricsInPlayer = prefs.getBool('show_lyrics_in_player') ?? true;
    final playerBarStyleIndex = prefs.getInt('player_bar_style') ?? 0;
    _playerBarStyle = PlayerBarStyle.values[playerBarStyleIndex];
    final playerBarLengthIndex = prefs.getInt('player_bar_length') ?? 0;
    _playerBarLength = PlayerBarLength.values[playerBarLengthIndex];
    // 加载液态玻璃参数
    _liquidGlassDistortion = prefs.getDouble('liquid_glass_distortion') ?? 0.075;
    if (_liquidGlassDistortion < 0.01) _liquidGlassDistortion = 0.075;

    _liquidGlassDistortionWidth = prefs.getDouble('liquid_glass_distortion_width') ?? 70.0;

    _liquidGlassChromaticAberration = prefs.getDouble('liquid_glass_chromatic_aberration') ?? 0.002;
    if (_liquidGlassChromaticAberration < 0.001) _liquidGlassChromaticAberration = 0.002;

    _liquidGlassSaturation = prefs.getDouble('liquid_glass_saturation') ?? 1.0;
    if (_liquidGlassSaturation < 0.1) _liquidGlassSaturation = 1.0;

    _liquidGlassBlurSigma = prefs.getDouble('liquid_glass_blur_sigma') ?? 0.5;
    if (_liquidGlassBlurSigma < 0.1) _liquidGlassBlurSigma = 0.5;

    _liquidGlassMagnification = prefs.getDouble('liquid_glass_magnification') ?? 1.0;

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
    
    // 加载封面设置
    final coverShapeIndex = prefs.getInt('cover_shape') ?? 0;
    _coverShape = CoverShape.values[coverShapeIndex];
    final circleCoverStateIndex = prefs.getInt('circle_cover_state') ?? 0;
    _circleCoverState = CircleCoverState.values[circleCoverStateIndex];
    _coverSize = prefs.getDouble('cover_size') ?? 300.0;
    _coverBorderRadius = prefs.getDouble('cover_border_radius') ?? 16.0;

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
    // 当从默认背景切换到流体背景时，保存当前透明度并设置为0
    if (_uiBackgroundType == UIBackgroundType.normal && value == UIBackgroundType.fluid) {
      _savedNormalWindowOpacity = _windowOpacity;
      _windowOpacity = 0.0;
      await _saveSetting('window_opacity', _windowOpacity);
    }
    // 当从流体背景切换回默认背景时，恢复之前保存的透明度
    else if (_uiBackgroundType == UIBackgroundType.fluid && value == UIBackgroundType.normal) {
      _windowOpacity = _savedNormalWindowOpacity;
      await _saveSetting('window_opacity', _windowOpacity);
    }
    
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

  Future<void> setScrollDuration(int value) async {
    _scrollDuration = value.clamp(100, 2000);
    await _saveSetting('scroll_duration', _scrollDuration);
    notifyListeners();
  }

  Future<void> setSelectionAutoResumeDuration(int value) async {
    _selectionAutoResumeDuration = value.clamp(100, 2000);
    await _saveSetting('selection_auto_resume_duration', _selectionAutoResumeDuration);
    notifyListeners();
  }

  Future<void> setActiveAutoResumeDuration(int value) async {
    _activeAutoResumeDuration = value.clamp(1000, 10000);
    await _saveSetting('active_auto_resume_duration', _activeAutoResumeDuration);
    notifyListeners();
  }

  Future<void> setScrollCurve(String value) async {
    _scrollCurve = value;
    await _saveSetting('scroll_curve', _scrollCurve);
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

  Future<void> setPlayerBarStyle(PlayerBarStyle value) async {
    // 当从默认样式切换到液态玻璃样式时，保存当前透明度并设置为1.0（完全不透明）
    if (_playerBarStyle == PlayerBarStyle.normal && value == PlayerBarStyle.liquidGlass) {
      _savedNormalWindowOpacity = _windowOpacity;
      _windowOpacity = 1.0;
      await _saveSetting('window_opacity', _windowOpacity);
    }
    // 当从液态玻璃样式切换回默认样式时，恢复之前保存的透明度
    else if (_playerBarStyle == PlayerBarStyle.liquidGlass && value == PlayerBarStyle.normal) {
      _windowOpacity = _savedNormalWindowOpacity;
      await _saveSetting('window_opacity', _windowOpacity);
    }

    _playerBarStyle = value;
    await _saveSetting('player_bar_style', value.index);
    notifyListeners();
  }

  Future<void> setPlayerBarLength(PlayerBarLength value) async {
    _playerBarLength = value;
    await _saveSetting('player_bar_length', value.index);
    notifyListeners();
  }

  // 液态玻璃参数 setters
  Future<void> setLiquidGlassDistortion(double value) async {
    _liquidGlassDistortion = value;
    await _saveSetting('liquid_glass_distortion', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassDistortionWidth(double value) async {
    _liquidGlassDistortionWidth = value;
    await _saveSetting('liquid_glass_distortion_width', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassChromaticAberration(double value) async {
    _liquidGlassChromaticAberration = value;
    await _saveSetting('liquid_glass_chromatic_aberration', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassSaturation(double value) async {
    _liquidGlassSaturation = value;
    await _saveSetting('liquid_glass_saturation', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassBlurSigma(double value) async {
    _liquidGlassBlurSigma = value;
    await _saveSetting('liquid_glass_blur_sigma', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassMagnification(double value) async {
    _liquidGlassMagnification = value;
    await _saveSetting('liquid_glass_magnification', value);
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
  
  // 封面设置 setters
  Future<void> setCoverShape(CoverShape value) async {
    _coverShape = value;
    await _saveSetting('cover_shape', _coverShape.index);
    notifyListeners();
  }
  
  Future<void> setCircleCoverState(CircleCoverState value) async {
    _circleCoverState = value;
    await _saveSetting('circle_cover_state', _circleCoverState.index);
    notifyListeners();
  }
  
  Future<void> setCoverSize(double value) async {
    _coverSize = value.clamp(200.0, 500.0);
    await _saveSetting('cover_size', _coverSize);
    notifyListeners();
  }
  

  
  Future<void> setCoverBorderRadius(double value) async {
    _coverBorderRadius = value.clamp(0.0, 50.0);
    await _saveSetting('cover_border_radius', _coverBorderRadius);
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
    await prefs.remove('scroll_duration');
    await prefs.remove('selection_auto_resume_duration');
    await prefs.remove('active_auto_resume_duration');
    await prefs.remove('scroll_curve');

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
    
    // 重置封面设置
    await prefs.remove('cover_shape');
    await prefs.remove('circle_cover_state');
    await prefs.remove('cover_size');
    await prefs.remove('cover_border_radius');

    // 重新加载设置
    await _loadSettings();
  }

  /// 导出设置为JSON字符串
  Future<String> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsMap = {};

    // 用户界面设置
    settingsMap['use_blur_background'] = prefs.getBool('use_blur_background') ?? true;
    settingsMap['show_album_art'] = prefs.getBool('show_album_art') ?? true;
    settingsMap['use_sidebar_glass'] = prefs.getBool('use_sidebar_glass') ?? true;
    settingsMap['use_player_glass'] = prefs.getBool('use_player_glass') ?? true;
    settingsMap['glass_opacity'] = prefs.getDouble('glass_opacity') ?? 0.2;
    settingsMap['border_radius'] = prefs.getDouble('border_radius') ?? 8.0;
    settingsMap['window_border_radius'] = prefs.getDouble('window_border_radius') ?? 12.0;
    settingsMap['window_opacity'] = prefs.getDouble('window_opacity') ?? 0.85;
    settingsMap['card_opacity'] = prefs.getDouble('card_opacity') ?? 0.85;
    settingsMap['ui_background_type'] = prefs.getInt('ui_background_type') ?? 0;
    settingsMap['ui_custom_image_path'] = prefs.getString('ui_custom_image_path') ?? '';
    settingsMap['ui_image_fit_type'] = prefs.getInt('ui_image_fit_type') ?? 0;
    settingsMap['sync_background_images'] = prefs.getBool('sync_background_images') ?? false;
    settingsMap['sync_gradient_settings'] = prefs.getBool('sync_gradient_settings') ?? false;
    settingsMap['ui_gradient_type'] = prefs.getInt('ui_gradient_type') ?? 0;
    settingsMap['ui_gradient_song_color_ratio'] = prefs.getDouble('ui_gradient_song_color_ratio') ?? 0.7;

    // 歌词设置
    settingsMap['lyrics_alignment'] = prefs.getInt('lyrics_alignment') ?? 1;
    settingsMap['lyrics_font_size'] = prefs.getDouble('lyrics_font_size') ?? 16.0;
    settingsMap['active_lyrics_font_size'] = prefs.getDouble('active_lyrics_font_size') ?? 22.0;
    settingsMap['show_translation'] = prefs.getBool('show_translation') ?? true;
    settingsMap['enable_lyrics_blur'] = prefs.getBool('enable_lyrics_blur') ?? true;
    settingsMap['lyrics_opacity'] = prefs.getDouble('lyrics_opacity') ?? 1.0;
    settingsMap['lyrics_line_gap'] = prefs.getInt('lyrics_line_gap') ?? 8;
    settingsMap['scroll_duration'] = prefs.getInt('scroll_duration') ?? 500;
    settingsMap['selection_auto_resume_duration'] = prefs.getInt('selection_auto_resume_duration') ?? 400;
    settingsMap['active_auto_resume_duration'] = prefs.getInt('active_auto_resume_duration') ?? 3500;
    settingsMap['scroll_curve'] = prefs.getString('scroll_curve') ?? 'easeInOutCubic';

    // 播放器设置
    settingsMap['auto_play_next'] = prefs.getBool('auto_play_next') ?? true;
    settingsMap['save_play_progress'] = prefs.getBool('save_play_progress') ?? true;
    settingsMap['show_play_count'] = prefs.getBool('show_play_count') ?? true;
    settingsMap['enable_fade_effect'] = prefs.getBool('enable_fade_effect') ?? true;
    settingsMap['fade_duration'] = prefs.getDouble('fade_duration') ?? 2.0;
    settingsMap['default_volume'] = prefs.getInt('default_volume') ?? 70;
    settingsMap['show_lyrics_in_player'] = prefs.getBool('show_lyrics_in_player') ?? true;
    settingsMap['player_bar_style'] = prefs.getInt('player_bar_style') ?? 0;
    settingsMap['player_bar_length'] = prefs.getInt('player_bar_length') ?? 0;

    // 液态玻璃参数
    settingsMap['liquid_glass_distortion'] = prefs.getDouble('liquid_glass_distortion') ?? 0.15;
    settingsMap['liquid_glass_distortion_width'] = prefs.getDouble('liquid_glass_distortion_width') ?? 40.0;
    settingsMap['liquid_glass_chromatic_aberration'] = prefs.getDouble('liquid_glass_chromatic_aberration') ?? 0.003;
    settingsMap['liquid_glass_saturation'] = prefs.getDouble('liquid_glass_saturation') ?? 1.0;
    settingsMap['liquid_glass_blur_sigma'] = prefs.getDouble('liquid_glass_blur_sigma') ?? 20.0;
    settingsMap['liquid_glass_magnification'] = prefs.getDouble('liquid_glass_magnification') ?? 1.0;

    // 歌曲页面设置
    settingsMap['song_page_background_type'] = prefs.getInt('song_page_background_type') ?? 0;
    settingsMap['gradient_type'] = prefs.getInt('gradient_type') ?? 0;
    settingsMap['is_fluid_dynamic'] = prefs.getBool('is_fluid_dynamic') ?? false;
    settingsMap['blur_amount'] = prefs.getDouble('blur_amount') ?? 30.0;
    settingsMap['page_opacity'] = prefs.getDouble('page_opacity') ?? 1.0;
    settingsMap['gradient_song_color_ratio'] = prefs.getDouble('gradient_song_color_ratio') ?? 0.7;
    settingsMap['custom_image_path'] = prefs.getString('custom_image_path') ?? '';
    settingsMap['image_fit_type'] = prefs.getInt('image_fit_type') ?? 1;

    // 流体背景参数
    settingsMap['fluid_bubbles_size'] = prefs.getDouble('fluid_bubbles_size') ?? 400.0;
    settingsMap['fluid_velocity'] = prefs.getDouble('fluid_velocity') ?? 120.0;
    settingsMap['fluid_animation_duration'] = prefs.getInt('fluid_animation_duration') ?? 2000;
    settingsMap['fluid_offset_amount'] = prefs.getDouble('fluid_offset_amount') ?? 20.0;
    settingsMap['fluid_layer_opacity'] = prefs.getDouble('fluid_layer_opacity') ?? 0.3;

    return jsonEncode(settingsMap);
  }

  /// 从JSON字符串导入设置
  Future<void> importSettings(String settingsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);

    // 导入所有设置项
    // 用户界面设置
    if (settingsMap.containsKey('use_blur_background')) {
      await prefs.setBool('use_blur_background', settingsMap['use_blur_background']);
    }
    if (settingsMap.containsKey('show_album_art')) {
      await prefs.setBool('show_album_art', settingsMap['show_album_art']);
    }
    if (settingsMap.containsKey('use_sidebar_glass')) {
      await prefs.setBool('use_sidebar_glass', settingsMap['use_sidebar_glass']);
    }
    if (settingsMap.containsKey('use_player_glass')) {
      await prefs.setBool('use_player_glass', settingsMap['use_player_glass']);
    }
    if (settingsMap.containsKey('glass_opacity')) {
      await prefs.setDouble('glass_opacity', settingsMap['glass_opacity']);
    }
    if (settingsMap.containsKey('border_radius')) {
      await prefs.setDouble('border_radius', settingsMap['border_radius']);
    }
    if (settingsMap.containsKey('window_border_radius')) {
      await prefs.setDouble('window_border_radius', settingsMap['window_border_radius']);
    }
    if (settingsMap.containsKey('window_opacity')) {
      await prefs.setDouble('window_opacity', settingsMap['window_opacity']);
    }
    if (settingsMap.containsKey('card_opacity')) {
      await prefs.setDouble('card_opacity', settingsMap['card_opacity']);
    }
    if (settingsMap.containsKey('ui_background_type')) {
      await prefs.setInt('ui_background_type', settingsMap['ui_background_type']);
    }
    if (settingsMap.containsKey('ui_custom_image_path')) {
      await prefs.setString('ui_custom_image_path', settingsMap['ui_custom_image_path']);
    }
    if (settingsMap.containsKey('ui_image_fit_type')) {
      await prefs.setInt('ui_image_fit_type', settingsMap['ui_image_fit_type']);
    }
    if (settingsMap.containsKey('sync_background_images')) {
      await prefs.setBool('sync_background_images', settingsMap['sync_background_images']);
    }
    if (settingsMap.containsKey('sync_gradient_settings')) {
      await prefs.setBool('sync_gradient_settings', settingsMap['sync_gradient_settings']);
    }
    if (settingsMap.containsKey('ui_gradient_type')) {
      await prefs.setInt('ui_gradient_type', settingsMap['ui_gradient_type']);
    }
    if (settingsMap.containsKey('ui_gradient_song_color_ratio')) {
      await prefs.setDouble('ui_gradient_song_color_ratio', settingsMap['ui_gradient_song_color_ratio']);
    }

    // 播放器设置
    if (settingsMap.containsKey('auto_play_next')) {
      await prefs.setBool('auto_play_next', settingsMap['auto_play_next']);
    }
    if (settingsMap.containsKey('save_play_progress')) {
      await prefs.setBool('save_play_progress', settingsMap['save_play_progress']);
    }
    if (settingsMap.containsKey('show_play_count')) {
      await prefs.setBool('show_play_count', settingsMap['show_play_count']);
    }
    if (settingsMap.containsKey('enable_fade_effect')) {
      await prefs.setBool('enable_fade_effect', settingsMap['enable_fade_effect']);
    }
    if (settingsMap.containsKey('fade_duration')) {
      await prefs.setDouble('fade_duration', settingsMap['fade_duration']);
    }
    if (settingsMap.containsKey('default_volume')) {
      await prefs.setInt('default_volume', settingsMap['default_volume']);
    }
    if (settingsMap.containsKey('show_lyrics_in_player')) {
      await prefs.setBool('show_lyrics_in_player', settingsMap['show_lyrics_in_player']);
    }
    if (settingsMap.containsKey('player_bar_style')) {
      await prefs.setInt('player_bar_style', settingsMap['player_bar_style']);
    }
    if (settingsMap.containsKey('player_bar_length')) {
      await prefs.setInt('player_bar_length', settingsMap['player_bar_length']);
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

    // 歌词设置
    if (settingsMap.containsKey('lyrics_alignment')) {
      await prefs.setInt('lyrics_alignment', settingsMap['lyrics_alignment']);
    }
    if (settingsMap.containsKey('lyrics_font_size')) {
      await prefs.setDouble('lyrics_font_size', settingsMap['lyrics_font_size']);
    }
    if (settingsMap.containsKey('active_lyrics_font_size')) {
      await prefs.setDouble('active_lyrics_font_size', settingsMap['active_lyrics_font_size']);
    }
    if (settingsMap.containsKey('show_translation')) {
      await prefs.setBool('show_translation', settingsMap['show_translation']);
    }
    if (settingsMap.containsKey('enable_lyrics_blur')) {
      await prefs.setBool('enable_lyrics_blur', settingsMap['enable_lyrics_blur']);
    }
    if (settingsMap.containsKey('lyrics_opacity')) {
      await prefs.setDouble('lyrics_opacity', settingsMap['lyrics_opacity']);
    }
    if (settingsMap.containsKey('lyrics_line_gap')) {
      await prefs.setInt('lyrics_line_gap', settingsMap['lyrics_line_gap']);
    }
    if (settingsMap.containsKey('scroll_duration')) {
      await prefs.setInt('scroll_duration', settingsMap['scroll_duration']);
    }
    if (settingsMap.containsKey('selection_auto_resume_duration')) {
      await prefs.setInt('selection_auto_resume_duration', settingsMap['selection_auto_resume_duration']);
    }
    if (settingsMap.containsKey('active_auto_resume_duration')) {
      await prefs.setInt('active_auto_resume_duration', settingsMap['active_auto_resume_duration']);
    }
    if (settingsMap.containsKey('scroll_curve')) {
      await prefs.setString('scroll_curve', settingsMap['scroll_curve']);
    }

    // 液态玻璃参数
    if (settingsMap.containsKey('liquid_glass_distortion')) {
      await prefs.setDouble('liquid_glass_distortion', settingsMap['liquid_glass_distortion']);
    }
    if (settingsMap.containsKey('liquid_glass_distortion_width')) {
      await prefs.setDouble('liquid_glass_distortion_width', settingsMap['liquid_glass_distortion_width']);
    }
    if (settingsMap.containsKey('liquid_glass_chromatic_aberration')) {
      await prefs.setDouble('liquid_glass_chromatic_aberration', settingsMap['liquid_glass_chromatic_aberration']);
    }
    if (settingsMap.containsKey('liquid_glass_saturation')) {
      await prefs.setDouble('liquid_glass_saturation', settingsMap['liquid_glass_saturation']);
    }
    if (settingsMap.containsKey('liquid_glass_blur_sigma')) {
      await prefs.setDouble('liquid_glass_blur_sigma', settingsMap['liquid_glass_blur_sigma']);
    }
    if (settingsMap.containsKey('liquid_glass_magnification')) {
      await prefs.setDouble('liquid_glass_magnification', settingsMap['liquid_glass_magnification']);
    }

    // 歌曲页面设置
    if (settingsMap.containsKey('song_page_background_type')) {
      await prefs.setInt('song_page_background_type', settingsMap['song_page_background_type']);
    }
    if (settingsMap.containsKey('gradient_type')) {
      await prefs.setInt('gradient_type', settingsMap['gradient_type']);
    }
    if (settingsMap.containsKey('is_fluid_dynamic')) {
      await prefs.setBool('is_fluid_dynamic', settingsMap['is_fluid_dynamic']);
    }
    if (settingsMap.containsKey('blur_amount')) {
      await prefs.setDouble('blur_amount', settingsMap['blur_amount']);
    }
    if (settingsMap.containsKey('page_opacity')) {
      await prefs.setDouble('page_opacity', settingsMap['page_opacity']);
    }
    if (settingsMap.containsKey('gradient_song_color_ratio')) {
      await prefs.setDouble('gradient_song_color_ratio', settingsMap['gradient_song_color_ratio']);
    }
    if (settingsMap.containsKey('custom_image_path')) {
      await prefs.setString('custom_image_path', settingsMap['custom_image_path']);
    }
    if (settingsMap.containsKey('image_fit_type')) {
      await prefs.setInt('image_fit_type', settingsMap['image_fit_type']);
    }

    // 流体背景参数
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

    // 重新加载设置
    await _loadSettings();
  }
}
