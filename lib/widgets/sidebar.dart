import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';
import '../constants/app_pages.dart';
import '../services/music_scanner_service.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';

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

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  final MusicScannerService _musicScannerService = MusicScannerService();
  bool _isScanning = false;
  late AnimationController _widthController;
  late Animation<double> _widthAnimation;
  
  // 菜单项悬停状态
  final Map<String, bool> _menuHoverStates = {};
  
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _hoverScale = 1.2;
  static const double _normalScale = 1.0;

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
      final scannedMusic =
          await _musicScannerService.scanDirectory(selectedDirectory);

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
  void initState() {
    super.initState();
    _widthController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 220, end: 0).animate(
      CurvedAnimation(parent: _widthController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    super.dispose();
  }

  /// 导航栏动画
  void _animateSidebar() {
    // 空实现，移除缩放动画
  }

  /// 切换导航栏展开/收起
  void _toggleSidebar() {
    if (widget.isExpanded) {
      _widthController.forward();
    } else {
      _widthController.reverse();
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: Colors.transparent,
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
                        return MouseRegion(
                          onEnter: (_) => setState(() {
                            _menuHoverStates['theme'] = true;
                          }),
                          onExit: (_) => setState(() {
                            _menuHoverStates['theme'] = false;
                          }),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                themeProvider.toggleTheme();
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              child: Padding(
                                padding: EdgeInsets.zero,
                                child: AnimatedScale(
                                  scale: (_menuHoverStates['theme'] ?? false) ? _hoverScale : _normalScale,
                                  duration: _animationDuration,
                                  child: AnimatedSwitcher(
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
                                      key: ValueKey<bool>(
                                          themeProvider.isDarkMode),
                                      color: Theme.of(context).iconTheme.color,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // 音质设置按钮
                    MouseRegion(
                      onEnter: (_) => setState(() {
                        _menuHoverStates['quality'] = true;
                      }),
                      onExit: (_) => setState(() {
                        _menuHoverStates['quality'] = false;
                      }),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            OverlayEntry? overlayEntry;
                            overlayEntry = OverlayEntry(
                              builder: (context) => Positioned(
                                top: 50,
                                left: 20,
                                right: 20,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.inverseSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          AppIcons.qualityHigh,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '音效设置功能也许可能在后面版本推出',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onInverseSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            CupertinoIcons.clear,
                                            color: Theme.of(context).colorScheme.onInverseSurface,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            overlayEntry?.remove();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            Overlay.of(context).insert(overlayEntry!);

                            // 3秒后自动移除
                            Future.delayed(const Duration(seconds: 3), () {
                              overlayEntry?.remove();
                            });
                          },
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: AnimatedScale(
                              scale: (_menuHoverStates['quality'] ?? false) ? _hoverScale : _normalScale,
                              duration: _animationDuration,
                              child: Icon(
                                AppIcons.qualityHigh,
                                color: Theme.of(context).iconTheme.color,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
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
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.songs);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.album,
                      iconColor: Colors.red,
                      title: '专辑',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.albums,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.albums);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.mic,
                      iconColor: Colors.yellow,
                      title: '艺术家',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.artists,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.artists);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.playlist,
                      iconColor: Colors.blue,
                      title: '歌单',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.playlists,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.playlists);
                      },
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
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.scanner);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.chart,
                      iconColor: Colors.indigo,
                      title: '统计',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.statistics,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.statistics);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.settings,
                      iconColor: Colors.grey,
                      title: '设置',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.settings,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.settings);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: AppIcons.info,
                      iconColor: Colors.cyan,
                      title: '关于',
                      isExpanded: widget.isExpanded,
                      isSelected: widget.currentPage == AppPage.about,
                      onTap: () {
                        _animateSidebar();
                        widget.onPageChanged(AppPage.about);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    // 初始化悬停状态
    _menuHoverStates.putIfAbsent(title, () => false);
    
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return MouseRegion(
              onEnter: (_) => setState(() => _menuHoverStates[title] = true),
              onExit: (_) => setState(() => _menuHoverStates[title] = false),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(settings.borderRadius),
                  child: InkWell(
                    onTap: onTap ?? () {},
                    borderRadius: BorderRadius.circular(settings.borderRadius),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12, horizontal: isExpanded ? 12 : 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: _menuHoverStates[title]! ? _hoverScale : _normalScale,
                            duration: _animationDuration,
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? iconColor.withOpacity(0.8)
                                      : iconColor,
                              size: 24,
                            ),
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
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
          },
        ),
      ),
    );
  }
}
