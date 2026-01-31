
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/music_scanner_service.dart';

/// 专辑页面播放器辅助类
class AlbumsPagePlayerHelper {
  /// 播放专辑中的歌曲
  static void playAlbum(BuildContext context, String albumName, List<MusicInfo> albumSongs) {
    debugPrint('=== AlbumsPagePlayerHelper.playAlbum 被调用 ===');
    debugPrint('专辑名称: $albumName');
    debugPrint('歌曲数量: ${albumSongs.length}');

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    debugPrint('获取PlayerProvider成功');

    if (albumSongs.isEmpty) {
      debugPrint('错误: 专辑中没有歌曲');
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
    debugPrint('歌曲排序完成');

    // 检查是否需要更新播放列表
    final currentPlaylist = playerProvider.playlist;
    final currentSource = playerProvider.playlistSource;
    final currentIdentifier = playerProvider.sourceIdentifier;
    final needsUpdate = currentPlaylist.length != sortedSongs.length ||
        currentSource != PlaylistSource.album ||
        currentIdentifier != albumName;

    debugPrint('当前播放列表长度: ${currentPlaylist.length}');
    debugPrint('当前播放来源: $currentSource');
    debugPrint('当前标识符: $currentIdentifier');
    debugPrint('是否需要更新播放列表: $needsUpdate');

    // 只在需要时更新播放列表
    if (needsUpdate) {
      debugPrint('更新播放列表...');
      playerProvider.setPlaylist(
        musicList: sortedSongs,
        source: PlaylistSource.album,
        identifier: albumName,
        startIndex: 0,
      );
      debugPrint('播放列表更新完成');
    }

    // 播放第一首歌曲
    debugPrint('准备播放歌曲...');
    playerProvider.playAtIndex(0);
    debugPrint('playAtIndex调用完成');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始播放专辑: $albumName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 播放专辑中的指定歌曲
  static void playSongInAlbum(
    BuildContext context,
    String albumName,
    List<MusicInfo> albumSongs,
    int songIndex,
  ) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (songIndex < 0 || songIndex >= albumSongs.length) {
      return;
    }

    // 按音轨号排序专辑歌曲
    final sortedSongs = List<MusicInfo>.from(albumSongs);
    sortedSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    // 找到指定歌曲在排序后列表中的索引
    final sortedIndex = sortedSongs.indexWhere(
      (song) => song.id == albumSongs[songIndex].id,
    );

    // 检查是否需要更新播放列表
    final currentPlaylist = playerProvider.playlist;
    final currentSource = playerProvider.playlistSource;
    final currentIdentifier = playerProvider.sourceIdentifier;
    final needsUpdate = currentPlaylist.length != sortedSongs.length ||
        currentSource != PlaylistSource.album ||
        currentIdentifier != albumName;

    // 只在需要时更新播放列表
    if (needsUpdate) {
      playerProvider.setPlaylist(
        musicList: sortedSongs,
        source: PlaylistSource.album,
        identifier: albumName,
        startIndex: sortedIndex,
      );
    }

    // 播放选中的歌曲
    playerProvider.playAtIndex(sortedIndex);
  }

  /// 将专辑歌曲添加到播放列表
  static void addAlbumToPlaylist(
    BuildContext context,
    String albumName,
    List<MusicInfo> albumSongs,
  ) {
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

    // 添加到播放列表
    playerProvider.addToPlaylist(sortedSongs);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将专辑 "$albumName" 添加到播放列表'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
