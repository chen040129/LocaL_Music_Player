import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';
import '../constants/app_pages.dart';
import '../services/music_scanner_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../common.dart' as common;

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

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 isExpanded 状态变化时，触发宽度动画
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _widthController.reverse(); // 展开：从0回到220
      } else {
        _widthController.forward(); // 收起：从220到0
      }
    }
  }

  /// 导航栏动画
  void _animateSidebar() {
    // 空实现，移除缩放动画
  }

  /// 切换导航栏展开/收起
  void _toggleSidebar() {
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        final currentWidth = _widthAnimation.value;
        // 计算透明度：宽度从220到60时，透明度从1.0到0.0
        final opacity = ((currentWidth - 60) / (220 - 60)).clamp(0.0, 1.0);
        return Container(
          width: currentWidth,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: ClipRect(
            child: Opacity(
              opacity: opacity,
              child: OverflowBox(
                maxWidth: 220,
                minWidth: 220,
                alignment: Alignment.centerLeft,
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
                    // 桌面歌词按钮 - 三态切换：关闭→解锁→上锁
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        // 确定当前状态：0=关闭, 1=解锁, 2=上锁
                        int lyricsState = 0;
                        if (settingsProvider.enableDesktopLyrics) {
                          lyricsState = settingsProvider.desktopLyricsLocked ? 2 : 1;
                        }

                        // 根据状态选择图标和颜色
                        IconData stateIcon;
                        Color stateColor;
                        String tooltip;
                        switch (lyricsState) {
                          case 0: // 关闭
                            stateIcon = Icons.lyrics_outlined;
                            stateColor = Theme.of(context).iconTheme.color ?? Colors.grey;
                            tooltip = '歌词已关闭（点击开启）';
                            break;
                          case 1: // 解锁
                            stateIcon = Icons.lock_open_rounded;
                            stateColor = Colors.blue;
                            tooltip = '歌词已解锁（点击锁定）';
                            break;
                          case 2: // 上锁
                            stateIcon = Icons.lock_rounded;
                            stateColor = Colors.orange;
                            tooltip = '歌词已锁定（点击解锁）';
                            break;
                          default:
                            stateIcon = Icons.lyrics_outlined;
                            stateColor = Theme.of(context).iconTheme.color ?? Colors.grey;
                            tooltip = '';
                        }

                        return Tooltip(
                          message: tooltip,
                          child: MouseRegion(
                            onEnter: (_) => setState(() {
                              _menuHoverStates['desktopLyrics'] = true;
                            }),
                            onExit: (_) => setState(() {
                              _menuHoverStates['desktopLyrics'] = false;
                            }),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () async {
                                  switch (lyricsState) {
                                    case 0: // 关闭 → 解锁（开启歌词）
                                      await settingsProvider.setEnableDesktopLyrics(true);
                                      await settingsProvider.setDesktopLyricsLocked(false);
                                      break;
                                    case 1: // 解锁 → 上锁
                                      await settingsProvider.setDesktopLyricsLocked(true);
                                      // 通知歌词窗口锁定（优先flutter_lyric，其次旧版）
                                      try {
                                        if (common.lyricsWindowControllerFlutterLyric != null) {
                                          await common.lyricsWindowControllerFlutterLyric!.invokeMethod('lock_lyrics');
                                        } else if (common.lyricsWindowController != null) {
                                          await common.lyricsWindowController!.invokeMethod('lock_lyrics');
                                        }
                                      } catch (e) {}
                                      break;
                                    case 2: // 上锁 → 解锁（不关闭歌词，先解锁）
                                      // 通知歌词窗口解锁（优先flutter_lyric，其次旧版）
                                      try {
                                        if (common.lyricsWindowControllerFlutterLyric != null) {
                                          await common.lyricsWindowControllerFlutterLyric!.invokeMethod('unlock');
                                        } else if (common.lyricsWindowController != null) {
                                          await common.lyricsWindowController!.invokeMethod('unlock');
                                        }
                                      } catch (e) {}
                                      await settingsProvider.setDesktopLyricsLocked(false);
                                      break;
                                  }
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: AnimatedScale(
                                    scale: (_menuHoverStates['desktopLyrics'] ?? false) ? _hoverScale : _normalScale,
                                    duration: _animationDuration,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(scale: animation, child: child);
                                      },
                                      child: Icon(
                                        stateIcon,
                                        key: ValueKey(lyricsState),
                                        color: stateColor,
                                        size: 24,
                                      ),
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
                            widget.onPageChanged(AppPage.dsp);
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
                ),  // Column 闭合
              ),  // OverflowBox 闭合
            ),  // Opacity 闭合
          ),  // ClipRect 闭合
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
