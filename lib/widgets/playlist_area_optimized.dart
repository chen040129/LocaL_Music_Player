// 优化后的播放列表区域 - 使用AutomaticKeepAlive和const优化性能
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_icons.dart';

class PlaylistAreaOptimized extends StatelessWidget {
  final bool isSidebarExpanded;
  final int currentPlayingIndex;
  final Function(int) onSongTap;
  final List<Map<String, dynamic>> songs;

  const PlaylistAreaOptimized({
    Key? key,
    required this.isSidebarExpanded,
    required this.currentPlayingIndex,
    required this.onSongTap,
    this.songs = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部播放控制相关功能
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
                Icon(AppIcons.repeat, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '循环播放',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // 歌曲列表 - 使用ListView.builder优化性能
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              // 添加itemExtent提高滚动性能
              itemExtent: 80,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isPlaying = index == currentPlayingIndex;

                return _SongItem(
                  song: song,
                  isPlaying: isPlaying,
                  onTap: () => onSongTap(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个歌曲项 - 使用const和AutomaticKeepAlive优化性能
class _SongItem extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongItem({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPlaying ? 3 : 1,
      color: isPlaying
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 专辑封面
              _AlbumCover(song: song),
              const SizedBox(width: 16),
              // 歌曲信息
              Expanded(
                child: _SongInfo(song: song, isPlaying: isPlaying),
              ),
              // 音质标识
              if (song['quality'] != null)
                _QualityBadge(quality: song['quality']),
              const SizedBox(width: 12),
              // 播放状态图标
              Icon(
                AppIcons.playCircle,
                color: isPlaying
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color?.withOpacity(0.4),
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 专辑封面组件
class _AlbumCover extends StatelessWidget {
  final Map<String, dynamic> song;

  const _AlbumCover({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Icon(
          AppIcons.musicNote,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 32,
        ),
      ),
    );
  }
}

/// 歌曲信息组件
class _SongInfo extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;

  const _SongInfo({
    Key? key,
    required this.song,
    required this.isPlaying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song['title'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            color: isPlaying
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        _SongDetails(song: song),
      ],
    );
  }
}

/// 歌曲详情组件
class _SongDetails extends StatelessWidget {
  final Map<String, dynamic> song;

  const _SongDetails({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          song['artist'],
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '·',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          song['album'],
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// 音质标识组件
class _QualityBadge extends StatelessWidget {
  final String quality;

  const _QualityBadge({Key? key, required this.quality}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHR = quality == 'HR';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHR
            ? Colors.orange.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        quality,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isHR
              ? Colors.orange[700]
              : Colors.green[700],
        ),
      ),
    );
  }
}
