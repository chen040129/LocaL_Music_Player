
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
                  _buildSectionHeader('歌词显示设置'),
                  const SizedBox(height: 16),
                  _buildLyricsSettings(context),
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

  /// 构建歌词设置
  Widget _buildLyricsSettings(BuildContext context) {
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

                // 歌词效果类型
                _buildLyricsEffectTypeTile(
                  title: '歌词效果',
                  subtitle: '选择歌词的视觉效果',
                  icon: CupertinoIcons.photo,
                  value: settings.lyricsEffectType,
                  onChanged: (value) async => await settings.setLyricsEffectType(value),
                ),
                const Divider(height: 32),

                // 歌词字体大小滑块
                _buildSliderTile(
                  title: '歌词字体大小',
                  subtitle: '调整普通歌词的字体大小',
                  icon: CupertinoIcons.textformat,
                  value: settings.lyricsFontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
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
                  max: 32.0,
                  divisions: 16,
                  label: '${settings.activeLyricsFontSize.toInt()}',
                  onChanged: (value) => settings.setActiveLyricsFontSize(value),
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

                // 启用歌词模糊开关
                _buildSwitchTile(
                  title: '启用歌词模糊',
                  subtitle: '在歌词上下区域添加模糊效果',
                  icon: CupertinoIcons.photo,
                  value: settings.enableLyricsBlur,
                  onChanged: (value) => settings.setEnableLyricsBlur(value),
                ),
                if (settings.enableLyricsBlur) ...
[
                  const SizedBox(height: 16),
                  // 使用自定义模糊效果开关
                  _buildSwitchTile(
                    title: '使用自定义模糊',
                    subtitle: '使用自定义高斯模糊效果（关闭则使用内置渐变效果）',
                    icon: CupertinoIcons.slider_horizontal_3,
                    value: settings.useCustomBlur,
                    onChanged: (value) => settings.setUseCustomBlur(value),
                  ),
                ],
                const Divider(height: 32),

                // 启用歌词选择效果开关
                _buildSwitchTile(
                  title: '启用歌词选择效果',
                  subtitle: '在歌词行选择时显示特殊效果',
                  icon: CupertinoIcons.pin,
                  value: settings.enableLyricsSelectionEffects,
                  onChanged: (value) => settings.setEnableLyricsSelectionEffects(value),
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
                const Divider(height: 32),

                // 歌词行间距滑块
                _buildSliderTile(
                  title: '歌词行间距',
                  subtitle: '调整歌词行之间的间距',
                  icon: CupertinoIcons.line_horizontal_3,
                  value: settings.lyricsLineGap.toDouble(),
                  min: 4.0,
                  max: 16.0,
                  divisions: 12,
                  label: '${settings.lyricsLineGap}',
                  onChanged: (value) => settings.setLyricsLineGap(value.toInt()),
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
}
