
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class LyricsSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const LyricsSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<LyricsSettingsPage> createState() => _LyricsSettingsPageState();
}

class _LyricsSettingsPageState extends State<LyricsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部工具栏
          _buildTopBar(context),
          // 设置内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基础设置
                  _buildSectionHeader('基础设置'),
                  const SizedBox(height: 16),
                  _buildBasicSettings(context),
                  const SizedBox(height: 24),

                  // 字体设置
                  _buildSectionHeader('字体设置'),
                  const SizedBox(height: 16),
                  _buildFontSettings(context),
                  const SizedBox(height: 24),

                  // 渐变效果设置
                  _buildSectionHeader('渐变效果'),
                  const SizedBox(height: 16),
                  _buildGradientSettings(context),
                  const SizedBox(height: 24),

                  // 动画设置
                  _buildSectionHeader('动画效果'),
                  const SizedBox(height: 16),
                  _buildAnimationSettings(context),
                  // 底部占位区域，确保内容滚动到底部时不被播放栏遮挡
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部工具栏
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: widget.onBack,
            tooltip: '返回',
          ),
          const SizedBox(width: 12),
          const Icon(
            CupertinoIcons.music_note,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '歌词设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建基础设置
  Widget _buildBasicSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 歌词对齐方式
                _buildAlignmentTile(
                  title: '歌词对齐',
                  subtitle: '选择歌词的对齐方式',
                  icon: CupertinoIcons.text_aligncenter,
                  value: settings.lyricsAlignment,
                  onChanged: (value) => settings.setLyricsAlignment(value),
                ),
                const Divider(height: 32),

                // 显示翻译开关
                _buildSwitchTile(
                  title: '显示翻译',
                  subtitle: '显示歌词的翻译文本',
                  icon: CupertinoIcons.globe,
                  value: settings.showTranslation,
                  onChanged: (value) => settings.setShowTranslation(value),
                ),
                const Divider(height: 32),

                // 歌词行间距滑块
                _buildSliderTile(
                  title: '歌词行间距',
                  subtitle: '调整歌词行之间的间距',
                  icon: CupertinoIcons.line_horizontal_3,
                  value: settings.lyricsLineGap.toDouble(),
                  min: 4.0,
                  max: 20.0,
                  divisions: 16,
                  label: '${settings.lyricsLineGap}',
                  onChanged: (value) => settings.setLyricsLineGap(value.toInt()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建字体设置
  Widget _buildFontSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 歌词字体大小滑块
                _buildSliderTile(
                  title: '普通歌词字体大小',
                  subtitle: '调整普通歌词的字体大小',
                  icon: CupertinoIcons.textformat,
                  value: settings.lyricsFontSize,
                  min: 12.0,
                  max: 32.0,
                  divisions: 20,
                  label: '${settings.lyricsFontSize.toInt()}',
                  onChanged: (value) => settings.setLyricsFontSize(value),
                ),
                const Divider(height: 32),

                // 当前歌词字体大小滑块
                _buildSliderTile(
                  title: '当前歌词字体大小',
                  subtitle: '调整当前播放歌词的字体大小',
                  icon: CupertinoIcons.textformat_size,
                  value: settings.activeLyricsFontSize,
                  min: 16.0,
                  max: 36.0,
                  divisions: 20,
                  label: '${settings.activeLyricsFontSize.toInt()}',
                  onChanged: (value) => settings.setActiveLyricsFontSize(value),
                ),
                const Divider(height: 32),

                // 歌词效果类型
                _buildLyricsEffectTypeTile(
                  title: '歌词效果',
                  subtitle: '选择歌词的视觉效果',
                  icon: CupertinoIcons.photo,
                  value: settings.lyricsEffectType,
                  onChanged: (value) async => await settings.setLyricsEffectType(value),
                ),
                const Divider(height: 32),

                // 歌词不透明度滑块
                _buildSliderTile(
                  title: '歌词不透明度',
                  subtitle: '调整歌词的透明度',
                  icon: CupertinoIcons.eyeglasses,
                  value: settings.lyricsOpacity,
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  label: '${(settings.lyricsOpacity * 100).toInt()}%',
                  onChanged: (value) => settings.setLyricsOpacity(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建渐变效果设置
  Widget _buildGradientSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 启用歌词模糊开关
                _buildSwitchTile(
                  title: '启用歌词模糊',
                  subtitle: '在歌词上下区域添加模糊效果',
                  icon: CupertinoIcons.photo,
                  value: settings.enableLyricsBlur,
                  onChanged: (value) => settings.setEnableLyricsBlur(value),
                ),

                if (settings.enableLyricsBlur) ...[
                  const SizedBox(height: 16),
                  _buildSliderTile(
                    title: '顶部渐变范围',
                    subtitle: '调整歌词顶部渐变效果的范围',
                    icon: CupertinoIcons.arrow_up,
                    value: settings.fadeRangeTop,
                    min: 50.0,
                    max: 500.0,
                    divisions: 45,
                    label: '${settings.fadeRangeTop.round()}',
                    onChanged: (value) => settings.setFadeRangeTop(value),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderTile(
                    title: '底部渐变范围',
                    subtitle: '调整歌词底部渐变效果的范围',
                    icon: CupertinoIcons.arrow_down,
                    value: settings.fadeRangeBottom,
                    min: 50.0,
                    max: 500.0,
                    divisions: 45,
                    label: '${settings.fadeRangeBottom.round()}',
                    onChanged: (value) => settings.setFadeRangeBottom(value),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderTile(
                    title: '渐变不透明度',
                    subtitle: '调整渐变效果的不透明度',
                    icon: CupertinoIcons.photo,
                    value: settings.fadeOpacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    label: '${(settings.fadeOpacity * 100).round()}%',
                    onChanged: (value) => settings.setFadeOpacity(value),
                  ),
                  const SizedBox(height: 16),
                  _buildAlignmentTile(
                    title: '渐变方向',
                    subtitle: '选择渐变效果的方向',
                    icon: CupertinoIcons.arrow_up,
                    value: settings.fadeDirection == 0 
                        ? LyricsAlignment.left 
                        : settings.fadeDirection == 1 
                            ? LyricsAlignment.center 
                            : LyricsAlignment.right,
                    onChanged: (value) {
                      final direction = value == LyricsAlignment.left 
                          ? 0 
                          : value == LyricsAlignment.center 
                              ? 1 
                              : 2;
                      settings.setFadeDirection(direction);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSegmentTile(
                    title: '混合模式',
                    subtitle: '选择渐变效果的混合模式',
                    icon: CupertinoIcons.color_filter,
                    value: settings.blendModeIndex,
                    options: const [
                      'DstIn', 'DstOut', 'SrcIn', 'SrcOut', 'SrcATop', 'DstATop',
                      'Xor', 'Plus', 'Modulate', 'Screen', 'Overlay',
                      'Darken', 'Lighten', 'ColorDodge', 'ColorBurn',
                      'HardLight', 'SoftLight', 'Difference', 'Exclusion',
                      'Multiply', 'Hue', 'Saturation', 'Color', 'Luminosity'
                    ],
                    onChanged: (index) => settings.setBlendModeIndex(index),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建动画设置
  Widget _buildAnimationSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 启用歌词选择效果开关
                _buildSwitchTile(
                  title: '启用歌词选择效果',
                  subtitle: '在歌词行选择时显示特殊效果',
                  icon: CupertinoIcons.pin,
                  value: settings.enableLyricsSelectionEffects,
                  onChanged: (value) => settings.setEnableLyricsSelectionEffects(value),
                ),
                const Divider(height: 32),

                // 滚动动画时长滑块
                _buildSliderTile(
                  title: '滚动动画时长',
                  subtitle: '调整歌词滚动的动画时长',
                  icon: CupertinoIcons.time,
                  value: settings.scrollDuration.toDouble(),
                  min: 100.0,
                  max: 2000.0,
                  divisions: 19,
                  label: '${settings.scrollDuration}ms',
                  onChanged: (value) => settings.setScrollDuration(value.toInt()),
                ),
                const Divider(height: 32),

                // 选中行自动恢复时长滑块
                _buildSliderTile(
                  title: '选中行恢复时长',
                  subtitle: '调整选中行自动恢复的动画时长',
                  icon: CupertinoIcons.time_solid,
                  value: settings.selectionAutoResumeDuration.toDouble(),
                  min: 100.0,
                  max: 2000.0,
                  divisions: 19,
                  label: '${settings.selectionAutoResumeDuration}ms',
                  onChanged: (value) => settings.setSelectionAutoResumeDuration(value.toInt()),
                ),
                const Divider(height: 32),

                // 播放行自动恢复时长滑块
                _buildSliderTile(
                  title: '播放行恢复时长',
                  subtitle: '调整播放行自动恢复的动画时长',
                  icon: CupertinoIcons.play_circle,
                  value: settings.activeAutoResumeDuration.toDouble(),
                  min: 1000.0,
                  max: 10000.0,
                  divisions: 18,
                  label: '${settings.activeAutoResumeDuration}ms',
                  onChanged: (value) => settings.setActiveAutoResumeDuration(value.toInt()),
                ),
                const Divider(height: 32),

                // 滚动动画曲线选择
                _buildCurveTile(
                  title: '滚动动画曲线',
                  subtitle: '选择滚动动画的缓动曲线',
                  icon: CupertinoIcons.graph_circle,
                  value: settings.scrollCurve,
                  onChanged: (value) => settings.setScrollCurve(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 构建滑块设置项
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 构建歌词效果类型选择项
  Widget _buildLyricsEffectTypeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required LyricsEffectType value,
    required ValueChanged<LyricsEffectType> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<LyricsEffectType>(
          segments: const [
            ButtonSegment(
              value: LyricsEffectType.shadow,
              label: Text('阴影'),
              icon: Icon(Icons.format_color_fill),
            ),
            ButtonSegment(
              value: LyricsEffectType.glow,
              label: Text('辉光'),
              icon: Icon(Icons.blur_on),
            ),
          ],
          selected: {value},
          onSelectionChanged: (Set<LyricsEffectType> newSelection) {
            onChanged(newSelection.first);
          },
        ),
      ],
    );
  }

  /// 构建对齐方式选择项
  Widget _buildAlignmentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required LyricsAlignment value,
    required ValueChanged<LyricsAlignment> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<LyricsAlignment>(
          segments: const [
            ButtonSegment(
              value: LyricsAlignment.left,
              label: Text('左对齐'),
              icon: Icon(Icons.format_align_left),
            ),
            ButtonSegment(
              value: LyricsAlignment.center,
              label: Text('居中'),
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(
              value: LyricsAlignment.right,
              label: Text('右对齐'),
              icon: Icon(Icons.format_align_right),
            ),
          ],
          selected: {value},
          onSelectionChanged: (Set<LyricsAlignment> newSelection) {
            onChanged(newSelection.first);
          },
        ),
      ],
    );
  }

  /// 构建分段选择项
  Widget _buildSegmentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required List<String> options,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(options.length, (index) {
              final isSelected = value == index;
              return Padding(
                padding: EdgeInsets.only(right: index < options.length - 1 ? 8 : 0),
                child: FilterChip(
                  label: Text(options[index]),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      onChanged(index);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 构建滚动曲线选择项
  Widget _buildCurveTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    // 曲线分类
    final curveCategories = {
      '基础曲线': [
        {'value': 'linear', 'label': '线性'},
        {'value': 'ease', 'label': '标准缓动'},
      ],
      '缓入曲线': [
        {'value': 'easeIn', 'label': '缓入'},
        {'value': 'easeInCubic', 'label': '三次缓入'},
        {'value': 'easeInQuart', 'label': '四次缓入'},
        {'value': 'easeInQuint', 'label': '五次缓入'},
        {'value': 'easeInSine', 'label': '正弦缓入'},
        {'value': 'easeInExpo', 'label': '指数缓入'},
        {'value': 'easeInCirc', 'label': '圆形缓入'},
        {'value': 'easeInBack', 'label': '回弹缓入'},
      ],
      '缓出曲线': [
        {'value': 'easeOut', 'label': '缓出'},
        {'value': 'easeOutCubic', 'label': '三次缓出'},
        {'value': 'easeOutQuart', 'label': '四次缓出'},
        {'value': 'easeOutQuint', 'label': '五次缓出'},
        {'value': 'easeOutSine', 'label': '正弦缓出'},
        {'value': 'easeOutExpo', 'label': '指数缓出'},
        {'value': 'easeOutCirc', 'label': '圆形缓出'},
        {'value': 'easeOutBack', 'label': '回弹缓出'},
      ],
      '缓入缓出曲线': [
        {'value': 'easeInOut', 'label': '缓入缓出'},
        {'value': 'easeInOutCubic', 'label': '三次缓入缓出'},
        {'value': 'easeInOutQuart', 'label': '四次缓入缓出'},
        {'value': 'easeInOutQuint', 'label': '五次缓入缓出'},
        {'value': 'easeInOutSine', 'label': '正弦缓入缓出'},
        {'value': 'easeInOutExpo', 'label': '指数缓入缓出'},
        {'value': 'easeInOutCirc', 'label': '圆形缓入缓出'},
        {'value': 'easeInOutBack', 'label': '回弹缓入缓出'},
      ],
      '特殊曲线': [
        {'value': 'fastOutSlowIn', 'label': '快出慢入'},
        {'value': 'slowMiddle', 'label': '中间慢'},
        {'value': 'elasticOut', 'label': '弹性缓出'},
        {'value': 'elasticIn', 'label': '弹性缓入'},
        {'value': 'elasticInOut', 'label': '弹性缓入缓出'},
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 添加曲线预览组件
        Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              // 导入曲线预览组件
              return _CurvePreviewWidget(
                curve: _getCurve(value),
                duration: settings.scrollDuration.toDouble() / 1000,
              );
            },
          ),
        ),

        ...curveCategories.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((option) {
                  final isSelected = value == option['value'];
                  return FilterChip(
                    label: Text(option['label'] as String),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        onChanged(option['value'] as String);
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  // 根据字符串获取对应的Curve对象
  Curve _getCurve(String curveName) {
    switch (curveName) {
      case 'linear':
        return Curves.linear;
      case 'ease':
        return Curves.ease;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeInCubic':
        return Curves.easeInCubic;
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      case 'easeInOutCubic':
        return Curves.easeInOutCubic;
      case 'easeInQuad':
        return Curves.easeInQuad;
      case 'easeOutQuad':
        return Curves.easeOutQuad;
      case 'easeInOutQuad':
        return Curves.easeInOutQuad;
      case 'easeInQuart':
        return Curves.easeInQuart;
      case 'easeOutQuart':
        return Curves.easeOutQuart;
      case 'easeInOutQuart':
        return Curves.easeInOutQuart;
      case 'easeInSine':
        return Curves.easeInSine;
      case 'easeOutSine':
        return Curves.easeOutSine;
      case 'easeInOutSine':
        return Curves.easeInOutSine;
      case 'easeInQuint':
        return Curves.easeInQuint;
      case 'easeOutQuint':
        return Curves.easeOutQuint;
      case 'easeInOutQuint':
        return Curves.easeInOutQuint;
      case 'easeInExpo':
        return Curves.easeInExpo;
      case 'easeOutExpo':
        return Curves.easeOutExpo;
      case 'easeInOutExpo':
        return Curves.easeInOutExpo;
      case 'easeInCirc':
        return Curves.easeInCirc;
      case 'easeOutCirc':
        return Curves.easeOutCirc;
      case 'easeInOutCirc':
        return Curves.easeInOutCirc;
      case 'easeInBack':
        return Curves.easeInBack;
      case 'easeOutBack':
        return Curves.easeOutBack;
      case 'easeInOutBack':
        return Curves.easeInOutBack;
      case 'fastOutSlowIn':
        return Curves.fastOutSlowIn;
      case 'slowMiddle':
        return Curves.slowMiddle;
      case 'elasticOut':
        return Curves.elasticOut;
      case 'elasticIn':
        return Curves.elasticIn;
      case 'elasticInOut':
        return Curves.elasticInOut;
      default:
        return Curves.easeInOutCubic;
    }
  }
}

// 曲线预览组件
class _CurvePreviewWidget extends StatefulWidget {
  final Curve curve;
  final double duration;

  const _CurvePreviewWidget({
    Key? key,
    required this.curve,
    required this.duration,
  }) : super(key: key);

  @override
  State<_CurvePreviewWidget> createState() => _CurvePreviewWidgetState();
}

class _CurvePreviewWidgetState extends State<_CurvePreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.duration * 1000).round()),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.repeat();
  }

  @override
  void didUpdateWidget(_CurvePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果动画时长改变，更新动画控制器
    if (oldWidget.duration != widget.duration) {
      _controller.duration = Duration(milliseconds: (widget.duration * 1000).round());
      if (_controller.isAnimating) {
        _controller.reset();
        _controller.repeat();
      }
    }

    // 如果曲线改变，更新动画曲线
    if (oldWidget.curve != widget.curve) {
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _CurvePreviewPainter(
            curve: widget.curve,
            duration: widget.duration,
            progress: _animation.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

// 曲线预览绘制器
class _CurvePreviewPainter extends CustomPainter {
  final Curve curve;
  final double duration;
  final double progress;

  _CurvePreviewPainter({
    required this.curve,
    required this.duration,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 绘制坐标轴
    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.5;

    // X轴
    canvas.drawLine(
      Offset(15, size.height - 15),
      Offset(size.width - 15, size.height - 15),
      axisPaint,
    );

    // Y轴
    canvas.drawLine(
      Offset(15, 15),
      Offset(15, size.height - 15),
      axisPaint,
    );

    // 绘制曲线
    final curvePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final curvePath = Path();
    final curveWidth = size.width - 30;
    final curveHeight = size.height - 30;

    // 绘制曲线
    for (double t = 0; t <= 1.0; t += 0.01) {
      final x = 15 + t * curveWidth;
      final y = size.height - 15 - curve.transform(t) * curveHeight;

      if (t == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }
    }

    canvas.drawPath(curvePath, curvePaint);

    // 绘制动画点
    final animationPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 确保动画点不会超出边界
    final adjustedProgress = progress.clamp(0.0, 0.99);  // 使用0.99而不是1.0，防止超出边界

    // 计算动画点位置，确保从左下角开始
    final startX = 15.0;  // X轴起点
    final startY = size.height - 15.0;  // Y轴起点

    // 计算当前点位置
    final pointX = startX + adjustedProgress * curveWidth;
    final pointY = startY - curve.transform(adjustedProgress) * curveHeight;

    // 绘制动画点
    canvas.drawCircle(Offset(pointX, pointY), 6.0, animationPaint);

    // 绘制动画点轨迹
    final trailPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // 绘制轨迹点
    for (double t = 0; t <= adjustedProgress; t += 0.02) {
      final trailX = startX + t * curveWidth;
      final trailY = startY - curve.transform(t) * curveHeight;
      final radius = 2.0 * (1.0 - t) + 1.0;
      canvas.drawCircle(Offset(trailX, trailY), radius, trailPaint);
    }

    // 添加动画时长标题
    final durationPainter = TextPainter(
      text: TextSpan(
        text: '动画时长: ${duration}秒',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    durationPainter.layout();
    durationPainter.paint(
      canvas,
      Offset(size.width / 2 - durationPainter.width / 2, 5),
    );
  }

  @override
  bool shouldRepaint(_CurvePreviewPainter oldDelegate) {
    return oldDelegate.curve != curve || 
           oldDelegate.duration != duration || 
           oldDelegate.progress != progress;
  }
}
