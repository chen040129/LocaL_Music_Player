import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';
import '../constants/app_pages.dart';
import '../services/music_scanner_service.dart';
import 'package:file_picker/file_picker.dart';

class Sidebar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(List<MusicInfo>)? onMusicScanned;
  final AppPage currentPage;
  final Function(AppPage) onPageChanged;

  const Sidebar({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
    this.onMusicScanned,
    required this.currentPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final MusicScannerService _musicScannerService = MusicScannerService();
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
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      width: widget.isExpanded ? 220 : 0,
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
                // 主题切换按钮
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
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
                // 音质设置按钮
                IconButton(
                  icon: Icon(
                    AppIcons.qualityHigh,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    // TODO: 实现音质设置功能
                  },
                  tooltip: '音质设置',
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
                  icon: AppIcons.playlist,
                  iconColor: Colors.blue,
                  title: '歌单',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.playlists,
                  onTap: () => widget.onPageChanged(AppPage.playlists),
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
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.scanner,
                  onTap: () => widget.onPageChanged(AppPage.scanner),
                ),

                _buildMenuItem(
                  context: context,
                  icon: AppIcons.chart,
                  iconColor: Colors.indigo,
                  title: '统计',
                  isExpanded: widget.isExpanded,
                  isSelected: widget.currentPage == AppPage.statistics,
                  onTap: () => widget.onPageChanged(AppPage.statistics),
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
                  iconColor: Colors.cyan,
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
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: isExpanded ? 12 : 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).brightness == Brightness.dark
                          ? iconColor.withOpacity(0.8)
                          : iconColor,
                  size: 24,
                ),
                if (isExpanded) ...[
                  SizedBox(width: isExpanded ? 16 : 0),
                  Flexible(
                    child: ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedOpacity(
                          opacity: isExpanded ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
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
