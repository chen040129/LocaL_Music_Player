
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/music_provider.dart';
import '../services/music_scanner_service.dart';

class StatisticsPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const StatisticsPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _touchedIndex = -1;
  int _selectedYearIndex = -1;
  // 标题悬停状态
  bool _isTitleHovered = false;
  int _selectedFormatIndex = -1;
  int _hoveredIndex = -1;
  int _selectedRankingType = 0; // 0: 日榜, 1: 周榜, 2: 月榜, 3: 年榜
  int _selectedSortType = 0; // 0: 按歌曲, 1: 按作曲家, 2: 按专辑
  int _hoveredCardIndex = -1; // 用于统计卡片的悬停状态
  bool _isRefreshing = false; // 防止重复刷新

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                if (musicProvider.musicList.isEmpty) {
                  return _buildEmptyState(context);
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCards(context, musicProvider),
                      const SizedBox(height: 24),
                      _buildQualityChartSection(context, musicProvider),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 400,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildFormatChartSection(context, musicProvider),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildRankingList(context, musicProvider),
                            ),
                          ],
                        ),
                      ),
                      // 底部占位区域，确保内容滚动到底部时不被播放栏遮挡
                      const SizedBox(height: 90),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                      CupertinoIcons.chart_bar, 
                      color: _isTitleHovered 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '统计',
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
          const Spacer(),
          IconButton(
            icon: Icon(
              CupertinoIcons.refresh,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            ),
            onPressed: _isRefreshing ? null : () async {
              if (_isRefreshing) return;
              setState(() {
                _isRefreshing = true;
                _touchedIndex = -1;
                _selectedYearIndex = -1;
                _selectedFormatIndex = -1;
              });
              try {
                final musicProvider = Provider.of<MusicProvider>(context, listen: false);
                // 保存统计数据
                await musicProvider.saveData();
                // 重新初始化音乐数据
                await musicProvider.initialize();
              } finally {
                if (mounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              }
            },
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无统计数据',
            style: TextStyle(
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先扫描音乐文件',
            style: TextStyle(
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, MusicProvider provider) {
    final totalDuration = provider.totalDuration;
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    final totalSize = provider.totalFileSize;
    final allSongsDuration = provider.allSongsDuration;
    final allSongsHours = allSongsDuration ~/ 3600;
    final allSongsMinutes = (allSongsDuration % 3600) ~/ 60;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          context,
          '总歌曲数',
          provider.musicList.length.toString(),
          CupertinoIcons.music_note,
          Colors.green,
          0,
        ),
        _buildStatCard(
          context,
          '总专辑数',
          provider.albums.length.toString(),
          CupertinoIcons.music_albums,
          Colors.red,
          1,
        ),
        _buildStatCard(
          context,
          '总艺术家数',
          provider.artists.length.toString(),
          CupertinoIcons.person,
          Colors.yellow,
          2,
        ),
        GestureDetector(
          onDoubleTap: () {
            // 显示确认对话框
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认重置'),
                content: const Text('确定要将播放时间归零吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
                      await musicProvider.resetTotalDuration();
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          },
          child: _buildStatCard(
            context,
            '总播放时长',
            '$hours小时$minutes分钟',
            CupertinoIcons.time,
            Colors.blue,
            3,
          ),
        ),
        _buildStatCard(
          context,
          '总文件大小',
          _formatFileSize(totalSize),
          CupertinoIcons.folder,
          Colors.purple,
          4,
        ),
        _buildStatCard(
          context,
          '平均歌曲时长',
          provider.musicList.isNotEmpty
              ? '${(allSongsDuration ~/ provider.musicList.length) ~/ 60}:${((allSongsDuration ~/ provider.musicList.length) % 60).toString().padLeft(2, '0')}'
              : '0:00',
          CupertinoIcons.time_solid,
          Colors.orange,
          5,
        ),
        _buildStatCard(
          context,
          '总播放次数',
          provider.totalPlayCount.toString(),
          CupertinoIcons.play_circle,
          Colors.teal,
          6,
        ),
        _buildStatCard(
          context,
          '所有歌曲时长',
          '$allSongsHours小时$allSongsMinutes分钟',
          CupertinoIcons.music_note_2,
          Colors.pink,
          7,
        ),
      ],
    );
  }

  Widget _buildQualityChartSection(BuildContext context, MusicProvider provider) {
    final qualityStats = provider.qualityStats;
    if (qualityStats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '音质分布',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      sections: _getQualitySections(qualityStats, provider.musicList.length),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              _hoveredIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildQualityLegend(qualityStats, provider.musicList.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getQualitySections(Map<String, Map<String, int>> qualityStats, int totalCount) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    int index = 0;

    qualityStats.forEach((quality, stats) {
      final count = stats['count'] ?? 0;
      final percentage = count / totalCount;
      final isTouched = index == _touchedIndex || index == _hoveredIndex;
      final radius = isTouched ? 50.0 : 40.0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: percentage * 100,
          title: isTouched ? '${(percentage * 100).toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );
      colorIndex++;
      index++;
    });

    return sections;
  }

  Widget _buildQualityLegend(Map<String, Map<String, int>> qualityStats, int totalCount) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    int colorIndex = 0;
    final List<Widget> legendItems = [];

    qualityStats.forEach((quality, stats) {
      final count = stats['count'] ?? 0;
      final size = stats['size'] ?? 0;
      final percentage = count / totalCount * 100;
      final currentIndex = legendItems.length;
      final isTouched = currentIndex == _touchedIndex || currentIndex == _hoveredIndex;

      legendItems.add(
        MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoveredIndex = currentIndex;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredIndex = -1;
            });
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _touchedIndex = isTouched ? -1 : currentIndex;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTouched ? colors[colorIndex % colors.length].withOpacity(0.15) : null,
                borderRadius: BorderRadius.circular(8),
                border: isTouched
                    ? Border.all(
                        color: colors[colorIndex % colors.length],
                        width: 2,
                      )
                    : null,
                boxShadow: isTouched
                    ? [
                        BoxShadow(
                          color: colors[colorIndex % colors.length].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[colorIndex % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quality,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% ($count首)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatFileSize(size),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors[colorIndex % colors.length],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      colorIndex++;
    });

    return Column(children: legendItems);
  }

  Widget _buildYearChartSection(BuildContext context, MusicProvider provider) {
    final yearStats = provider.yearStats;
    if (yearStats.isEmpty) return const SizedBox.shrink();

    final sortedYears = yearStats.keys.toList()..sort();
    final maxCount = yearStats.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '年份分布',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final year = sortedYears[group.x.toInt()];
                      return BarTooltipItem(
                        '$year年\n',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.round()}首',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedYears.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedYears[index].toString(),
                              style: TextStyle(
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(
                  sortedYears.length,
                  (index) {
                    final year = sortedYears[index];
                    final count = yearStats[year] ?? 0;
                    final isSelected = index == _selectedYearIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChartSection(BuildContext context, MusicProvider provider) {
    final formatStats = provider.formatStats;
    if (formatStats.isEmpty) return const SizedBox.shrink();

    final sortedFormats = formatStats.keys.toList()..sort();
    final maxCount = formatStats.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.music_note_2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '格式分布',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final format = sortedFormats[group.x.toInt()];
                      return BarTooltipItem(
                        '$format\n',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.round()}首',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedFormats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedFormats[index].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(
                  sortedFormats.length,
                  (index) {
                    final format = sortedFormats[index];
                    final count = formatStats[format] ?? 0;
                    final isSelected = index == _selectedFormatIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLists(BuildContext context, MusicProvider provider) {
    final topAlbums = provider.albums.take(5).toList();
    final topArtists = provider.artists.take(5).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTopAlbumsList(context, provider, topAlbums),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopArtistsList(context, provider, topArtists),
        ),
      ],
    );
  }

  Widget _buildTopAlbumsList(BuildContext context, MusicProvider provider, List<String> albums) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.music_albums,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '热门专辑',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...albums.asMap().entries.map((entry) {
            final index = entry.key;
            final album = entry.value;
            final count = provider.getMusicByAlbum(album).length;
            return _buildListItem(context, album, count, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopArtistsList(BuildContext context, MusicProvider provider, List<String> artists) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '热门艺术家',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...artists.asMap().entries.map((entry) {
            final index = entry.key;
            final artist = entry.value;
            final count = provider.getMusicByArtist(artist).length;
            return _buildListItem(context, artist, count, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title, int count, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: index < 3
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: index < 3 ? Colors.white : Theme.of(context).iconTheme.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count首',
            style: TextStyle(
              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
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
              : Colors.transparent,
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
                          value,
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

  Widget _buildRankingList(BuildContext context, MusicProvider provider) {
    final periods = [
      const Duration(days: 1),
      const Duration(days: 7),
      const Duration(days: 30),
      const Duration(days: 365),
    ];

    final currentPeriod = periods[_selectedRankingType];
    final titles = ['日榜', '周榜', '月榜', '年榜'];
    final sortTitles = ['按歌曲', '按作曲家', '按专辑'];

    // 根据排序类型获取不同的列表
    dynamic currentList;
    switch (_selectedSortType) {
      case 0: // 按歌曲
        currentList = provider.getTopList(period: currentPeriod, limit: 10);
        break;
      case 1: // 按作曲家
        currentList = provider.getArtistTopList(period: currentPeriod, limit: 10);
        break;
      case 2: // 按专辑
        currentList = provider.getAlbumTopList(period: currentPeriod, limit: 10);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '播放排行',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final isSelected = index == _selectedRankingType;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRankingType = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final isSelected = index == _selectedSortType;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSortType = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      sortTitles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      return _buildRankingItem(context, currentList[index], index + 1, _selectedSortType);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(BuildContext context, dynamic item, int rank, int sortType) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? Colors.grey;
    }

    String title;
    String subtitle;
    int playCount;

    if (sortType == 0) {
      // 按歌曲
      title = item.title;
      subtitle = item.artist;
      playCount = item.playCount;
    } else if (sortType == 1) {
      // 按作曲家
      title = item.key;
      subtitle = '作曲家';
      playCount = item.value;
    } else {
      // 按专辑
      title = item.key;
      subtitle = '专辑';
      playCount = item.value;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$playCount次',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
