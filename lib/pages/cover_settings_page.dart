import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class CoverSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const CoverSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<CoverSettingsPage> createState() => _CoverSettingsPageState();
}

class _CoverSettingsPageState extends State<CoverSettingsPage> {
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
                  _buildSectionHeader('封面设置'),
                  const SizedBox(height: 16),
                  _buildCoverSettings(context),
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
            CupertinoIcons.photo,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '封面设置',
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

  /// 构建封面设置
  Widget _buildCoverSettings(BuildContext context) {
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
      },
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
