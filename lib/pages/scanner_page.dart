
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import '../constants/app_icons.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';
import '../services/music_scanner_service.dart';

class ScannerPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const ScannerPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MusicScannerService _musicScannerService = MusicScannerService();
  // 标题悬停状态
  bool _isTitleHovered = false;
  
  // 排序方式
  String _sortBy = 'custom'; // custom, title, filename, album, artist, size, year, folder, playCount
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部工具栏
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
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
                            AppIcons.scanner, 
                            color: _isTitleHovered 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '扫描音乐',
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
          );
            },
          ),
          // 扫描内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 114),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 扫描状态卡片
                  Card(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Consumer<MusicProvider>(
                        builder: (context, musicProvider, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    musicProvider.isScanning ? AppIcons.sync : AppIcons.checkCircle,
                                    color: musicProvider.isScanning ? Colors.blue : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    musicProvider.scanStatus,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (musicProvider.isScanning) ...[
                                // 进度条
                                Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: musicProvider.scanProgress,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(musicProvider.scanProgress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showScanLogDialog(context),
                                  icon: Icon(AppIcons.list),
                                  label: Text('查看扫描日志'),
                                ),
                              ],
                              if (musicProvider.scannedCount > 0) ...[
                                const SizedBox(height: 16),
                                Text(
                                  '已扫描 ${musicProvider.scannedCount} 首歌曲',
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 扫描按钮
                  Consumer<MusicProvider>(
                    builder: (context, musicProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: musicProvider.isScanning ? null : _scanMusic,
                          icon: Icon(AppIcons.scanner),
                          label: Text(musicProvider.isScanning ? '扫描中...' : '开始扫描'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 已扫描的文件夹列表
                  Text(
                    '已扫描的文件夹',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    child: Consumer<MusicProvider>(
                      builder: (context, musicProvider, child) {
                        final scannedFolders = musicProvider.scannedFolders;

                        return scannedFolders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      AppIcons.folder,
                                      size: 48,
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '暂无已扫描的文件夹',
                                      style: TextStyle(
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: scannedFolders.length,
                                itemBuilder: (context, index) {
                                  final folder = scannedFolders[index];
                                  return Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Icon(
                                        AppIcons.folder,
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                      ),
                                      title: Text(
                                        folder,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          AppIcons.deleteOutline,
                                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                        ),
                                        onPressed: () {
                                          musicProvider.removeFolder(index);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 扫描到的歌曲列表
                  Row(
                    children: [
                      Text(
                        '扫描到的歌曲',
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 排序按钮
                      PopupMenuButton<String>(
                        icon: Icon(
                          AppIcons.sort,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        ),
                        tooltip: '排序方式',
                        onSelected: (String value) {
                          setState(() {
                            if (value == 'asc' || value == 'desc') {
                              _isAscending = value == 'asc';
                            } else {
                              _sortBy = value;
                            }
                          });
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'custom',
                            child: Text(
                              '自定义排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'title',
                            child: Text(
                              '按标题排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'filename',
                            child: Text(
                              '按文件名排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'album',
                            child: Text(
                              '按专辑（音轨）排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'artist',
                            child: Text(
                              '按艺术家（专辑）排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'size',
                            child: Text(
                              '按大小排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'year',
                            child: Text(
                              '按年份排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'folder',
                            child: Text(
                              '按文件夹（标题）排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'playCount',
                            child: Text(
                              '按播放次数排序',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'asc',
                            child: Row(
                              children: [
                                Icon(AppIcons.arrowUpward, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                const SizedBox(width: 8),
                                Text(
                                  '升序',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'desc',
                            child: Row(
                              children: [
                                Icon(AppIcons.arrowDownward, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                const SizedBox(width: 8),
                                Text(
                                  '降序',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    child: Consumer<MusicProvider>(
                      builder: (context, musicProvider, child) {
                        List<MusicInfo> musicList = List.from(musicProvider.musicList);

                        // 根据排序方式对音乐列表进行排序
                        switch (_sortBy) {
                          case 'title':
                            musicList.sort((a, b) {
                              final aPinyin = PinyinHelper.getPinyinE(a.title, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              final bPinyin = PinyinHelper.getPinyinE(b.title, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              return _isAscending
                                  ? aPinyin.compareTo(bPinyin)
                                  : bPinyin.compareTo(aPinyin);
                            });
                            break;
                          case 'filename':
                            musicList.sort((a, b) {
                              final aFilename = File(a.filePath).uri.pathSegments.last;
                              final bFilename = File(b.filePath).uri.pathSegments.last;
                              return _isAscending
                                  ? aFilename.compareTo(bFilename)
                                  : bFilename.compareTo(aFilename);
                            });
                            break;
                          case 'album':
                            musicList.sort((a, b) {
                              final aPinyin = PinyinHelper.getPinyinE(a.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              final bPinyin = PinyinHelper.getPinyinE(b.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              int result = _isAscending
                                  ? aPinyin.compareTo(bPinyin)
                                  : bPinyin.compareTo(aPinyin);
                              
                              // 如果专辑相同，则按音轨号排序
                              if (result == 0) {
                                result = _isAscending
                                    ? a.trackNumber.compareTo(b.trackNumber)
                                    : b.trackNumber.compareTo(a.trackNumber);
                              }
                              return result;
                            });
                            break;
                          case 'artist':
                            musicList.sort((a, b) {
                              final aPinyin = PinyinHelper.getPinyinE(a.artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              final bPinyin = PinyinHelper.getPinyinE(b.artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                              int result = _isAscending
                                  ? aPinyin.compareTo(bPinyin)
                                  : bPinyin.compareTo(aPinyin);
                              
                              // 如果艺术家相同，则按专辑排序
                              if (result == 0) {
                                final aAlbumPinyin = PinyinHelper.getPinyinE(a.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                final bAlbumPinyin = PinyinHelper.getPinyinE(b.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                result = _isAscending
                                    ? aAlbumPinyin.compareTo(bAlbumPinyin)
                                    : bAlbumPinyin.compareTo(aAlbumPinyin);
                              }
                              return result;
                            });
                            break;
                          case 'size':
                            musicList.sort((a, b) => _isAscending
                                ? a.fileSize.compareTo(b.fileSize)
                                : b.fileSize.compareTo(a.fileSize));
                            break;
                          case 'year':
                            musicList.sort((a, b) => _isAscending
                                ? a.year.compareTo(b.year)
                                : b.year.compareTo(a.year));
                            break;
                          case 'folder':
                            musicList.sort((a, b) {
                              final aFolder = File(a.filePath).parent.path;
                              final bFolder = File(b.filePath).parent.path;
                              int result = _isAscending
                                  ? aFolder.compareTo(bFolder)
                                  : bFolder.compareTo(aFolder);
                              
                              // 如果文件夹相同，则按标题排序
                              if (result == 0) {
                                final aPinyin = PinyinHelper.getPinyinE(a.title, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                final bPinyin = PinyinHelper.getPinyinE(b.title, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                result = _isAscending
                                    ? aPinyin.compareTo(bPinyin)
                                    : bPinyin.compareTo(aPinyin);
                              }
                              return result;
                            });
                            break;
                          case 'playCount':
                            musicList.sort((a, b) => _isAscending
                                ? a.playCount.compareTo(b.playCount)
                                : b.playCount.compareTo(a.playCount));
                            break;
                          case 'custom':
                          default:
                            // 自定义排序，不做处理
                            break;
                        }

                        if (musicList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.musicNote,
                                  size: 48,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '暂无扫描到的歌曲',
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: musicList.length,
                          itemBuilder: (context, index) {
                            final music = musicList[index];
                            return Card(
                              color: Colors.transparent,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: music.coverArt != null
                                    ? Image.memory(
                                        music.coverArt!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            AppIcons.musicNote,
                                            size: 48,
                                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                          );
                                        },
                                      )
                                    : Icon(
                                        AppIcons.musicNote,
                                        size: 48,
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                      ),
                                title: Text(
                                  music.title,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      music.artist,
                                      style: TextStyle(
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      music.album,
                                      style: TextStyle(
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (music.quality != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getQualityColor(music.quality),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          music.quality!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(music.duration),
                                      style: TextStyle(
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 扫描音乐
  Future<void> _scanMusic() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      try {
        // 检查路径是否已经扫描过
        if (mounted) {
          final musicProvider = Provider.of<MusicProvider>(context, listen: false);

          if (musicProvider.scannedFolders.contains(selectedDirectory)) {
            // 显示确认对话框
            final shouldScan = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认重新扫描'),
                content: Text('该文件夹已经扫描过了，是否要重新扫描？\n\n路径：$selectedDirectory'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('重新扫描'),
                  ),
                ],
              ),
            );

            if (shouldScan != true) {
              return;
            }
          }

          await musicProvider.scanDirectory(selectedDirectory);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('扫描完成，共找到 ${musicProvider.scannedCount} 首新歌曲'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('扫描失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 显示扫描日志对话框
  void _showScanLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.list_bullet,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '扫描日志',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.xmark,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // 日志内容
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<MusicProvider>(
                      builder: (context, musicProvider, child) {
                        return StreamBuilder<String>(
                          stream: musicProvider.scanLogStream,
                          builder: (context, snapshot) {
                            return SingleChildScrollView(
                              child: Text(
                                snapshot.data ?? '等待扫描...',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// 获取音质颜色
  Color _getQualityColor(String? quality) {
    switch (quality) {
      case 'HR':
        return Colors.purple;
      case 'HQ':
        return Colors.blue;
      case 'SQ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
