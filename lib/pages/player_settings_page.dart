
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
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

                // 显示播放次数开关
                _buildSwitchTile(
                  title: '显示播放次数',
                  subtitle: '在歌曲列表中显示播放次数',
                  icon: CupertinoIcons.chart_bar,
                  value: settings.showPlayCount,
                  onChanged: (value) => settings.setShowPlayCount(value),
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
                const Divider(height: 32),

                // 播放器中显示歌词开关
                _buildSwitchTile(
                  title: '播放器中显示歌词',
                  subtitle: '在播放器界面中显示歌词',
                  icon: CupertinoIcons.music_note,
                  value: settings.showLyricsInPlayer,
                  onChanged: (value) => settings.setShowLyricsInPlayer(value),
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
}
