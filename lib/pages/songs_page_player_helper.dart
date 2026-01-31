
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../services/music_scanner_service.dart';

/// 歌曲页面播放器辅助类
class SongsPagePlayerHelper {
  /// 随机播放一首歌曲
  static void playRandomSong(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
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

    // 设置播放列表并播放
    playerProvider.setPlaylist(
      musicList: musicList,
      source: PlaylistSource.all,
      startIndex: randomIndex,
    );

    // 播放选中的歌曲
    playerProvider.playAtIndex(randomIndex);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('随机播放: ${musicList[randomIndex].title} - ${musicList[randomIndex].artist}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 播放指定索引的歌曲
  static void playSongAtIndex(BuildContext context, int index, List<MusicInfo> musicList) {
    debugPrint('=== SongsPagePlayerHelper.playSongAtIndex 被调用 ===');
    debugPrint('索引: $index');
    debugPrint('歌曲数量: ${musicList.length}');

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    debugPrint('获取PlayerProvider成功');

    if (index < 0 || index >= musicList.length) {
      debugPrint('错误: 索引超出范围');
      return;
    }

    // 检查是否需要更新播放列表
    final currentPlaylist = playerProvider.playlist;
    final currentSource = playerProvider.playlistSource;
    final needsUpdate = currentPlaylist.length != musicList.length ||
        currentSource != PlaylistSource.all;

    debugPrint('当前播放列表长度: ${currentPlaylist.length}');
    debugPrint('当前播放来源: $currentSource');
    debugPrint('是否需要更新播放列表: $needsUpdate');

    // 只在需要时更新播放列表
    if (needsUpdate) {
      debugPrint('更新播放列表...');
      playerProvider.setPlaylist(
        musicList: musicList,
        source: PlaylistSource.all,
        startIndex: index,
      );
      debugPrint('播放列表更新完成');
    }

    // 播放选中的歌曲
    debugPrint('准备播放歌曲...');
    playerProvider.playAtIndex(index);
    debugPrint('playAtIndex调用完成');
  }

  /// 播放专辑中的歌曲
  static void playAlbum(BuildContext context, String albumName, List<MusicInfo> albumSongs) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (albumSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('专辑中没有歌曲'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 按音轨号排序专辑歌曲
    final sortedSongs = List<MusicInfo>.from(albumSongs);
    sortedSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    // 设置播放列表并播放
    playerProvider.setPlaylist(
      musicList: sortedSongs,
      source: PlaylistSource.album,
      identifier: albumName,
      startIndex: 0,
    );

    // 播放第一首歌曲
    playerProvider.playAtIndex(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始播放专辑: $albumName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 播放艺术家的歌曲
  static void playArtist(BuildContext context, String artistName, List<MusicInfo> artistSongs) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (artistSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('艺术家没有歌曲'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 按专辑和音轨号排序艺术家歌曲
    final sortedSongs = List<MusicInfo>.from(artistSongs);
    sortedSongs.sort((a, b) {
      // 先按专辑排序
      final albumCompare = a.album.compareTo(b.album);
      if (albumCompare != 0) return albumCompare;
      // 同一专辑内按音轨号排序
      return a.trackNumber.compareTo(b.trackNumber);
    });

    // 设置播放列表并播放
    playerProvider.setPlaylist(
      musicList: sortedSongs,
      source: PlaylistSource.artist,
      identifier: artistName,
      startIndex: 0,
    );

    // 播放第一首歌曲
    playerProvider.playAtIndex(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始播放艺术家: $artistName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
