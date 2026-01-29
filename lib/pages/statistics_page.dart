
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
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
                Icon(AppIcons.chart, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '统计',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 刷新按钮
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // TODO: 实现刷新功能
                  },
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          // 统计内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 统计卡片
                  _buildStatCard(
                    context,
                    '总歌曲数',
                    '0',
                    AppIcons.musicNote,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    '总专辑数',
                    '0',
                    AppIcons.album,
                    Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    '总艺术家数',
                    '0',
                    AppIcons.mic,
                    Colors.yellow,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    '总播放时长',
                    '0小时',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
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
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
