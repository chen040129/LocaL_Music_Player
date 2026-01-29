
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/music_provider.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
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
                Icon(AppIcons.album, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '专辑',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 搜索按钮
                IconButton(
                  icon: Icon(
                    AppIcons.search,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // TODO: 实现搜索功能
                  },
                  tooltip: '搜索',
                ),
              ],
            ),
          ),
          // 专辑列表
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final albums = musicProvider.albums;

                if (albums.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.album,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无专辑',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '扫描音乐后将自动显示专辑',
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
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final albumMusics = musicProvider.getMusicByAlbum(album);
                    final coverArt = albumMusics.isNotEmpty ? albumMusics.first.coverArt : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: coverArt != null
                            ? Image.memory(
                                coverArt,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    AppIcons.album,
                                    size: 56,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  );
                                },
                              )
                            : Icon(
                                AppIcons.album,
                                size: 56,
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                              ),
                        title: Text(
                          album,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${albumMusics.length} 首歌曲',
                          style: TextStyle(
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                        ),
                        trailing: Icon(
                          AppIcons.arrowDown,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        ),
                        onTap: () {
                          // TODO: 显示专辑详情
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
}
