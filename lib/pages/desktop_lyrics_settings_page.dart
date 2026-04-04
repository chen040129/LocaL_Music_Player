import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';
import '../common.dart';

class DesktopLyricsSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const DesktopLyricsSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<DesktopLyricsSettingsPage> createState() => _DesktopLyricsSettingsPageState();
}

class _DesktopLyricsSettingsPageState extends State<DesktopLyricsSettingsPage> {
  @override
  void initState() {
    super.initState();
    // 初始化时同步桌面歌词窗口状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      if (settingsProvider.enableDesktopLyrics && !lyricsWindowVisible) {
        playerProvider.showDesktopLyrics();
      }
    });
  }

  SettingsProvider get settingsProvider => context.read<SettingsProvider>();
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          color: Colors.transparent,
          child: Column(
            children: [
              // 顶部工具栏
              Container(
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
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '桌面歌词',
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 设置内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('基本设置'),
                      _buildSettingsItem(
                        '启用桌面歌词',
                        '在桌面上显示歌词窗口',
                        settings.enableDesktopLyrics,
                        (value) async {
                          settings.setEnableDesktopLyrics(value);
                          final playerProvider = context.read<PlayerProvider>();
                          if (value) {
                            await playerProvider.showDesktopLyrics();
                          } else {
                            await playerProvider.hideDesktopLyrics();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('显示设置'),
                      _buildSettingsItem(
                        '显示锁定按钮',
                        '在歌词窗口上显示锁定按钮',
                        settings.showLockButton,
                        (value) {
                          settings.setShowLockButton(value);
                        },
                      ),
                      _buildSettingsItem(
                        '显示控制按钮',
                        '在歌词窗口上显示播放控制按钮',
                        settings.showControlButtons,
                        (value) {
                          settings.setShowControlButtons(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('样式设置'),
                      _buildSettingsItem(
                        '启用卡拉OK效果',
                        '歌词逐字高亮显示',
                        settings.enableKaraokeEffect,
                        (value) {
                          settings.setEnableKaraokeEffect(value);
                        },
                      ),
                      _buildSliderItem(
                        '字体大小',
                        '调整歌词字体大小',
                        settings.desktopLyricsFontSize,
                        20.0,
                        50.0,
                        (value) {
                          settings.setDesktopLyricsFontSize(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader('窗口设置'),
                      _buildSettingsItem(
                        '鼠标悬停显示背景',
                        '鼠标悬停时显示半透明背景',
                        settings.showBackgroundOnHover,
                        (value) {
                          settings.setShowBackgroundOnHover(value);
                        },
                      ),
                      _buildSettingsItem(
                        '始终置顶',
                        '歌词窗口始终显示在其他窗口之上',
                        settings.alwaysOnTop,
                        (value) {
                          settings.setAlwaysOnTop(value);
                        },
                      ),
                      // 底部占位区域
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  /// 构建设置项（开关）
  Widget _buildSettingsItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 构建设置项（滑块）
  Widget _buildSliderItem(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
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
                '${value.toInt()}',
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
            divisions: 30,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
