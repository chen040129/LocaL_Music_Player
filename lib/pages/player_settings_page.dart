
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';

class PlayerSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PlayerSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<PlayerSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<PlayerSettingsPage> {
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
                  _buildSectionHeader('播放器设置'),
                  const SizedBox(height: 16),
                  _buildPlayerSettings(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('歌曲页面设置'),
                  const SizedBox(height: 16),
                  _buildSongPageSettings(context),
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
            CupertinoIcons.play_circle,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '播放器设置',
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

  /// 构建播放器设置
  Widget _buildPlayerSettings(BuildContext context) {
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
                // TODO: 显示专辑封面开关（后续版本实现）
                // _buildSwitchTile(
                //   title: '显示专辑封面',
                //   subtitle: '在播放器中显示专辑封面',
                //   icon: CupertinoIcons.music_albums,
                //   value: settings.showAlbumArt,
                //   onChanged: (value) => settings.setShowAlbumArt(value),
                // ),
                // const Divider(height: 32),

                // TODO: 播放器中显示歌词开关（后续版本实现）
                // _buildSwitchTile(
                //   title: '播放器中显示歌词',
                //   subtitle: '在播放器界面中显示歌词',
                //   icon: CupertinoIcons.music_note,
                //   value: settings.showLyricsInPlayer,
                //   onChanged: (value) => settings.setShowLyricsInPlayer(value),
                // ),
                // const Divider(height: 32),

                // 自动播放下一首开关
                _buildSwitchTile(
                  title: '自动播放下一首',
                  subtitle: '当前歌曲播放结束后自动播放下一首',
                  icon: CupertinoIcons.forward_end,
                  value: settings.autoPlayNext,
                  onChanged: (value) => settings.setAutoPlayNext(value),
                ),
                const Divider(height: 32),

                // 保存播放进度开关
                _buildSwitchTile(
                  title: '保存播放进度',
                  subtitle: '记住每首歌的播放位置',
                  icon: CupertinoIcons.bookmark,
                  value: settings.savePlayProgress,
                  onChanged: (value) => settings.setSavePlayProgress(value),
                ),
                const Divider(height: 32),

                // 启用淡入淡出效果开关
                _buildSwitchTile(
                  title: '启用淡入淡出效果',
                  subtitle: '播放和暂停时使用淡入淡出效果',
                  icon: CupertinoIcons.waveform,
                  value: settings.enableFadeEffect,
                  onChanged: (value) => settings.setEnableFadeEffect(value),
                ),
                const Divider(height: 32),

                // 淡入淡出时长滑块
                _buildSliderTile(
                  title: '淡入淡出时长',
                  subtitle: '调整淡入淡出效果的时长',
                  icon: CupertinoIcons.time,
                  value: settings.fadeDuration,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  label: '${settings.fadeDuration.toStringAsFixed(1)}秒',
                  onChanged: (value) => settings.setFadeDuration(value),
                  enabled: settings.enableFadeEffect,
                ),
                const Divider(height: 32),

                // 默认音量滑块
                _buildSliderTile(
                  title: '默认音量',
                  subtitle: '设置播放器的默认音量',
                  icon: CupertinoIcons.volume_up,
                  value: settings.defaultVolume.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${settings.defaultVolume}%',
                  onChanged: (value) => settings.setDefaultVolume(value.toInt()),
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
    bool enabled = true,
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
                color: enabled 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: enabled 
                          ? null 
                          : Theme.of(context).iconTheme.color?.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled 
                          ? Theme.of(context).iconTheme.color?.withOpacity(0.7)
                          : Theme.of(context).iconTheme.color?.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: enabled 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  /// 构建歌曲页面设置
  Widget _buildSongPageSettings(BuildContext context) {
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
                // 背景类型选择
                _buildBackgroundTypeTile(context, settings),
                const Divider(height: 32),
                
                // 根据背景类型显示不同的设置选项
                if (settings.songPageBackgroundType == SongPageBackgroundType.fluid) ...[
                  _buildSwitchTile(
                    title: '流体动态效果',
                    subtitle: '启用流体背景的动态效果',
                    icon: CupertinoIcons.waveform_path,
                    value: settings.isFluidDynamic,
                    onChanged: (value) => settings.setIsFluidDynamic(value),
                  ),
                  const Divider(height: 32),
                  _buildSliderTile(
                    title: '流体球大小',
                    subtitle: '调整流体背景中球的大小',
                    icon: CupertinoIcons.circle,
                    value: settings.fluidBubblesSize,
                    min: 100.0,
                    max: 1000.0,
                    divisions: 90,
                    label: '${settings.fluidBubblesSize.toInt()}',
                    onChanged: (value) => settings.setFluidBubblesSize(value),
                  ),
                  const Divider(height: 32),
                  _buildSliderTile(
                    title: '流体偏移量',
                    subtitle: '调整流体效果的偏移程度',
                    icon: CupertinoIcons.move,
                    value: settings.fluidOffsetAmount,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    label: '${settings.fluidOffsetAmount.toInt()}',
                    onChanged: (value) => settings.setFluidOffsetAmount(value),
                  ),
                  const Divider(height: 32),
                  _buildSliderTile(
                    title: '流体层透明度',
                    subtitle: '调整流体层的透明度',
                    icon: CupertinoIcons.eye_slash,
                    value: settings.fluidLayerOpacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 90,
                    label: '${(settings.fluidLayerOpacity * 100).toInt()}%',
                    onChanged: (value) => settings.setFluidLayerOpacity(value),
                  ),
                  const Divider(height: 32),
                  _buildSliderTile(
                    title: '流体动画时长',
                    subtitle: '调整流体动画的持续时间',
                    icon: CupertinoIcons.time,
                    value: settings.fluidAnimationDuration.toDouble(),
                    min: 500,
                    max: 10000,
                    divisions: 95,
                    label: '${settings.fluidAnimationDuration}ms',
                    onChanged: (value) => settings.setFluidAnimationDuration(value.toInt()),
                  ),
                  const Divider(height: 32),
                ],
                
                if (settings.songPageBackgroundType == SongPageBackgroundType.blur) ...[
                  _buildSliderTile(
                    title: '模糊程度',
                    subtitle: '调整背景的模糊程度',
                    icon: CupertinoIcons.photo,
                    value: settings.blurAmount,
                    min: 0.0,
                    max: 50.0,
                    divisions: 50,
                    label: '${settings.blurAmount.toInt()}',
                    onChanged: (value) => settings.setBlurAmount(value),
                  ),
                  const Divider(height: 32),
                ],
                
                if (settings.songPageBackgroundType == SongPageBackgroundType.gradient) ...[
                  _buildGradientTypeTile(context, settings),
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('同步渐变设置'),
                    subtitle: const Text('与用户界面的渐变设置保持一致'),
                    value: settings.syncGradientSettings,
                    onChanged: (value) {
                      settings.setSyncGradientSettings(value);
                      // 如果启用同步，立即同步当前设置
                      if (value) {
                        settings.setGradientType(settings.gradientType);
                        settings.setGradientSongColorRatio(settings.gradientSongColorRatio);
                      }
                    },
                  ),
                  const Divider(height: 32),
                  _buildSliderTile(
                    title: '歌曲主题色占比',
                    subtitle: '调整渐变中歌曲主题色的占比',
                    icon: CupertinoIcons.color_filter,
                    value: settings.gradientSongColorRatio,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(settings.gradientSongColorRatio * 100).toInt()}%',
                    onChanged: (value) => settings.setGradientSongColorRatio(value),
                  ),
                  const Divider(height: 32),
                ],
                

              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建背景类型选择项
  Widget _buildBackgroundTypeTile(BuildContext context, SettingsProvider settings) {
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
                CupertinoIcons.photo_fill_on_rectangle_fill,
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
                    '背景类型',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择歌曲页面的背景类型',
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
        SegmentedButton<SongPageBackgroundType>(
          segments: const [
            ButtonSegment(
              value: SongPageBackgroundType.transparent,
              label: Text('透明'),
              icon: Icon(CupertinoIcons.eye_slash),
            ),
            ButtonSegment(
              value: SongPageBackgroundType.fluid,
              label: Text('流体'),
              icon: Icon(CupertinoIcons.waveform_path),
            ),
            ButtonSegment(
              value: SongPageBackgroundType.blur,
              label: Text('模糊'),
              icon: Icon(CupertinoIcons.photo),
            ),
            ButtonSegment(
              value: SongPageBackgroundType.gradient,
              label: Text('渐变'),
              icon: Icon(CupertinoIcons.color_filter),
            ),
            ButtonSegment(
              value: SongPageBackgroundType.solid,
              label: Text('纯色'),
              icon: Icon(CupertinoIcons.circle_fill),
            ),
            ButtonSegment(
              value: SongPageBackgroundType.customImage,
              label: Text('自定义图片'),
              icon: Icon(CupertinoIcons.photo_on_rectangle),
            ),
          ],
          selected: {settings.songPageBackgroundType},
          onSelectionChanged: (Set<SongPageBackgroundType> newSelection) {
            settings.setSongPageBackgroundType(newSelection.first);
          },
        ),
        // 透明背景类型的设置
        if (settings.songPageBackgroundType == SongPageBackgroundType.transparent)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 页面透明度滑块
                _buildSliderTile(
                  title: '页面透明度',
                  subtitle: '调整歌曲页面的透明度',
                  icon: CupertinoIcons.eye,
                  value: settings.pageOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(settings.pageOpacity * 100).toInt()}%',
                  onChanged: (value) => settings.setPageOpacity(value),
                ),
              ],
            ),
          ),
        // 自定义图片路径选择
        if (settings.songPageBackgroundType == SongPageBackgroundType.customImage)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '自定义图片路径',
                      hintText: '请输入图片路径',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: TextEditingController(text: settings.customImagePath),
                    onChanged: (value) {
                      settings.setCustomImagePath(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(CupertinoIcons.folder),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.single.path != null) {
                      settings.setCustomImagePath(result.files.single.path!);
                    }
                  },
                  tooltip: '选择图片',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_left_square),
                  onPressed: () async {
                    // 将歌词页面背景图片同步到用户界面
                    if (settings.customImagePath.isNotEmpty) {
                      await settings.setUICustomImagePath(settings.customImagePath);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已将背景图片同步到用户界面'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请先选择一张图片'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: '同步到用户界面',
                ),
              ],
            ),
          ),
        // 图片布局方式选择
        if (settings.songPageBackgroundType == SongPageBackgroundType.customImage)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('图片布局方式'),
                const SizedBox(height: 8),
                SegmentedButton<ImageFitType>(
                  segments: const [
                    ButtonSegment(
                      value: ImageFitType.fill,
                      label: Text('拉伸'),
                      icon: Icon(CupertinoIcons.arrow_up_right),
                    ),
                    ButtonSegment(
                      value: ImageFitType.cover,
                      label: Text('覆盖'),
                      icon: Icon(CupertinoIcons.rectangle),
                    ),
                    ButtonSegment(
                      value: ImageFitType.contain,
                      label: Text('包含'),
                      icon: Icon(CupertinoIcons.square_list),
                    ),
                    ButtonSegment(
                      value: ImageFitType.fitWidth,
                      label: Text('适应宽度'),
                      icon: Icon(CupertinoIcons.arrow_left_right),
                    ),
                    ButtonSegment(
                      value: ImageFitType.fitHeight,
                      label: Text('适应高度'),
                      icon: Icon(CupertinoIcons.arrow_up_down),
                    ),
                    ButtonSegment(
                      value: ImageFitType.none,
                      label: Text('原始'),
                      icon: Icon(CupertinoIcons.photo),
                    ),
                  ],
                  selected: {settings.imageFitType},
                  onSelectionChanged: (Set<ImageFitType> newSelection) {
                    settings.setImageFitType(newSelection.first);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建渐变类型选择项
  Widget _buildGradientTypeTile(BuildContext context, SettingsProvider settings) {
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
                CupertinoIcons.color_filter,
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
                    '渐变类型',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择渐变背景的类型',
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
        SegmentedButton<GradientType>(
          segments: const [
            ButtonSegment(
              value: GradientType.static,
              label: Text('静态'),
              icon: Icon(CupertinoIcons.stop_circle),
            ),
            ButtonSegment(
              value: GradientType.dynamic,
              label: Text('动态'),
              icon: Icon(CupertinoIcons.play_circle),
            ),
          ],
          selected: {settings.gradientType},
          onSelectionChanged: (Set<GradientType> newSelection) {
            settings.setGradientType(newSelection.first);
          },
        ),
      ],
    );
  }
}
