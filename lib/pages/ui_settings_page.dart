
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
                  value: settings.glassOpacity,
                  min: 0.0,
                  max: 0.8,
                  divisions: 80,
                  label: '${(settings.glassOpacity * 100).toInt()}%',
                  onChanged: (value) => settings.setGlassOpacity(value),
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

                // 窗口背景透明度滑块
                _buildSliderTile(
                  title: '窗口背景透明度',
                  subtitle: '调整整个应用窗口的背景透明度',
                  icon: CupertinoIcons.eye,
                  value: settings.windowOpacity,
                  min: 0.3,
                  max: 1.0,
                  divisions: 70,
                  label: '${(settings.windowOpacity * 100).toInt()}%',
                  onChanged: (value) => settings.setWindowOpacity(value),
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
