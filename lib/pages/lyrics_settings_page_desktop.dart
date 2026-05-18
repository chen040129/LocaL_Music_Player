import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';

/// 桌面歌词设置构建方法
/// 这个文件包含桌面歌词设置的所有UI组件
class DesktopLyricsSettingsBuilder {
  /// 构建桌面歌词设置
  static Widget build(BuildContext context) {
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
                // 启用桌面歌词开关
                _buildSwitchTile(
                  context: context,
                  title: '启用桌面歌词',
                  subtitle: '在桌面上显示歌词窗口',
                  icon: CupertinoIcons.desktopcomputer,
                  value: settings.enableDesktopLyrics,
                  onChanged: (value) async {
                    await settings.setEnableDesktopLyrics(value);
                    final playerProvider = context.read<PlayerProvider>();
                    if (value) {
                      await playerProvider.showDesktopLyrics();
                    } else {
                      await playerProvider.hideDesktopLyrics();
                    }
                  },
                ),
                const Divider(height: 32),

                // 字体大小滑块
                _buildSliderTile(
                  context: context,
                  title: '字体大小',
                  subtitle: '调整桌面歌词的字体大小',
                  icon: CupertinoIcons.textformat_size,
                  value: settings.desktopLyricsFontSize,
                  min: 20.0,
                  max: 50.0,
                  divisions: 30,
                  label: '${settings.desktopLyricsFontSize.toInt()}',
                  onChanged: (value) => settings.setDesktopLyricsFontSize(value),
                ),
                const Divider(height: 32),

                // 调试按钮：Flutter Lyric桌面歌词
                _buildDebugButton(
                  context: context,
                  title: 'Flutter Lyric桌面歌词',
                  subtitle: '使用flutter_lyric库的桌面歌词实现',
                  icon: CupertinoIcons.lab_flask_solid,
                  onPressed: () async {
                    await settings.showFlutterLyricDesktopLyrics();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建设置项（开关）
  static Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
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

  /// 构建设置项（滑块）
  static Widget _buildSliderTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  /// 构建设置项（调试按钮）
  static Widget _buildDebugButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onPressed,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('测试'),
        ),
      ],
    );
  }
}
