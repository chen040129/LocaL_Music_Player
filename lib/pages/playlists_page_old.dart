
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../models/playlist_model.dart';
import '../providers/music_provider.dart';
import '../services/music_scanner_service.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({Key? key}) : super(key: key);

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  // 搜索状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // 初始化时加载歌单数据
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
                Icon(AppIcons.playlist, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '歌单',
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
                // 创建歌单按钮
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
              ],
            ),
          ),
          // 歌单列表
          Expanded(
            child: Consumer<PlaylistService>(
              builder: (context, playlistService, child) {
                final playlists = playlistService.playlists;
                
                // 根据搜索查询过滤歌单列表
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
                          CupertinoIcons.search,
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
                  itemCount: filteredPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = filteredPlaylists[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          AppIcons.playlist,
                          color: Theme.of(context).colorScheme.primary,
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
                          _showPlaylistDetail(playlist);
                        },
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

  /// 创建歌单
  void _createPlaylist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String playlistName = '';
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
              onPressed: () {
                if (playlistName.isNotEmpty) {
                  final playlistService = Provider.of<PlaylistService>(context, listen: false);
                  playlistService.createPlaylist(playlistName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
  
  /// 重命名歌单
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
  
  /// 删除歌单
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
  
  /// 显示歌单详情
  void _showPlaylistDetail(PlaylistModel playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailPage(playlist: playlist),
      ),
    );
  }
}

/// 歌单详情页面
class PlaylistDetailPage extends StatefulWidget {
  final PlaylistModel playlist;
  
  const PlaylistDetailPage({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              _showAddMusicDialog();
            },
            tooltip: '添加音乐',
          ),
        ],
      ),
      body: Consumer2<PlaylistService, MusicProvider>(
        builder: (context, playlistService, musicProvider, child) {
          final playlist = playlistService.getPlaylistById(widget.playlist.id);
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
            itemCount: playlistMusics.length,
            itemBuilder: (context, index) {
              final music = playlistMusics[index]!;
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
                trailing: IconButton(
                  icon: Icon(
                    CupertinoIcons.delete,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onPressed: () {
                    _removeMusicFromPlaylist(music.id);
                  },
                  tooltip: '从歌单移除',
                ),
                onTap: () {
                  // TODO: 播放音乐
                },
              );
            },
          );
        },
      ),
    );
  }
  
  /// 显示添加音乐对话框
  void _showAddMusicDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMusicToPlaylistPage(playlistId: widget.playlist.id),
      ),
    );
  }
  
  /// 从歌单移除音乐
  void _removeMusicFromPlaylist(String musicId) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    playlistService.removeMusicFromPlaylist(widget.playlist.id, musicId);
  }
}
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加音乐'),
        actions: [
          TextButton(
            onPressed: _selectedMusicIds.isEmpty
                ? null
                : () {
                    _addSelectedMusic();
                  },
            child: const Text('添加'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索音乐',
                prefixIcon: const Icon(CupertinoIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid),
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
          // 音乐列表
          Expanded(
            child: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          // 根据搜索查询过滤音乐
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
          final playlist = playlistService.getPlaylistById(widget.playlist.id);
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
            itemCount: playlistMusics.length,
            itemBuilder: (context, index) {
              final music = playlistMusics[index]!;
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
                trailing: IconButton(
                  icon: Icon(
                    CupertinoIcons.delete,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onPressed: () {
                    _removeMusicFromPlaylist(music.id);
                  },
                  tooltip: '从歌单移除',
                ),
                onTap: () {
                  // TODO: 播放音乐
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 显示添加音乐对话框
  void _showAddMusicDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMusicToPlaylistPage(playlistId: widget.playlist.id),
      ),
    );
  }

  /// 从歌单移除音乐
  void _removeMusicFromPlaylist(String musicId) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    playlistService.removeMusicFromPlaylist(widget.playlist.id, musicId);
  }
}

/// 添加音乐到歌单页面
class AddMusicToPlaylistPage extends StatefulWidget {
  final String playlistId;

  const AddMusicToPlaylistPage({Key? key, required this.playlistId}) : super(key: key);

  @override
  State<AddMusicToPlaylistPage> createState() => _AddMusicToPlaylistPageState();
}

class _AddMusicToPlaylistPageState extends State<AddMusicToPlaylistPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加音乐'),
        actions: [
          TextButton(
            onPressed: _selectedMusicIds.isEmpty
                ? null
                : () {
                    _addSelectedMusic();
                  },
            child: const Text('添加'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索音乐',
                prefixIcon: const Icon(CupertinoIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid),
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
          // 音乐列表
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final allMusic = musicProvider.musicList;
                
                // 根据搜索查询过滤音乐
                List<MusicInfo> filteredMusic = allMusic;
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  filteredMusic = allMusic.where((music) {
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
    );
  }
  
  /// 添加选中的音乐到歌单
  void _addSelectedMusic() {
    // 使用传入的playlistId
    
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    for (final musicId in _selectedMusicIds) {
      playlistService.addMusicToPlaylist(widget.playlistId, musicId);
    }
    
    Navigator.of(context).pop(); // 返回歌单详情页
  }
}
}
