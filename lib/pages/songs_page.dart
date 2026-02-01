
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../constants/app_icons.dart';
import '../constants/app_pages.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../services/music_scanner_service.dart';
import '../models/playlist_model.dart';
import '../providers/navigation_provider.dart';
import '../widgets/mask_card.dart';

class SongsPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const SongsPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  // 排序方式
  String _sortBy = 'default'; // default, title, artist, album, duration
  bool _isAscending = true;
  // 标题悬停状态
  bool _isTitleHovered = false;
  final ItemScrollController _scrollController = ItemScrollController();
  final List<String> _alphabet = [
    '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
  ];
  // 搜索状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 悬停和点击状态
  int _hoveredIndex = -1;
  int _touchedIndex = -1;

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
                      // 通知父组件展开侧边栏并导航到歌曲页面
                      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                      navigationProvider.changePage(AppPage.songs);
                      // 需要父组件实现展开侧边栏的逻辑
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
                            CupertinoIcons.music_note, 
                            color: _isTitleHovered 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '歌曲',
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
                Consumer<MusicProvider>(
                  builder: (context, musicProvider, child) {
                    return Text(
                      ' ${musicProvider.musicList.length}',
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // 随机播放按钮
                IconButton(
                  icon: Icon(
                    AppIcons.shuffle,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  onPressed: () {
                    _playRandomSong(context);
                  },
                  tooltip: '随机播放',
                ),
                const SizedBox(width: 8),
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
                        CupertinoIcons.search,
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
                    CupertinoIcons.arrow_up_arrow_down,
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
                      value: 'default',
                      child: Text('默认排序'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'title',
                      child: Text('按标题排序'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'artist',
                      child: Text('按艺术家排序'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'album',
                      child: Text('按专辑排序'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'duration',
                      child: Text('按时长排序'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'asc',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrow_up, size: 16),
                          const SizedBox(width: 8),
                          const Text('升序'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'desc',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrow_down, size: 16),
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
          // 歌曲列表
          Expanded(
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
                  case 'artist':
                    musicList.sort((a, b) {
                      final aPinyin = PinyinHelper.getPinyinE(a.artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      final bPinyin = PinyinHelper.getPinyinE(b.artist, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      return _isAscending
                          ? aPinyin.compareTo(bPinyin)
                          : bPinyin.compareTo(aPinyin);
                    });
                    break;
                  case 'album':
                    musicList.sort((a, b) {
                      final aPinyin = PinyinHelper.getPinyinE(a.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      final bPinyin = PinyinHelper.getPinyinE(b.album, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                      return _isAscending
                          ? aPinyin.compareTo(bPinyin)
                          : bPinyin.compareTo(aPinyin);
                    });
                    break;
                  case 'duration':
                    musicList.sort((a, b) => _isAscending 
                        ? a.duration.compareTo(b.duration) 
                        : b.duration.compareTo(a.duration));
                    break;
                  default:
                    // 默认排序，不做处理
                    break;
                }

                // 根据搜索查询过滤音乐列表
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  musicList = musicList.where((music) {
                    return music.title.toLowerCase().contains(searchLower) ||
                           music.artist.toLowerCase().contains(searchLower) ||
                           music.album.toLowerCase().contains(searchLower);
                  }).toList();
                }

                if (musicList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? CupertinoIcons.search
                              : CupertinoIcons.music_note,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? '未找到匹配的歌曲' : '暂无歌曲',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '尝试使用其他关键词搜索'
                              : '点击侧边栏的"扫描音乐"按钮添加音乐',
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
                      itemCount: musicList.length,
                      itemBuilder: (context, index) {
                        final music = musicList[index];
                        final isHovered = index == _hoveredIndex;
                        final isTouched = index == _touchedIndex;

                        // 使用保存的封面颜色
                        final animationColor = music.coverColor != null 
                            ? Color(music.coverColor!)
                            : Theme.of(context).colorScheme.primary;

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
                                _touchedIndex = isTouched ? -1 : index;
                              });
                            },
                            child: MaskCard(
                              isSelected: isTouched,
                              isHovered: isHovered,
                              accentColor: animationColor,
                              child: ListTile(
                            leading: music.coverArt != null
                                ? Image.memory(
                                    music.coverArt!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        AppIcons.musicNote,
                                        size: 56,
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                      );
                                    },
                                  )
                                : Icon(
                                    AppIcons.musicNote,
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
                              // 播放选中的音乐
                              final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

                              // 设置播放列表（使用当前排序后的列表）
                              playerProvider.setPlaylist(
                                musicList: musicList,
                                source: PlaylistSource.all,
                                startIndex: index,
                              );

                              // 播放指定索引的音乐
                              playerProvider.playAtIndex(index);
                            },
                          ),
                          ),
                          ),
                        );
                      },
                    ),
                    // 字母索引栏（只在按标题或艺术家排序时显示）
                    if (_sortBy == 'title' || _sortBy == 'artist')
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
                              // 检查是否有以该字母开头的歌曲
                              final hasSongs = musicList.any((music) {
                                final text = _sortBy == 'title' 
                                    ? music.title 
                                    : music.artist;
                                final pinyin = PinyinHelper.getPinyinE(text, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                if (letter == '0') {
                                  return RegExp(r'^[0-9]').hasMatch(text);
                                } else if (letter == '#') {
                                  return !RegExp(r'^[A-Z0-9]').hasMatch(pinyin);
                                } else {
                                  return pinyin.startsWith(letter);
                                } 
                                        
                                        
                              });

                              return GestureDetector(
                                onTap: () {
                                  // 滚动到对应字母的位置
                                  final targetIndex = musicList.indexWhere((music) {
                                    final text = _sortBy == 'title' 
                                        ? music.title 
                                        : music.artist;
                                    final pinyin = PinyinHelper.getPinyinE(text, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
                                    if (letter == '0') {
                                  return RegExp(r'^[0-9]').hasMatch(text);
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
                                      fontSize: hasSongs ? 12 : 10,
                                      color: hasSongs 
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).iconTheme.color?.withOpacity(0.3),
                                      fontWeight: hasSongs ? FontWeight.bold : FontWeight.normal,
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

  /// 获取字符串的拼音首字母
  String _getPinyinFirstLetter(String text) {
    if (text.isEmpty) return '';
    // 获取拼音首字母
    final pinyin = PinyinHelper.getPinyinE(text, format: PinyinFormat.WITHOUT_TONE);
    return pinyin.isNotEmpty ? pinyin[0].toUpperCase() : '';
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

  /// 随机播放一首歌曲
  void _playRandomSong(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final musicList = musicProvider.musicList;
    
    if (musicList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有可播放的歌曲'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // 随机选择一首歌曲
    final randomIndex = (musicList.length * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor();
    final randomSong = musicList[randomIndex];
    
    // 这里应该调用播放器的播放方法，但由于项目中没有实现实际的播放功能，
    // 我们只显示一个提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('随机播放: ${randomSong.title} - ${randomSong.artist}'),
        duration: const Duration(seconds: 2),
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
                      // 可以在这里添加创建新歌单的逻辑
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
                          // 从歌单中移除
                          await playlistService.removeMusicFromPlaylist(playlist.id, musicId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已从 "${playlist.name}" 中移除'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          // 添加到歌单
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
                        // 使用NavigationProvider切换到艺术家页面
                        final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                        navigationProvider.navigateToArtist(music.artist);
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
                        CupertinoIcons.play_circle,
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
}

