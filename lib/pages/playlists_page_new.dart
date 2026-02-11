
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../models/playlist_model.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
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
        moveToTop: true,
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
        moveToTop: true,
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
  const PlaylistsPage({Key? key}) : super(key: key);

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlaylistModel? _selectedPlaylist;

  // 悬停和点击状态
  int _hoveredIndex = -1;
  int _touchedIndex = -1;

  // 按钮悬停状态
  bool _isBackHovered = false;
  bool _isAddHovered = false;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
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
                if (_selectedPlaylist != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isBackHovered = true),
                    onExit: (_) => setState(() => _isBackHovered = false),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlaylist = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedScale(
                          scale: _isBackHovered ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CupertinoIcons.back,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                Icon(AppIcons.playlist, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  _selectedPlaylist != null ? _selectedPlaylist!.name : '歌单',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedPlaylist == null)
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
                if (_selectedPlaylist == null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isAddHovered = true),
                    onExit: (_) => setState(() => _isAddHovered = false),
                    child: GestureDetector(
                      onTap: () {
                        _createPlaylist();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedScale(
                          scale: _isAddHovered ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            AppIcons.add,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_selectedPlaylist != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isAddHovered = true),
                    onExit: (_) => setState(() => _isAddHovered = false),
                    child: GestureDetector(
                      onTap: () {
                        _showAddMusicDialog();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedScale(
                          scale: _isAddHovered ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CupertinoIcons.add,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                    itemCount: playlistMusics.length,
                    itemBuilder: (context, index) {
                      final music = playlistMusics[index]!;
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
                                  _touchedIndex = isTouched ? -1 : index;
                                });

                                // 播放音乐
                                final musicProvider = Provider.of<MusicProvider>(context, listen: false);

                                // 获取歌单中的所有歌曲
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
                  itemCount: filteredPlaylists.length,
                  itemBuilder: (context, index) {
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

  void _showPlaylistDetail(PlaylistModel playlist) {
    setState(() {
      _selectedPlaylist = playlist;
    });
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

  /// 获取音质颜色
  Color _getQualityColor(String? quality) {
    if (quality == null) return Colors.grey;
    switch (quality.toUpperCase()) {
      case 'LOSSLESS':
      case 'FLAC':
        return Colors.purple;
      case 'HI-RES':
        return Colors.orange;
      case 'DSD':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
