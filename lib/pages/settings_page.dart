
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const SettingsPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 标题悬停状态
  bool _isTitleHovered = false;
  int _hoveredCardIndex = -1; // 用于设置卡片的悬停状态
             
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('设置类别'),
                  _buildSettingsCards(context),
                ],
              ),
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

  /// 构建设置卡片
  Widget _buildSettingsCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildSettingsCard(
          context,
          '用户界面',
          '自定义应用外观和行为',
          AppIcons.settings,
          Colors.blue,
          0,
        ),
        _buildSettingsCard(
          context,
          '歌词',
          '歌词显示和同步设置',
          AppIcons.musicNote,
          Colors.green,
          1,
        ),
        _buildSettingsCard(
          context,
          '歌曲界面',
          '播放器和歌曲列表设置',
          AppIcons.playCircle,
          Colors.orange,
          2,
        ),
      ],
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int index,
  ) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredCardIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredCardIndex = -1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 80,
        decoration: BoxDecoration(
          color: isHovered
              ? color.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered
                ? color.withOpacity(0.6)
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: isHovered ? 2 : 1,
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isHovered ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: isHovered ? 24 : 0,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
