import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_icons.dart';
import 'mask_card.dart';

/// 音质饼状图组件
class QualityPieChartWidget extends StatelessWidget {
  const QualityPieChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final musicList = musicProvider.musicList;
    final qualityStats = musicProvider.qualityStats;

    // 提取音质数量和大小
    final Map<String, int> qualityCounts = {};
    final Map<String, int> qualitySizes = {};

    qualityStats.forEach((quality, stats) {
      qualityCounts[quality] = stats['count'] ?? 0;
      qualitySizes[quality] = stats['size'] ?? 0;
    });

    // 如果没有数据，显示提示
    if (musicList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.pieChart,
                size: 64,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无数据',
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 准备饼状图数据
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    int colorIndex = 0;
    qualityCounts.forEach((quality, count) {
      final percentage = count / musicList.length;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: percentage * 100,
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );
      colorIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 3D饼状图
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
                borderData: FlBorderData(
                  show: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 音质统计信息
          _buildQualityStats(context, qualityCounts, qualitySizes, colors),
        ],
      ),
    );
  }

  /// 构建音质统计信息
  Widget _buildQualityStats(
    BuildContext context,
    Map<String, int> qualityCounts,
    Map<String, int> qualitySizes,
    List<Color> colors,
  ) {
    final settings = Provider.of<SettingsProvider>(context);
    int colorIndex = 0;
    final List<Widget> statWidgets = [];

    // 按音质排序
    final sortedQualities = qualityCounts.keys.toList()..sort();

    // 计算总大小
    final totalSize = qualitySizes.values.fold<int>(0, (sum, size) => sum + size);

    for (final quality in sortedQualities) {
      final count = qualityCounts[quality] ?? 0;
      final size = qualitySizes[quality] ?? 0;
      final sizePercentage = totalSize > 0 ? (size / totalSize * 100) : 0;
      final color = colors[colorIndex % colors.length];

      statWidgets.add(
        MaskCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          accentColor: color,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quality,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '歌曲数量: $count',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatFileSize(size),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '占比: ${sizePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    }

    return Column(
      children: statWidgets,
    );
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
