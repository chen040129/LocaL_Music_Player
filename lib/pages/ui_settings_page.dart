
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../theme/theme_provider.dart';

class UISettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const UISettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<UISettingsPage> createState() => _UISettingsPageState();
}

class _UISettingsPageState extends State<UISettingsPage> {
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
                  _buildSectionHeader('界面设置'),
                  const SizedBox(height: 16),
                  _buildUISettings(context),
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
            CupertinoIcons.settings,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '用户界面设置',
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

  /// 构建用户界面设置
  Widget _buildUISettings(BuildContext context) {
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
                // 主题切换
                _buildSwitchTile(
                  title: '深色模式',
                  subtitle: '切换深色/浅色主题',
                  icon: CupertinoIcons.moon,
                  value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
                const Divider(height: 32),
                // 背景类型选择
                const Text('背景类型'),
                const SizedBox(height: 8),
                SegmentedButton<UIBackgroundType>(
                  segments: const [
                    ButtonSegment(
                      value: UIBackgroundType.normal,
                      label: Text('默认'),
                      icon: Icon(CupertinoIcons.square),
                    ),
                    ButtonSegment(
                      value: UIBackgroundType.fluid,
                      label: Text('流体'),
                      icon: Icon(CupertinoIcons.waveform_path),
                    ),
                    ButtonSegment(
                      value: UIBackgroundType.gradient,
                      label: Text('渐变'),
                      icon: Icon(CupertinoIcons.color_filter),
                    ),
                    ButtonSegment(
                      value: UIBackgroundType.customImage,
                      label: Text('自定义图片'),
                      icon: Icon(CupertinoIcons.photo_on_rectangle),
                    ),
                  ],
                  selected: {settings.uiBackgroundType},
                  onSelectionChanged: (Set<UIBackgroundType> newSelection) {
                    settings.setUIBackgroundType(newSelection.first);
                  },
                ),
                // 流体背景设置
                if (settings.uiBackgroundType == UIBackgroundType.fluid)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSwitchTile(
                          title: '流体动态效果',
                          subtitle: '启用流体背景的动态效果',
                          icon: CupertinoIcons.waveform_path,
                          value: settings.isFluidDynamic,
                          onChanged: (value) => settings.setIsFluidDynamic(value),
                        ),
                      ],
                    ),
                  ),
                // 默认背景类型的设置
                if (settings.uiBackgroundType == UIBackgroundType.normal)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 窗口背景透明度滑块
                        _buildSliderTile(
                          title: '窗口背景透明度',
                          subtitle: '调整整个应用窗口的背景透明度',
                          icon: CupertinoIcons.eye,
                          value: 1.0 - settings.windowOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${((1.0 - settings.windowOpacity) * 100).toInt()}%',
                          onChanged: (value) => settings.setWindowOpacity(1.0 - value),
                        ),
                      ],
                    ),
                  ),
                // 渐变背景设置
                if (settings.uiBackgroundType == UIBackgroundType.gradient)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 同步渐变设置选项
                        SwitchListTile(
                          title: const Text('同步渐变设置'),
                          subtitle: const Text('与歌曲页面的渐变设置保持一致'),
                          value: settings.syncGradientSettings,
                          onChanged: (value) {
                            settings.setSyncGradientSettings(value);
                            // 如果启用同步，立即同步当前设置
                            if (value) {
                              settings.setUIGradientType(settings.uiGradientType);
                              settings.setUIGradientSongColorRatio(settings.uiGradientSongColorRatio);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        // 渐变类型选择
                        const Text('渐变类型'),
                        const SizedBox(height: 8),
                        SegmentedButton<GradientType>(
                          segments: const [
                            ButtonSegment(
                              value: GradientType.static,
                              label: Text('静态'),
                              icon: Icon(CupertinoIcons.pause),
                            ),
                            ButtonSegment(
                              value: GradientType.dynamic,
                              label: Text('动态'),
                              icon: Icon(CupertinoIcons.play),
                            ),
                          ],
                          selected: {settings.uiGradientType},
                          onSelectionChanged: (Set<GradientType> newSelection) {
                            settings.setUIGradientType(newSelection.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        // 歌曲主题色占比
                        Row(
                          children: [
                            const Text('歌曲主题色占比'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Slider(
                                value: settings.uiGradientSongColorRatio,
                                min: 0.0,
                                max: 1.0,
                                divisions: 100,
                                label: '${(settings.uiGradientSongColorRatio * 100).toInt()}%',
                                onChanged: (value) {
                                  settings.setUIGradientSongColorRatio(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // 自定义图片路径选择
                if (settings.uiBackgroundType == UIBackgroundType.customImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图片路径选择
                        Row(
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
                                controller: TextEditingController(text: settings.uiCustomImagePath),
                                onChanged: (value) {
                                  settings.setUICustomImagePath(value);
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
                                  settings.setUICustomImagePath(result.files.single.path!);
                                }
                              },
                              tooltip: '选择图片',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(CupertinoIcons.arrow_right_square),
                              onPressed: () async {
                                // 将用户界面背景图片同步到歌词页面
                                if (settings.uiCustomImagePath.isNotEmpty) {
                                  await settings.setCustomImagePath(settings.uiCustomImagePath);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('已将背景图片同步到歌词页面'),
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
                              tooltip: '同步到歌词页面',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 图片布局方式选择
                        const Text('图片布局方式'),
                        const SizedBox(height: 8),
                        SegmentedButton<ImageFitType>(
                          segments: const [
                            ButtonSegment(
                              value: ImageFitType.fill,
                              label: Text('填充'),
                              icon: Icon(CupertinoIcons.resize),
                            ),
                            ButtonSegment(
                              value: ImageFitType.cover,
                              label: Text('覆盖'),
                              icon: Icon(CupertinoIcons.photo),
                            ),
                            ButtonSegment(
                              value: ImageFitType.contain,
                              label: Text('包含'),
                              icon: Icon(CupertinoIcons.square),
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
                              label: Text('原始大小'),
                              icon: Icon(CupertinoIcons.square_on_square),
                            ),
                          ],
                          selected: {settings.uiImageFitType},
                          onSelectionChanged: (Set<ImageFitType> newSelection) {
                            settings.setUIImageFitType(newSelection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 32),
                // 播放栏玻璃材质开关
                _buildSwitchTile(
                  title: '播放栏玻璃材质',
                  subtitle: '为底部播放栏应用玻璃材质效果',
                  icon: CupertinoIcons.music_note_2,
                  value: settings.usePlayerGlass,
                  onChanged: (value) => settings.setUsePlayerGlass(value),
                ),
                const Divider(height: 32),

                // 玻璃透明度滑块
                _buildSliderTile(
                  title: '玻璃透明度',
                  subtitle: '调整玻璃材质的透明度',
                  icon: CupertinoIcons.eye,
                  value: 1.0 - settings.glassOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${((1.0 - settings.glassOpacity) * 100).toInt()}%',
                  onChanged: (value) => settings.setGlassOpacity(1.0 - value),
                ),
                const Divider(height: 32),

                // 边框弧度值滑块
                _buildSliderTile(
                  title: '边框弧度值',
                  subtitle: '调整主页面元素的边框弧度',
                  icon: CupertinoIcons.rectangle,
                  value: settings.borderRadius,
                  min: 0.0,
                  max: 20.0,
                  divisions: 20,
                  label: '${settings.borderRadius.toInt()}',
                  onChanged: (value) => settings.setBorderRadius(value),
                ),
                const Divider(height: 32),

                // 窗口边框弧度值滑块
                _buildSliderTile(
                  title: '窗口边框弧度值',
                  subtitle: '调整整个应用窗口的边框弧度',
                  icon: CupertinoIcons.app,
                  value: settings.windowBorderRadius,
                  min: 0.0,
                  max: 30.0,
                  divisions: 30,
                  label: '${settings.windowBorderRadius.toInt()}',
                  onChanged: (value) => settings.setWindowBorderRadius(value),
                ),
                const Divider(height: 32),



                // 音乐卡片透明度滑块
                _buildSliderTile(
                  title: '音乐卡片透明度',
                  subtitle: '调整音乐卡片的背景透明度',
                  icon: CupertinoIcons.rectangle_on_rectangle,
                  value: 1.0 - settings.cardOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${((1.0 - settings.cardOpacity) * 100).toInt()}%',
                  onChanged: (value) => settings.setCardOpacity(1.0 - value),
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
}
