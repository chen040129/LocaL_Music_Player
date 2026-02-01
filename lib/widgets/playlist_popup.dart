import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/player_provider.dart';
import '../services/music_scanner_service.dart';

class PlaylistPopup extends StatefulWidget {
  const PlaylistPopup({Key? key}) : super(key: key);

  @override
  State<PlaylistPopup> createState() => _PlaylistPopupState();
}

class _PlaylistPopupState extends State<PlaylistPopup> {
  final ScrollController _scrollController = ScrollController();
  int _hoveredIndex = -1;
  int? _draggingIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final playlist = playerProvider.playlist;
        final currentIndex = playerProvider.currentIndex;
        final currentMusic = playerProvider.currentMusic;

        return Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.playlist,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '播放列表',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // 清空播放列表按钮
                    if (playlist.isNotEmpty)
                      IconButton(
                        icon: const Icon(AppIcons.delete, size: 18),
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('清空播放列表'),
                              content: const Text('确定要清空当前播放列表吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    playerProvider.clearPlaylist();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: '清空播放列表',
                      ),
                    // 关闭按钮
                    IconButton(
                      icon: const Icon(AppIcons.close, size: 18),
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                      onPressed: () => Navigator.pop(context),
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
              // 播放列表内容
              Expanded(
                child: playlist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.musicNote,
                              size: 64,
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '播放列表为空',
                              style: TextStyle(
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: playlist.length,
                        itemBuilder: (context, index) {
                          final music = playlist[index];
                          final isCurrent = index == currentIndex;
                          final isHovered = index == _hoveredIndex;

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
                            child: LongPressDraggable<int>(
                              data: index,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 400,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: animationColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: music.coverArt != null
                                              ? Image.memory(
                                                  music.coverArt!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  AppIcons.musicNote,
                                                  size: 24,
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color
                                                      ?.withOpacity(0.5),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              music.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: animationColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              music.artist,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .iconTheme
                                                    .color
                                                    ?.withOpacity(0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              childWhenDragging: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                ),
                              ),
                              onDragStarted: () {
                                setState(() {
                                  _draggingIndex = index;
                                });
                              },
                              onDragEnd: (_) {
                                setState(() {
                                  _draggingIndex = null;
                                });
                              },
                              child: DragTarget<int>(
                                onAcceptWithDetails: (details) {
                                  final fromIndex = details.data;
                                  if (fromIndex != index) {
                                    playerProvider.moveInPlaylist(fromIndex, index);
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final isDraggingOver = candidateData.isNotEmpty && candidateData.first != index;

                                  return GestureDetector(
                                    onTap: () {
                                      playerProvider.playAtIndex(index);
                                    },
                                    child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? animationColor.withOpacity(0.1)
                                      : (isHovered
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                          : Colors.transparent),
                                  border: isCurrent
                                      ? Border(
                                          left: BorderSide(
                                            color: animationColor,
                                            width: 3,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // 专辑封面
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: music.coverArt != null
                                            ? Image.memory(
                                                music.coverArt!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    AppIcons.musicNote,
                                                    size: 24,
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color
                                                        ?.withOpacity(0.5),
                                                  );
                                                },
                                              )
                                            : Icon(
                                                AppIcons.musicNote,
                                                size: 24,
                                                color: Theme.of(context)
                                                    .iconTheme
                                                    .color
                                                    ?.withOpacity(0.5),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 歌曲信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            music.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isCurrent
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isCurrent
                                                  ? animationColor
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            music.artist,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color
                                                  ?.withOpacity(0.7),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 播放状态图标
                                    if (isCurrent)
                                      Icon(
                                        playerProvider.isPlaying
                                            ? AppIcons.pause
                                            : AppIcons.playArrow,
                                        size: 20,
                                        color: animationColor,
                                      ),
                                    // 移除按钮
                                    if (isHovered && !isCurrent)
                                      IconButton(
                                        icon: const Icon(AppIcons.delete, size: 18),
                                        color: Theme.of(context)
                                            .iconTheme
                                            .color
                                            ?.withOpacity(0.5),
                                        onPressed: () {
                                          playerProvider.removeFromPlaylist(index);
                                        },
                                        tooltip: '从列表中移除',
                                      ),
                                  ],
                                ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // 底部信息
              if (playlist.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '共 ${playlist.length} 首歌曲',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        playerProvider.getPlayModeName(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
