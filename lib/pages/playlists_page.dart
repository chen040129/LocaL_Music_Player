
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../models/playlist_model.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/music_scanner_service.dart';
import '../widgets/mask_card.dart';

/// 歌单页面播放器辅助类
class PlaylistsPagePlayerHelper {
  /// 播放歌单中的指定歌曲
  static void playSongInPlaylist(
    BuildContext context,
    PlaylistModel playlist,
    List<MusicInfo> playlistSongs,
    int songIndex,
  ) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (songIndex < 0 || songIndex >= playlistSongs.length) {
      return;
    }

    // 检查是否需要更新播放列表
    final currentPlaylist = playerProvider.playlist;
    final currentSource = playerProvider.playlistSource;
    final currentIdentifier = playerProvider.sourceIdentifier;
    final needsUpdate = currentPlaylist.length != playlistSongs.length ||
        currentSource != PlaylistSource.custom ||
        currentIdentifier != playlist.name;

    // 只在需要时更新播放列表
    if (needsUpdate) {
      playerProvider.setPlaylist(
        musicList: playlistSongs,
        source: PlaylistSource.custom,
        identifier: playlist.name,
        startIndex: songIndex,
      );
    }

    // 播放选中的歌曲
    playerProvider.playAtIndex(songIndex);
  }

  /// 播放整个歌单
  static void playPlaylist(
    BuildContext context,
    PlaylistModel playlist,
    List<MusicInfo> playlistSongs,
  ) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (playlistSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('歌单中没有歌曲'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 检查是否需要更新播放列表
    final currentPlaylist = playerProvider.playlist;
    final currentSource = playerProvider.playlistSource;
    final currentIdentifier = playerProvider.sourceIdentifier;
    final needsUpdate = currentPlaylist.length != playlistSongs.length ||
        currentSource != PlaylistSource.custom ||
        currentIdentifier != playlist.name;

    // 只在需要时更新播放列表
    if (needsUpdate) {
      playerProvider.setPlaylist(
        musicList: playlistSongs,
        source: PlaylistSource.custom,
        identifier: playlist.name,
        startIndex: 0,
      );
    }

    // 播放第一首歌曲
    playerProvider.playAtIndex(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始播放歌单: ${playlist.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class PlaylistsPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const PlaylistsPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlaylistModel? _selectedPlaylist;
  // 标题悬停状态
  bool _isTitleHovered = false;
  
  // 悬停和点击状态
  int _hoveredIndex = -1;
  int _touchedIndex = -1;

  // 性能优化：缓存常用常量
  static const _animationDuration = Duration(milliseconds: 200);
  static const _itemMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistService = Provider.of<PlaylistService>(context, listen: false);
      playlistService.loadPlaylists();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
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
                if (_selectedPlaylist != null)
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.back,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPlaylist = null;
                      });
                    },
                    tooltip: '返回',
                  ),
                MouseRegion(
                  onEnter: (_) => setState(() => _isTitleHovered = true),
                  onExit: (_) => setState(() => _isTitleHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      // 通知父组件展开侧边栏并导航到歌单页面
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
                            AppIcons.playlist, 
                            color: _isTitleHovered 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPlaylist != null ? _selectedPlaylist!.name : '歌单',
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
                if (_selectedPlaylist == null)
                  Container(
                    width: 200,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
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
                if (_selectedPlaylist == null)
                  IconButton(
                    icon: Icon(
                      AppIcons.add,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _createPlaylist();
                    },
                    tooltip: '创建歌单',
                  ),
                if (_selectedPlaylist != null)
                  IconButton(
                    icon: Icon(
                      Icons.color_lens,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _showColorPickerDialog();
                    },
                    tooltip: '选择歌单颜色',
                  ),
                if (_selectedPlaylist != null)
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.add,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _showAddMusicDialog();
                    },
                    tooltip: '添加音乐',
                  ),
              ],
            ),
          );
            },
          ),
          Expanded(
            child: Consumer2<PlaylistService, MusicProvider>(
              builder: (context, playlistService, musicProvider, child) {
                // 如果有选中的歌单，显示歌单详情
                if (_selectedPlaylist != null) {
                  final playlist = playlistService.getPlaylistById(_selectedPlaylist!.id);
                  if (playlist == null) {
                    return const Center(
                      child: Text('歌单不存在'),
                    );
                  }

                  final playlistMusics = playlist.musicIds
                      .map((id) => musicProvider.getMusicById(id))
                      .where((music) => music != null)
                      .toList();

                  if (playlistMusics.isEmpty) {
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
                            '点击右上角的"+"按钮添加歌曲',
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    itemCount: playlistMusics.length,
                    itemBuilder: (context, index) {
                      final music = playlistMusics[index]!;
                      
                      // 使用歌曲封面颜色
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
                        child: MaskCard(
                          isSelected: index == _touchedIndex,
                          isHovered: index == _hoveredIndex,
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
                                    CupertinoIcons.delete,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    playlistService.removeMusicFromPlaylist(playlist.id, music.id);
                                  },
                                  tooltip: '从歌单移除',
                                ),
                              ],
                            ),
                            onTap: () {
                              // 设置点击状态
                              setState(() {
                                _touchedIndex = _touchedIndex == index ? -1 : index;
                              });

                              // 播放音乐
                              final playlistMusics = playlist.musicIds
                                  .map((id) => musicProvider.getMusicById(id))
                                  .where((music) => music != null)
                                  .cast<MusicInfo>()
                                  .toList();

                              // 使用辅助类播放歌曲
                              PlaylistsPagePlayerHelper.playSongInPlaylist(
                                context,
                                playlist,
                                playlistMusics,
                                index,
                              );
                            },
                          ),
                        ),
                      );

                    },
                  );
                }

                // 如果没有选中的歌单，显示歌单列表
                final playlists = playlistService.playlists;

                List<PlaylistModel> filteredPlaylists = playlists;
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  filteredPlaylists = playlists.where((playlist) {
                    return playlist.name.toLowerCase().contains(searchLower);
                  }).toList();
                }

                if (playlists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.playlist,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无歌单',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击右上角的"+"按钮创建新歌单',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredPlaylists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.search,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未找到匹配的歌单',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemCount: filteredPlaylists.length + 1, // 添加一个额外的项作为底部占位
                  itemBuilder: (context, index) {
                    // 如果是最后一项，显示底部占位区域
                    if (index == filteredPlaylists.length) {
                      return const SizedBox(height: 90); // 底部占位区域高度
                    }

                    final playlist = filteredPlaylists[index];
                    final isHovered = index == _hoveredIndex;
                    final isTouched = index == _touchedIndex;

                    // 使用歌单颜色或默认主题颜色
                    final animationColor = playlist.color != null
                        ? Color(playlist.color!)
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
                            leading: Icon(
                              AppIcons.playlist,
                              color: animationColor,
                            ),
                            title: Text(
                              playlist.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist.musicIds.length} 首歌曲',
                              style: TextStyle(
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    AppIcons.playCircle,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    // 获取歌单中的所有歌曲
                                    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
                                    final playlistMusics = playlist.musicIds
                                        .map((id) => musicProvider.getMusicById(id))
                                        .where((music) => music != null)
                                        .cast<MusicInfo>()
                                        .toList();

                                    // 播放整个歌单
                                    PlaylistsPagePlayerHelper.playPlaylist(
                                      context,
                                      playlist,
                                      playlistMusics,
                                    );
                                  },
                                  tooltip: '播放歌单',
                                ),
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.pencil,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    _renamePlaylist(playlist);
                                  },
                                  tooltip: '重命名',
                                ),
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.delete,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    _deletePlaylist(playlist.id);
                                  },
                                  tooltip: '删除',
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedPlaylist = playlist;
                              });
                            },
                          ),
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
    );
  }

  void _createPlaylist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String playlistName = '';
        int? selectedColor;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('创建新歌单'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '请输入歌单名称',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      playlistName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('选择歌单颜色'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildColorOption(null, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.red.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.orange.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.yellow.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.green.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.teal.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.blue.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.indigo.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.purple.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                      _buildColorOption(Colors.pink.value, selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (playlistName.isNotEmpty) {
                      final playlistService = Provider.of<PlaylistService>(context, listen: false);
                      final playlist = PlaylistModel.create(playlistName, color: selectedColor);
                      playlistService.createPlaylist(playlist.name, musicIds: playlist.musicIds);
                      // 更新歌单颜色
                      if (selectedColor != null) {
                        playlistService.updatePlaylist(playlist.updateColor(selectedColor));
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 构建颜色选项
  Widget _buildColorOption(int? colorValue, int? selectedColor, Function(int?) onSelected) {
    return GestureDetector(
      onTap: () {
        onSelected(colorValue);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorValue != null ? Color(colorValue) : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == colorValue ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// 显示颜色选择对话框
  void _showColorPickerDialog() {
    if (_selectedPlaylist == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedColor = _selectedPlaylist!.color;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('选择歌单颜色'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorOption(null, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.red.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.orange.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.yellow.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.green.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.teal.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.blue.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.indigo.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.purple.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                  _buildColorOption(Colors.pink.value, selectedColor, (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final playlistService = Provider.of<PlaylistService>(context, listen: false);
                    playlistService.updatePlaylist(_selectedPlaylist!.updateColor(selectedColor));
                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _renamePlaylist(PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = playlist.name;
        return AlertDialog(
          title: const Text('重命名歌单'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入新的歌单名称',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: playlist.name),
            onChanged: (value) {
              newName = value;
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
              onPressed: () {
                if (newName.isNotEmpty && newName != playlist.name) {
                  final playlistService = Provider.of<PlaylistService>(context, listen: false);
                  playlistService.updatePlaylist(playlist.updateName(newName));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(String playlistId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个歌单吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final playlistService = Provider.of<PlaylistService>(context, listen: false);
                playlistService.deletePlaylist(playlistId);
                Navigator.of(context).pop();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMusicDialog() {
    if (_selectedPlaylist == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMusicToPlaylistDialog(playlistId: _selectedPlaylist!.id);
      },
    );
  }
}

class AddMusicToPlaylistDialog extends StatefulWidget {
  final String playlistId;

  const AddMusicToPlaylistDialog({Key? key, required this.playlistId}) : super(key: key);

  @override
  State<AddMusicToPlaylistDialog> createState() => _AddMusicToPlaylistDialogState();
}

class _AddMusicToPlaylistDialogState extends State<AddMusicToPlaylistDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMusicIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    '添加音乐',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selectedMusicIds.isEmpty
                        ? null
                        : () {
                            _addSelectedMusic();
                            Navigator.of(context).pop();
                          },
                    child: const Text('添加'),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.clear),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索音乐',
                  prefixIcon: const Icon(AppIcons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(AppIcons.clearCircledSolid),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer<MusicProvider>(
                builder: (context, musicProvider, child) {
                  List<MusicInfo> filteredMusic = musicProvider.musicList;
                  if (_searchQuery.isNotEmpty) {
                    final searchLower = _searchQuery.toLowerCase();
                    filteredMusic = musicProvider.musicList.where((music) {
                      return music.title.toLowerCase().contains(searchLower) ||
                          music.artist.toLowerCase().contains(searchLower) ||
                          music.album.toLowerCase().contains(searchLower);
                    }).toList();
                  }

                  if (filteredMusic.isEmpty) {
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
                            _searchQuery.isNotEmpty ? '未找到匹配的音乐' : '暂无音乐',
                            style: TextStyle(
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredMusic.length,
                    itemBuilder: (context, index) {
                      final music = filteredMusic[index];
                      final isSelected = _selectedMusicIds.contains(music.id);
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
                          '${music.artist} - ${music.album}',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMusicIds.add(music.id);
                              } else {
                                _selectedMusicIds.remove(music.id);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMusicIds.remove(music.id);
                            } else {
                              _selectedMusicIds.add(music.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSelectedMusic() {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    for (final musicId in _selectedMusicIds) {
      playlistService.addMusicToPlaylist(widget.playlistId, musicId);
    }
  }
}

/// 歌单列表项 - 独立Widget优化性能
class _PlaylistItem extends StatefulWidget {
  final PlaylistModel playlist;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlaylistItem({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<_PlaylistItem> {
  bool _isHovered = false;
  bool _isTouched = false;

  static const _animationDuration = Duration(milliseconds: 200);
  static const _itemMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    // 使用歌单颜色或默认主题颜色
    final animationColor = widget.playlist.color != null
        ? Color(widget.playlist.color!)
        : Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: _animationDuration,
          margin: _itemMargin,
          decoration: BoxDecoration(
            color: _isTouched || _isHovered
                ? animationColor.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: _borderRadius,
            border: _isTouched
                ? Border.all(color: animationColor, width: 2)
                : null,
            boxShadow: (_isTouched || _isHovered)
                ? [
                    BoxShadow(
                      color: animationColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            leading: Icon(
              AppIcons.playlist,
              color: animationColor,
            ),
            title: Text(
              widget.playlist.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${widget.playlist.musicIds.length} 首歌曲',
              style: TextStyle(
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    CupertinoIcons.pencil,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onPressed: widget.onRename,
                  tooltip: '重命名',
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.delete,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onPressed: widget.onDelete,
                  tooltip: '删除',
                ),
              ],
            ),
            onTap: () {
              setState(() => _isTouched = !_isTouched);
              widget.onTap();
            },
          ),
        ),
      ),
    );
  }
}

/// 歌单音乐列表项 - 独立Widget优化性能
class _PlaylistMusicItem extends StatefulWidget {
  final MusicInfo music;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistMusicItem({
    required this.music,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PlaylistMusicItem> createState() => _PlaylistMusicItemState();
}

class _PlaylistMusicItemState extends State<_PlaylistMusicItem> {
  bool _isHovered = false;
  bool _isTouched = false;

  static const _animationDuration = Duration(milliseconds: 200);
  static const _itemMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    // 使用歌曲封面颜色或默认主题颜色
    final animationColor = widget.music.coverColor != null
        ? Color(widget.music.coverColor!)
        : Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: _animationDuration,
          margin: _itemMargin,
          decoration: BoxDecoration(
            color: _isTouched || _isHovered
                ? animationColor.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: _borderRadius,
            border: _isTouched
                ? Border.all(color: animationColor, width: 2)
                : null,
            boxShadow: (_isTouched || _isHovered)
                ? [
                    BoxShadow(
                      color: animationColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            leading: widget.music.coverArt != null
                ? Image.memory(
                    widget.music.coverArt!,
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
              widget.music.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '${widget.music.artist} - ${widget.music.album}',
              style: TextStyle(
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(widget.music.duration),
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.delete,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onPressed: widget.onDelete,
                  tooltip: '从歌单移除',
                ),
              ],
            ),
            onTap: () {
              setState(() => _isTouched = !_isTouched);
              widget.onTap();
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
