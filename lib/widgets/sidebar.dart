import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';

class Sidebar extends StatelessWidget {

  final bool isExpanded;
  final VoidCallback onToggle;

  const Sidebar({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 240 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // 顶部工具栏
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16.0 : 8.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 主题切换按钮
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? AppIcons.sun
                              : AppIcons.moon,
                          key: ValueKey<bool>(themeProvider.isDarkMode),
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                      tooltip: themeProvider.isDarkMode ? '切换到浅色主题' : '切换到深色主题',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    );
                  },
                ),
                // 侧边栏切换按钮
                IconButton(
                  icon: Icon(
                    isExpanded ? AppIcons.sidebarLeft : AppIcons.sidebarRight,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
          // 导航菜单项
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.musicNote,
                  iconColor: Colors.green,
                  title: '歌曲',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.album,
                  iconColor: Colors.red,
                  title: '专辑',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.mic,
                  iconColor: Colors.yellow,
                  title: '艺术家',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.folder,
                  iconColor: Colors.purple,
                  title: '文件夹',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.playlist,
                  iconColor: Colors.blue,
                  title: '歌单',
                  isExpanded: isExpanded,
                ),
                Divider(
                  height: 24,
                  color: Theme.of(context).dividerColor,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.scanner,
                  iconColor: Colors.orange,
                  title: '扫描音乐',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.library,
                  iconColor: Colors.teal,
                  title: '音乐库',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.chart,
                  iconColor: Colors.indigo,
                  title: '统计',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.settings,
                  iconColor: Colors.grey,
                  title: '设置',
                  isExpanded: isExpanded,
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.info,
                  iconColor: Colors.cyan,
                  title: '关于',
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? iconColor.withOpacity(0.8)
                      : iconColor,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
