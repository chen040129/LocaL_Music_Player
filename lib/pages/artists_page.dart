
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/music_provider.dart';
import '../models/playlist_model.dart';
import '../services/music_scanner_service.dart';
import '../providers/navigation_provider.dart';
import '../widgets/mask_card.dart';
import '../constants/app_icons.dart';

class ArtistsPage extends StatefulWidget {
  final String? navigateToArtist;

  const ArtistsPage({Key? key, this.navigateToArtist}) : super(key: key);

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  // 排序方式
  String _sortBy = 'name'; // name, count
  bool _isAscending = true;
  
  // 字母索引
  final ItemScrollController _scrollController = ItemScrollController();
  final List<String> _alphabet = [
    '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
  ];
  
  // 展开的艺术家
  final Set<String> _expandedArtists = <String>{};

  // 悬停和点击状态
  int _hoveredIndex = -1;
  int _touchedIndex = -1;
  
  // 搜索状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 如果有导航参数，延迟滚动到对应艺术家
    if (widget.navigateToArtist != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToArtist(widget.navigateToArtist!);
      });
    }
  }

  /// 获取主题色的相反颜色
  Color _getThemeOppositeColor(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    // 计算相反颜色
    return Color.fromARGB(
      primaryColor.alpha,
      255 - primaryColor.red,
      255 - primaryColor.green,
      255 - primaryColor.blue,
    );
  }
  
  /// 滚动到指定索引
  void _scrollToIndex(int index) {
    if (_scrollController.isAttached) {
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 滚动到指定艺术家
  void _scrollToArtist(String artistName) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final artists = musicProvider.artists;

    // 对艺术家进行排序
    List<String> sortedArtists = List.from(artists);
    switch (_sortBy) {
      case 'name':
        sortedArtists.sort((a, b) {
          final aPinyin = PinyinHelper.getPinyinE(a, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
          final bPinyin = PinyinHelper.getPinyinE(b, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
          return _isAscending ? aPinyin.compareTo(bPinyin) : bPinyin.compareTo(aPinyin);
        });
        break;
      case 'count':
        sortedArtists.sort((a, b) {
          final aCount = musicProvider.getMusicByArtist(a).length;
          final bCount = musicProvider.getMusicByArtist(b).length;
          return _isAscending ? aCount.compareTo(bCount) : bCount.compareTo(aCount);
        });
        break;
      default:
        break;
    }

    // 根据搜索查询过滤艺术家列表
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      sortedArtists = sortedArtists.where((artist) {
        return artist.toLowerCase().contains(searchLower);
      }).toList();
    }

    // 查找目标艺术家的索引
    final targetIndex = sortedArtists.indexOf(artistName);
    if (targetIndex != -1) {
      _scrollToIndex(targetIndex);
      // 展开该艺术家
      setState(() {
        _expandedArtists.add(artistName);
      });
    }
  }
  
  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 显示音乐详情对话框
  void _showMusicDetailDialog(MusicInfo music) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 歌曲卡片
                Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ListTile(
                    leading: music.coverArt != null
                        ? Image.memory(
                            music.coverArt!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                CupertinoIcons.music_note,
                                size: 56,
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                              );
                            },
                          )
                        : Icon(
                            CupertinoIcons.music_note,
                            size: 56,
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
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            // TODO: 跳转到艺术家页面
                          },
                          child: Text(
                            music.artist,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
                    trailing: Text(
                      _formatDuration(music.duration),
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // 操作按钮
                ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.person,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      title: const Text('跳转到艺术家'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: 跳转到艺术家页面并定位到对应艺术家
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.music_albums,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      title: const Text('跳转到专辑'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // 使用NavigationProvider切换到专辑页面
                        final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                        navigationProvider.navigateToAlbum(music.album);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        AppIcons.addCircled,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      title: const Text('添加到歌单'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showAddToPlaylistDialog(music.id);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        AppIcons.playCircle,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      title: const Text('下一首播放'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: 设置为下一首播放
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.music_note,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      title: const Text('歌曲信息'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showMusicInfoDialog(music);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示歌曲信息对话框
  void _showMusicInfoDialog(MusicInfo music) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: GestureDetector(
            onTap: () {
              // 复制所有信息
              String allInfo = '';
              allInfo += '标题: ${music.title}\n';
              allInfo += '艺术家: ${music.artist}\n';
              allInfo += '专辑: ${music.album}\n';
              allInfo += '时长: ${_formatDuration(music.duration)}\n';
              if (music.quality != null) {
                allInfo += '音质: ${music.quality!}\n';
              }
              allInfo += '文件路径: ${music.filePath}';

              Clipboard.setData(ClipboardData(text: allInfo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制所有歌曲信息'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('歌曲信息'),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCopyableInfoRow('标题', music.title),
                _buildCopyableInfoRow('艺术家', music.artist),
                _buildCopyableInfoRow('专辑', music.album),
                _buildCopyableInfoRow('时长', _formatDuration(music.duration)),
                if (music.quality != null) _buildCopyableInfoRow('音质', music.quality!),
                _buildCopyableInfoRow('文件路径', music.filePath),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  /// 构建可复制的信息行
  Widget _buildCopyableInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                // 复制到剪贴板
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已复制 $label'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示添加到歌单对话框
  void _showAddToPlaylistDialog(String musicId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<PlaylistService>(
          builder: (context, playlistService, child) {
            final playlists = playlistService.playlists;

            if (playlists.isEmpty) {
              return AlertDialog(
                title: const Text('添加到歌单'),
                content: const Text('暂无歌单，请先创建歌单'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCreatePlaylistDialog(musicId);
                    },
                    child: const Text('创建歌单'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('添加到歌单'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final isMusicInPlaylist = playlist.musicIds.contains(musicId);
                    return ListTile(
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.musicIds.length} 首歌曲'),
                      trailing: isMusicInPlaylist
                          ? Icon(AppIcons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        if (isMusicInPlaylist) {
                          await playlistService.removeMusicFromPlaylist(playlist.id, musicId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已从 "${playlist.name}" 中移除'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await playlistService.addMusicToPlaylist(playlist.id, musicId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已添加到 "${playlist.name}"'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示创建新歌单对话框
  void _showCreatePlaylistDialog(String musicId) {
    String playlistName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('创建新歌单'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入歌单名称',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              playlistName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (playlistName.isNotEmpty) {
                  final playlistService = Provider.of<PlaylistService>(context, listen: false);
                  final playlist = await playlistService.createPlaylist(playlistName);
                  await playlistService.addMusicToPlaylist(playlist.id, musicId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已创建歌单 "${playlistName}" 并添加歌曲'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
  
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
                Icon(CupertinoIcons.person, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '艺术家',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<MusicProvider>(
                  builder: (context, musicProvider, child) {
                    return Text(
                      ' ${musicProvider.artists.length}',
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const Spacer(),
                // 搜索框
                Container(
                  width: 200,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.search,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '搜索',
                            hintStyle: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: Icon(
                            AppIcons.clearCircledSolid,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                    const PopupMenuItem<String>(
                      value: 'name',
                      child: Text('按名称排序'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'count',
                      child: Text('按歌曲数量排序'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'asc',
                      child: Row(
                        children: [
                          Icon(AppIcons.arrowUpward, size: 16),
                          const SizedBox(width: 8),
                          const Text('升序'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'desc',
                      child: Row(
                        children: [
                          Icon(AppIcons.arrowDownward, size: 16),
                          const SizedBox(width: 8),
                          const Text('降序'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 艺术家列表
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final artists = musicProvider.artists;
                
                // 对艺术家进行排序
                List<String> sortedArtists = List.from(artists);
                switch (_sortBy) {
                  case 'name':
                    sortedArtists.sort((a, b) {
                      final aPinyin = PinyinHelper.getPinyinE(a, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      final bPinyin = PinyinHelper.getPinyinE(b, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      return _isAscending ? aPinyin.compareTo(bPinyin) : bPinyin.compareTo(aPinyin);
                    });
                    break;
                  case 'count':
                    sortedArtists.sort((a, b) {
                      final aCount = musicProvider.getMusicByArtist(a).length;
                      final bCount = musicProvider.getMusicByArtist(b).length;
                      return _isAscending ? aCount.compareTo(bCount) : bCount.compareTo(aCount);
                    });
                    break;
                  default:
                    break;
                }

                // 根据搜索查询过滤艺术家列表
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  sortedArtists = sortedArtists.where((artist) {
                    return artist.toLowerCase().contains(searchLower);
                  }).toList();
                }

                if (artists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无艺术家',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '扫描音乐后将自动显示艺术家',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: _scrollController,
                      itemCount: sortedArtists.length,
                      itemBuilder: (context, index) {
                        final artist = sortedArtists[index];
                        final artistMusics = musicProvider.getMusicByArtist(artist);

                        // 艺术家首字母
                        String initial = artist.isNotEmpty ? artist[0].toUpperCase() : '';

                        return MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredIndex = index;
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
                                _touchedIndex = _touchedIndex == index ? -1 : index;
                              });
                            },
                            child: MaskCard(
                              isSelected: _touchedIndex == index,
                              isHovered: _hoveredIndex == index,
                              accentColor: artistMusics.isNotEmpty && artistMusics.first.coverColor != null
                                  ? Color(artistMusics.first.coverColor!)
                                  : null,
                              child: Column(
                                children: [
                                  ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  artist,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${artistMusics.length} 首歌曲',
                                  style: TextStyle(
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                  ),
                                ),
                                trailing: AnimatedRotation(
                                  turns: _expandedArtists.contains(artist) ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    CupertinoIcons.chevron_down,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    if (_expandedArtists.contains(artist)) {
                                      _expandedArtists.remove(artist);
                                    } else {
                                      _expandedArtists.add(artist);
                                    }
                                    _touchedIndex = _expandedArtists.contains(artist) ? index : -1;
                                  });
                                },
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                height: _expandedArtists.contains(artist) ? artistMusics.length * 72.0 : 0,
                                child: _expandedArtists.contains(artist)
                                    ? ListView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: artistMusics.length,
                                        itemBuilder: (context, musicIndex) {
                                          final music = artistMusics[musicIndex];
                                          return ListTile(
                                            leading: music.coverArt != null
                                                ? Image.memory(
                                                    music.coverArt!,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        CupertinoIcons.music_note,
                                                        size: 48,
                                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    CupertinoIcons.music_note,
                                                    size: 48,
                                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                                  ),
                                            title: Text(
                                              music.title,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            subtitle: Text(
                                              music.album,
                                              style: TextStyle(
                                                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _formatDuration(music.duration),
                                                  style: TextStyle(
                                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(
                                                    CupertinoIcons.ellipsis,
                                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    _showMusicDetailDialog(music);
                                                  },
                                                  tooltip: '详细信息',
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              // TODO: 播放音乐
                                            },
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                            ),
                          ),
                        );
                      },
                    ),
                    // 字母索引栏（只在按名称排序时显示）
                    if (_sortBy == 'name')
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          color: Colors.transparent,
                          child: ListView.builder(
                            itemCount: _alphabet.length,
                            itemBuilder: (context, index) {
                              // 根据排序方式调整字母顺序
                              final alphabet = _isAscending
                                  ? _alphabet
                                  : _alphabet.reversed.toList();
                              final letter = alphabet[index];
                              // 检查是否有以该字母开头的艺术家
                              final hasArtists = sortedArtists.any((artist) {
                                final pinyin = PinyinHelper.getPinyinE(artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                if (letter == '0') {
                                  return RegExp(r'^[0-9]').hasMatch(artist);
                                } else if (letter == '#') {
                                  return !RegExp(r'^[A-Z0-9]').hasMatch(pinyin);
                                } else {
                                  return pinyin.startsWith(letter);
                                }
                              });

                              return GestureDetector(
                                onTap: () {
                                  // 滚动到对应字母的位置
                                  final targetIndex = sortedArtists.indexWhere((artist) {
                                    final pinyin = PinyinHelper.getPinyinE(artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                    if (letter == '0') {
                                      return RegExp(r'^[0-9]').hasMatch(artist);
                                    } else if (letter == '#') {
                                      return !RegExp(r'^[A-Z0-9]').hasMatch(pinyin);
                                    } else {
                                      return pinyin.startsWith(letter);
                                    }
                                  });

                                  if (targetIndex != -1) {
                                    _scrollToIndex(targetIndex);
                                  }
                                },
                                child: Container(
                                  height: 18,
                                  alignment: Alignment.center,
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: hasArtists ? 12 : 10,
                                      color: hasArtists
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).iconTheme.color?.withOpacity(0.3),
                                      fontWeight: hasArtists ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
