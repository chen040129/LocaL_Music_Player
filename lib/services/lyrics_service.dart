import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/lyrics_model.dart';

class LyricsService {
  /// 从音乐文件所在目录加载歌词文件
  static Future<Lyrics?> loadLyricsForMusic(String musicFilePath) async {
    try {
      final directory = Directory(path.dirname(musicFilePath));
      final musicFileName = path.basenameWithoutExtension(musicFilePath);

      // 尝试查找同名的 .lrc 文件
      final lrcFiles = directory.listSync().whereType<File>().where((file) {
        final fileName = path.basename(file.path);
        final baseName = path.basenameWithoutExtension(file.path);
        return baseName.toLowerCase() == musicFileName.toLowerCase() &&
               fileName.toLowerCase().endsWith('.lrc');
      }).toList();

      if (lrcFiles.isNotEmpty) {
        final lrcContent = await lrcFiles.first.readAsString();
        return Lyrics.parseLrc(lrcContent);
      }

      return null;
    } catch (e) {
      print('加载歌词失败: $e');
      return null;
    }
  }

  /// 解析 LRC 格式歌词
  static Lyrics parseLrc(String lrcContent) {
    return Lyrics.parseLrc(lrcContent);
  }

  /// 获取默认歌词（当没有找到歌词文件时）
  static String getDefaultLyrics() {
    return '[00:00.00]暂无歌词\n[00:02.00]请在音乐文件同目录下\n[00:04.00]放置同名的 .lrc 歌词文件\n[00:06.00]例如：song.mp3 对应 song.lrc';
  }

  /// 将 Lyrics 对象转换为 LRC 格式字符串
  static String lyricsToLrc(Lyrics lyrics) {
    final buffer = StringBuffer();
    for (final line in lyrics.lines) {
      final minutes = line.time ~/ 60000;
      final seconds = (line.time % 60000) ~/ 1000;
      final milliseconds = line.time % 1000;
      final timeTag = '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}]';
      buffer.writeln('$timeTag${line.text}');
    }
    return buffer.toString();
  }

  /// 保存歌词到文件
  static Future<void> saveLyrics(String musicFilePath, String lrcContent) async {
    try {
      final directory = Directory(path.dirname(musicFilePath));
      final musicFileName = path.basenameWithoutExtension(musicFilePath);
      final lrcFilePath = path.join(directory.path, '$musicFileName.lrc');
      await File(lrcFilePath).writeAsString(lrcContent);
    } catch (e) {
      print('保存歌词失败: $e');
      rethrow;
    }
  }
}
