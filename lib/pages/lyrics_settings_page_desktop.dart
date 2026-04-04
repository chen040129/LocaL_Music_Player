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

                // 显示锁定按钮
                _buildSwitchTile(
                  context: context,
                  title: '显示锁定按钮',
                  subtitle: '在歌词窗口上显示锁定按钮',
                  icon: CupertinoIcons.lock,
                  value: settings.showLockButton,
                  onChanged: (value) => settings.setShowLockButton(value),
                ),
                const Divider(height: 32),

                // 显示控制按钮
                _buildSwitchTile(
                  context: context,
                  title: '显示控制按钮',
                  subtitle: '在歌词窗口上显示播放控制按钮',
                  icon: CupertinoIcons.play_rectangle,
                  value: settings.showControlButtons,
                  onChanged: (value) => settings.setShowControlButtons(value),
                ),
                const Divider(height: 32),

                // 启用卡拉OK效果
                _buildSwitchTile(
                  context: context,
                  title: '启用卡拉OK效果',
                  subtitle: '歌词逐字高亮显示',
                  icon: CupertinoIcons.music_note,
                  value: settings.enableKaraokeEffect,
                  onChanged: (value) => settings.setEnableKaraokeEffect(value),
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

                // 鼠标悬停显示背景
                _buildSwitchTile(
                  context: context,
                  title: '鼠标悬停显示背景',
                  subtitle: '鼠标悬停时显示半透明背景',
                  icon: CupertinoIcons.cursor_rays,
                  value: settings.showBackgroundOnHover,
                  onChanged: (value) => settings.setShowBackgroundOnHover(value),
                ),
                const Divider(height: 32),

                // 始终置顶
                _buildSwitchTile(
                  context: context,
                  title: '始终置顶',
                  subtitle: '歌词窗口始终显示在其他窗口之上',
                  icon: CupertinoIcons.arrow_up,
                  value: settings.alwaysOnTop,
                  onChanged: (value) => settings.setAlwaysOnTop(value),
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
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14,
        ),
      ),
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
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
}
