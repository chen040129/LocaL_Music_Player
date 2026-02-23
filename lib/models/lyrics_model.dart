/// 歌词行模型
class LyricsLine {
  final int time; // 时间，单位毫秒
  final String text; // 歌词文本

  LyricsLine({
    required this.time,
    required this.text,
  });

  @override
  String toString() => 'LyricsLine(time: $time, text: $text)';
}

/// 歌词模型
class Lyrics {
  final List<LyricsLine> lines;
  final String? source; // 歌词来源（lrc文件或内嵌）

  Lyrics({
    required this.lines,
    this.source,
  });

  /// 解析LRC格式歌词
  factory Lyrics.parseLrc(String lrcContent, {String? source}) {
    final lyricsLines = <LyricsLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          final time = minutes * 60000 + seconds * 1000 + milliseconds;
          lyricsLines.add(LyricsLine(time: time, text: text));
        }
      }
    }

    // 按时间排序
    lyricsLines.sort((a, b) => a.time.compareTo(b.time));

    return Lyrics(lines: lyricsLines, source: source ?? 'lrc');
  }

  /// 根据当前播放时间获取当前歌词行索引
  int getCurrentLineIndex(int currentTimeMs) {
    if (lines.isEmpty) return -1;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentTimeMs >= lines[i].time) {
        return i;
      }
    }

    return -1;
  }

  /// 获取当前歌词行
  LyricsLine? getCurrentLine(int currentTimeMs) {
    final index = getCurrentLineIndex(currentTimeMs);
    if (index >= 0 && index < lines.length) {
      return lines[index];
    }
    return null;
  }

  /// 获取下一行歌词
  LyricsLine? getNextLine(int currentTimeMs) {
    final index = getCurrentLineIndex(currentTimeMs);
    if (index >= 0 && index < lines.length - 1) {
      return lines[index + 1];
    }
    return null;
  }

  /// 获取上一行歌词
  LyricsLine? getPreviousLine(int currentTimeMs) {
    final index = getCurrentLineIndex(currentTimeMs);
    if (index > 0) {
      return lines[index - 1];
    }
    return null;
  }

  /// 判断是否有歌词
  bool get hasLyrics => lines.isNotEmpty;
}
