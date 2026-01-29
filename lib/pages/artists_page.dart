
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_icons.dart';
import '../providers/music_provider.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({Key? key}) : super(key: key);

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
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
                Icon(AppIcons.mic, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
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
          // 艺术家列表
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final artists = musicProvider.artists;

                if (artists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.mic,
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

                return ListView.builder(
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    final artistMusics = musicProvider.getMusicByArtist(artist);

                    // 艺术家首字母
                    String initial = artist.isNotEmpty ? artist[0].toUpperCase() : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
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
                          AppIcons.arrowDown,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        ),
                        onTap: () {
                          // TODO: 显示艺术家详情
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
