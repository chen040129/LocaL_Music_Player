import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SongPageSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SongPageSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<SongPageSettingsPage> createState() => _SongPageSettingsPageState();
}

class _SongPageSettingsPageState extends State<SongPageSettingsPage> {
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
          Icon(
            CupertinoIcons.music_albums,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '歌曲页面设置',
            style: TextStyle(
              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
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

                if (settings.songPageBackgroundType == SongPageBackgroundType.transparent) ...[
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
                  const Divider(height: 32),
                ],

                if (settings.songPageBackgroundType == SongPageBackgroundType.customImage) ...[
                  _buildCustomImageTile(context, settings),
                  const Divider(height: 32),
                  _buildImageFitTile(context, settings),
                ],
                
                // 封面设置
                const Divider(height: 32),
                _buildSectionHeader('封面设置'),
                const SizedBox(height: 16),
                _buildCoverSettings(context, settings),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建背景类型选择
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
                CupertinoIcons.photo,
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
                    '选择歌曲页面的背景样式',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SongPageBackgroundType.values.map((type) {
            final isSelected = settings.songPageBackgroundType == type;
            return ChoiceChip(
              label: Text(_getBackgroundTypeName(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  settings.setSongPageBackgroundType(type);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 获取背景类型名称
  String _getBackgroundTypeName(SongPageBackgroundType type) {
    switch (type) {
      case SongPageBackgroundType.transparent:
        return '透明';
      case SongPageBackgroundType.fluid:
        return '流体';
      case SongPageBackgroundType.blur:
        return '模糊';
      case SongPageBackgroundType.gradient:
        return '渐变';
      case SongPageBackgroundType.solid:
        return '纯色';
      case SongPageBackgroundType.customImage:
        return '自定义图片';
    }
  }

  /// 构建渐变类型选择
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
                    '选择渐变效果的类型',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GradientType.values.map((type) {
            final isSelected = settings.gradientType == type;
            return ChoiceChip(
              label: Text(type == GradientType.static ? '静态' : '动态'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  settings.setGradientType(type);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建自定义图片设置
  Widget _buildCustomImageTile(BuildContext context, SettingsProvider settings) {
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
                CupertinoIcons.photo,
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
                    '自定义图片路径',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.customImagePath.isNotEmpty
                        ? settings.customImagePath
                        : '未选择图片',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.folder),
              onPressed: () async {
                // TODO: 实现图片选择功能
              },
              tooltip: '选择图片',
            ),
          ],
        ),
      ],
    );
  }

  /// 构建图片布局方式选择
  Widget _buildImageFitTile(BuildContext context, SettingsProvider settings) {
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
                CupertinoIcons.resize,
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
                    '图片布局方式',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择图片的显示方式',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ImageFitType.values.map((type) {
            final isSelected = settings.imageFitType == type;
            return ChoiceChip(
              label: Text(_getImageFitTypeName(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  settings.setImageFitType(type);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 获取图片布局方式名称
  String _getImageFitTypeName(ImageFitType type) {
    switch (type) {
      case ImageFitType.fill:
        return '填充';
      case ImageFitType.cover:
        return '覆盖';
      case ImageFitType.contain:
        return '包含';
      case ImageFitType.fitWidth:
        return '适应宽度';
      case ImageFitType.fitHeight:
        return '适应高度';
      case ImageFitType.none:
        return '原始';
    }
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

  /// 构建封面设置
  Widget _buildCoverSettings(BuildContext context, SettingsProvider settings) {
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
            // 封面形状选择
            _buildCoverShapeTile(context, settings),
            const Divider(height: 32),
            
            // 如果是圆形，显示圆形状态选择
            if (settings.coverShape == CoverShape.circle) ...[
              _buildCircleStateTile(context, settings),
              const Divider(height: 32),
            ],
            
            // 如果是方形，显示弧度设置
            if (settings.coverShape == CoverShape.square) ...[
              _buildSliderTile(
                title: '封面弧度',
                subtitle: '调整方形封面的圆角弧度',
                icon: CupertinoIcons.crop,
                value: settings.coverBorderRadius,
                min: 0.0,
                max: 50.0,
                divisions: 50,
                label: '${settings.coverBorderRadius.toInt()}',
                onChanged: (value) => settings.setCoverBorderRadius(value),
              ),
              const Divider(height: 32),
            ],


          ],
        ),
      ),
    );
  }

  /// 构建封面形状选择
  Widget _buildCoverShapeTile(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.circle_grid_3x3,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '封面形状',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildShapeOption(
                    context,
                    '方形',
                    CupertinoIcons.square,
                    settings.coverShape == CoverShape.square,
                    () => settings.setCoverShape(CoverShape.square),
                  ),
                  const SizedBox(width: 16),
                  _buildShapeOption(
                    context,
                    '圆形',
                    CupertinoIcons.circle,
                    settings.coverShape == CoverShape.circle,
                    () => settings.setCoverShape(CoverShape.circle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 构建形状选项
  Widget _buildShapeOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color?.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取封面形状文本
  String _getCoverShapeText(CoverShape shape) {
    switch (shape) {
      case CoverShape.square:
        return '方形';
      case CoverShape.circle:
        return '圆形';
      default:
        return '方形';
    }
  }
  
  /// 获取圆形封面状态文本
  String _getCircleStateText(CircleCoverState state) {
    switch (state) {
      case CircleCoverState.static:
        return '静态';
      case CircleCoverState.rotating:
        return '旋转';
      default:
        return '静态';
    }
  }


  
  /// 构建圆形封面状态选择
  Widget _buildCircleStateTile(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.arrow_2_circlepath,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '圆形状态',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStateOption(
                    context,
                    '静态',
                    CupertinoIcons.pause_circle,
                    settings.circleCoverState == CircleCoverState.static,
                    () => settings.setCircleCoverState(CircleCoverState.static),
                  ),
                  const SizedBox(width: 16),
                  _buildStateOption(
                    context,
                    '旋转',
                    CupertinoIcons.arrow_counterclockwise,
                    settings.circleCoverState == CircleCoverState.rotating,
                    () => settings.setCircleCoverState(CircleCoverState.rotating),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 构建状态选项
  Widget _buildStateOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color?.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
                color: enabled
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(context).disabledColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
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
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled
                          ? Theme.of(context).iconTheme.color?.withOpacity(0.7)
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
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
}
