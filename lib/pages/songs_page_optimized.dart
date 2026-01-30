// 优化后的歌曲页面 - 添加缓存机制和性能优化
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../constants/app_icons.dart';
import '../providers/music_provider.dart';
import '../services/music_scanner_service.dart';
import '../models/playlist_model.dart';

class SongsPageOptimized extends StatefulWidget {
  const SongsPageOptimized({Key? key}) : super(key: key);

  @override
  State<SongsPageOptimized> createState() => _SongsPageOptimizedState();
}

class _SongsPageOptimizedState extends State<SongsPageOptimized> {
  // 排序方式
  String _sortBy = 'default'; // default, title, artist, album, duration
  bool _isAscending = true;
  final ItemScrollController _scrollController = ItemScrollController();
  final List<String> _alphabet = [
    '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
  ];
  // 搜索状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 拼音缓存
  final Map<String, String> _pinyinCache = {};

  // 缓存排序后的歌曲列表
  List<MusicInfo>? _cachedSortedSongs;
  String? _lastSortBy;
  bool? _lastIsAscending;

  // 缓存过滤后的歌曲列表
  List<MusicInfo>? _cachedFilteredSongs;
  String? _lastSearchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    _pinyinCache.clear();
    super.dispose();
  }

  /// 获取拼音（带缓存）
  String _getPinyin(String text) {
    if (_pinyinCache.containsKey(text)) {
      return _pinyinCache[text]!;
    }
    final pinyin = PinyinHelper.getPinyinE(text, format: PinyinFormat.WITHOUT_TONE).toUpperCase();
    _pinyinCache[text] = pinyin;
    return pinyin;
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

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// 随机播放
  void _playRandomSong(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    if (musicProvider.musicList.isEmpty) return;

    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % musicProvider.musicList.length;
    _scrollToIndex(index);

    // TODO: 实际播放音乐
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('播放: ${musicProvider.musicList[index].title}'),
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
                          ? const Icon(Icons.check, color: Colors.green)
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
                      content: Text('已创建歌单 "$playlistName" 并添加歌曲'),
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
                Icon(CupertinoIcons.music_note, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '歌曲',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                    CupertinoIcons.shuffle,
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
                              // 搜索时清除缓存
                              if (value.isEmpty) {
                                _cachedFilteredSongs = null;
                              }
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
                              _cachedFilteredSongs = null;
                            });
                          },
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
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
                      // 排序改变时清除缓存
                      _cachedSortedSongs = null;
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
                if (musicProvider.musicList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.music_note,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无歌曲',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '扫描音乐后将自动显示歌曲',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 获取或计算排序后的歌曲列表
                List<MusicInfo> sortedSongs;

                // 检查是否可以使用缓存的排序结果
                if (_cachedSortedSongs != null && 
                    _lastSortBy == _sortBy && 
                    _lastIsAscending == _isAscending &&
                    _searchQuery.isEmpty) {
                  sortedSongs = _cachedSortedSongs!;
                } else {
                  sortedSongs = List.from(musicProvider.musicList);

                  // 根据排序方式排序
                  switch (_sortBy) {
                    case 'title':
                      sortedSongs.sort((a, b) {
                        final aPinyin = _getPinyin(a.title);
                        final bPinyin = _getPinyin(b.title);
                        return _isAscending ? aPinyin.compareTo(bPinyin) : bPinyin.compareTo(aPinyin);
                      });
                      break;
                    case 'artist':
                      sortedSongs.sort((a, b) {
                        final aPinyin = _getPinyin(a.artist);
                        final bPinyin = _getPinyin(b.artist);
                        return _isAscending ? aPinyin.compareTo(bPinyin) : bPinyin.compareTo(aPinyin);
                      });
                      break;
                    case 'album':
                      sortedSongs.sort((a, b) {
                        final aPinyin = _getPinyin(a.album);
                        final bPinyin = _getPinyin(b.album);
                        return _isAscending ? aPinyin.compareTo(bPinyin) : bPinyin.compareTo(aPinyin);
                      });
                      break;
                    case 'duration':
                      sortedSongs.sort((a, b) {
                        return _isAscending 
                            ? a.duration.compareTo(b.duration) 
                            : b.duration.compareTo(a.duration);
                      });
                      break;
                    case 'default':
                    default:
                      // 默认按文件路径排序
                      sortedSongs.sort((a, b) => a.filePath.compareTo(b.filePath));
                      break;
                  }

                  // 缓存排序结果
                  if (_searchQuery.isEmpty) {
                    _cachedSortedSongs = sortedSongs;
                    _lastSortBy = _sortBy;
                    _lastIsAscending = _isAscending;
                  }
                }

                // 根据搜索查询过滤歌曲列表
                if (_searchQuery.isNotEmpty) {
                  // 检查是否可以使用缓存的过滤结果
                  if (_cachedFilteredSongs != null && _lastSearchQuery == _searchQuery) {
                    // 使用缓存的过滤结果
                  } else {
                    final searchLower = _searchQuery.toLowerCase();
                    sortedSongs = sortedSongs.where((music) {
                      return music.title.toLowerCase().contains(searchLower) ||
                          music.artist.toLowerCase().contains(searchLower) ||
                          music.album.toLowerCase().contains(searchLower);
                    }).toList();

                    // 缓存过滤结果
                    _cachedFilteredSongs = sortedSongs;
                    _lastSearchQuery = _searchQuery;
                  }
                }

                return Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: _scrollController,
                      itemCount: sortedSongs.length,
                      itemBuilder: (context, index) {
                        final music = sortedSongs[index];

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
                            '${music.artist} · ${music.album}',
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 音质标识
                              if (music.quality != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: music.quality == 'HR'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    music.quality!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: music.quality == 'HR'
                                          ? Colors.orange[700]
                                          : Colors.green[700],
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
                                  Icons.playlist_add,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  size: 20,
                                ),
                                onPressed: () {
                                  _showAddToPlaylistDialog(music.id);
                                },
                                tooltip: '添加到歌单',
                              ),
                            ],
                          ),
                          onTap: () {
                            // TODO: 播放音乐
                          },
                        );
                      },
                    ),
                    // 字母索引栏（只在按标题排序时显示）
                    if (_sortBy == 'title' || _sortBy == 'default')
                      Positioned(
                        right: 0,
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
                              final hasSongs = sortedSongs.any((music) {
                                final pinyin = _getPinyin(music.title);
                                if (letter == '0') {
                                  return RegExp(r'^[0-9]').hasMatch(music.title);
                                } else if (letter == '#') {
                                  return !RegExp(r'^[A-Z0-9]').hasMatch(pinyin);
                                } else {
                                  return pinyin.startsWith(letter);
                                }
                              });

                              return GestureDetector(
                                onTap: () {
                                  // 滚动到对应字母的位置
                                  final targetIndex = sortedSongs.indexWhere((music) {
                                    final pinyin = _getPinyin(music.title);
                                    if (letter == '0') {
                                      return RegExp(r'^[0-9]').hasMatch(music.title);
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
}
