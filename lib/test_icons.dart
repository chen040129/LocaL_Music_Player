
import 'package:flutter/material.dart';

class TestIconsPage extends StatelessWidget {
  const TestIconsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图标测试'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Icon(Icons.album, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Icon(Icons.mic, size: 48, color: Colors.yellow),
            const SizedBox(height: 16),
            const Icon(Icons.folder, size: 48, color: Colors.purple),
            const SizedBox(height: 16),
            const Icon(Icons.playlist_play, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Icon(Icons.scanner, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Icon(Icons.library_music, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            const Icon(Icons.bar_chart, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            const Icon(Icons.settings, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Icon(Icons.info, size: 48, color: Colors.cyan),
            const SizedBox(height: 16),
            const Icon(Icons.menu_open, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Icon(Icons.menu, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Icon(Icons.repeat, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Icon(Icons.play_circle_filled, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Icon(Icons.skip_previous, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Icon(Icons.play_arrow, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Icon(Icons.pause, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Icon(Icons.skip_next, size: 48, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
