
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const SettingsPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 标题悬停状态
  bool _isTitleHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                MouseRegion(
                  onEnter: (_) => setState(() => _isTitleHovered = true),
                  onExit: (_) => setState(() => _isTitleHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      // 通知父组件展开侧边栏
                      if (widget.onSidebarToggle != null) {
                        widget.onSidebarToggle!();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isTitleHovered 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.settings, 
                            color: _isTitleHovered 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '设置',
                            style: TextStyle(
                              color: _isTitleHovered 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 设置内容
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 主题设置
                _buildSectionHeader('外观'),
                _buildThemeSetting(context),
                const SizedBox(height: 24),

                // 播放设置
                _buildSectionHeader('播放'),
                _buildSettingItem(
                  context,
                  '自动播放',
                  '添加到播放列表后自动播放',
                  false,
                  (value) {},
                ),
                _buildSettingItem(
                  context,
                  '循环播放',
                  '播放列表循环播放',
                  true,
                  (value) {},
                ),
                const SizedBox(height: 24),

                // 音质设置
                _buildSectionHeader('音质'),
                _buildQualitySetting(context),
                const SizedBox(height: 24),

                // 其他设置
                _buildSectionHeader('其他'),
                _buildSettingItem(
                  context,
                  '显示歌词',
                  '播放时显示歌词',
                  true,
                  (value) {},
                ),
                _buildSettingItem(
                  context,
                  '最小化到托盘',
                  '关闭窗口时最小化到系统托盘',
                  false,
                  (value) {},
                ),
              ],
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

  /// 构建主题设置
  Widget _buildThemeSetting(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: ListTile(
            title: const Text('主题模式'),
            subtitle: Text(
              themeProvider.isDarkMode ? '深色主题' : '浅色主题',
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              icon: Icon(AppIcons.arrowDown, size: 18),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(AppIcons.lightMode, size: 18),
                      SizedBox(width: 8),
                      Text('浅色'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(AppIcons.darkMode, size: 18),
                      SizedBox(width: 8),
                      Text('深色'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(AppIcons.lightMode, size: 18),
                      Icon(AppIcons.darkMode, size: 18),
                      SizedBox(width: 8),
                      Text('跟随系统'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建音质设置
  Widget _buildQualitySetting(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('默认音质'),
        subtitle: const Text('选择默认播放音质'),
        trailing: DropdownButton<String>(
          value: '标准',
          icon: Icon(AppIcons.arrowDown, size: 18),
          items: const [
            DropdownMenuItem(
              value: '标准',
              child: Row(
                children: [
                  Icon(AppIcons.qualityStandard, size: 18),
                  SizedBox(width: 8),
                  Text('标准'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: '高质量',
              child: Row(
                children: [
                  Icon(AppIcons.qualityHigh, size: 18),
                  SizedBox(width: 8),
                  Text('高质量'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: '高解析度',
              child: Row(
                children: [
                  Icon(AppIcons.qualityUltra, size: 18),
                  SizedBox(width: 8),
                  Text('高解析度'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            // TODO: 实现音质设置
          },
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
