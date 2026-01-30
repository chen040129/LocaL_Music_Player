// 优化后的侧边栏 - 减少不必要的重建
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';
import '../constants/app_pages.dart';
import '../services/music_scanner_service.dart';

class SidebarOptimized extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(List<MusicInfo>)? onMusicScanned;
  final AppPage currentPage;
  final Function(AppPage) onPageChanged;

  const SidebarOptimized({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
    this.onMusicScanned,
    required this.currentPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<SidebarOptimized> createState() => _SidebarOptimizedState();
}

class _SidebarOptimizedState extends State<SidebarOptimized> {
  bool _isScanning = false;

  /// 扫描音乐
  Future<void> _scanMusic() async {
    if (_isScanning) return;

    // 选择要扫描的目录
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    setState(() {
      _isScanning = true;
    });

    // 显示扫描中提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 16),
              Text('正在扫描音乐文件...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // 执行扫描
      final scannedMusic = await _musicScannerService.scanDirectory(selectedDirectory);

      // 通知父组件扫描完成
      if (widget.onMusicScanned != null) {
        widget.onMusicScanned!(scannedMusic);
      }

      // 显示扫描结果
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描完成，共找到 ${scannedMusic.length} 首音乐'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描失败: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isExpanded ? 240 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // 顶部工具栏
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 主题切换按钮 - 使用Selector减少重建
                Selector<ThemeProvider, bool>(
                  selector: (context, themeProvider) => themeProvider.isDarkMode,
                  builder: (context, isDarkMode, child) {
                    return IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isDarkMode ? AppIcons.sun : AppIcons.moon,
                          key: ValueKey<bool>(isDarkMode),
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      onPressed: () {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      },
                      tooltip: isDarkMode ? '切换到浅色主题' : '切换到深色主题',
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
                    widget.isExpanded ? AppIcons.sidebarLeft : AppIcons.sidebarRight,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: widget.onToggle,
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
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.songs,
                  onTap: () => widget.onPageChanged(AppPage.songs),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.album,
                  iconColor: Colors.red,
                  title: '专辑',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.albums,
                  onTap: () => widget.onPageChanged(AppPage.albums),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.mic,
                  iconColor: Colors.yellow,
                  title: '艺术家',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.artists,
                  onTap: () => widget.onPageChanged(AppPage.artists),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.folder,
                  iconColor: Colors.blue,
                  title: '文件夹',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.folders,
                  onTap: () => widget.onPageChanged(AppPage.folders),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.playlist,
                  iconColor: Colors.purple,
                  title: '歌单',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.playlists,
                  onTap: () => widget.onPageChanged(AppPage.playlists),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.scanner,
                  iconColor: Colors.orange,
                  title: '扫描音乐',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.scanner,
                  onTap: () => widget.onPageChanged(AppPage.scanner),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.library,
                  iconColor: Colors.cyan,
                  title: '音乐库',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.library,
                  onTap: () => widget.onPageChanged(AppPage.library),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.chartBar,
                  iconColor: Colors.indigo,
                  title: '统计',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.statistics,
                  onTap: () => widget.onPageChanged(AppPage.statistics),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.settings,
                  iconColor: Colors.grey,
                  title: '设置',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.settings,
                  onTap: () => widget.onPageChanged(AppPage.settings),
                ),
                _buildMenuItem(
                  context: context,
                  icon: AppIcons.info,
                  iconColor: Colors.grey,
                  title: '关于',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.about,
                  onTap: () => widget.onPageChanged(AppPage.about),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : iconColor.withOpacity(0.7),
                size: 20,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
