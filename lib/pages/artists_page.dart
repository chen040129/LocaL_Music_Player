
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/music_provider.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({Key? key}) : super(key: key);

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
  
  // 搜索状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ExpansionTile(
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
                            trailing: Icon(
                              CupertinoIcons.chevron_down,
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            ),
                            onExpansionChanged: (isExpanded) {
                              setState(() {
                                if (isExpanded) {
                                  _expandedArtists.add(artist);
                                } else {
                                  _expandedArtists.remove(artist);
                                }
                              });
                            },
                            initiallyExpanded: _expandedArtists.contains(artist),
                            children: [
                              // 显示艺术家的歌曲
                              ...artistMusics.map((music) {
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
                                  trailing: Text(
                                    _formatDuration(music.duration),
                                    style: TextStyle(
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    // TODO: 播放音乐
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                    // 字母索引栏（只在按名称排序时显示）
                    if (_sortBy == 'name')
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
