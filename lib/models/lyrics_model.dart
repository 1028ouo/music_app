class LyricsModel {
  final List<LyricLine> lines;
  final String title;
  final String artist;

  const LyricsModel({
    required this.lines,
    required this.title,
    required this.artist,
  });

  // 從LRC格式解析歌詞
  factory LyricsModel.fromLRC(String lrcContent, String title, String artist) {
    final lines = <LyricLine>[];
    final lrcLines = lrcContent.split('\n');

    for (var line in lrcLines) {
      if (line.isEmpty) continue;

      // 解析時間標記 [mm:ss.xx]
      final RegExp timeRegex = RegExp(r'\[(\d+):(\d+)\.(\d+)\]');
      final matches = timeRegex.allMatches(line);

      if (matches.isEmpty) continue;

      // 取得歌詞文本
      var text = line.replaceAll(timeRegex, '').trim();

      for (var match in matches) {
        if (match.groupCount >= 3) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final milliseconds =
              int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));

          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );

          lines.add(LyricLine(timestamp: timestamp, text: text));
        }
      }
    }

    // 按時間順序排序
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LyricsModel(
      lines: lines,
      title: title,
      artist: artist,
    );
  }

  // 獲取當前應該顯示的歌詞
  LyricLine? getCurrentLine(Duration position) {
    if (lines.isEmpty) return null;

    // 如果位置小於第一行的時間，返回第一行
    if (position < lines.first.timestamp) {
      return lines.first;
    }

    // 如果位置大於最後一行的時間，返回最後一行
    if (position > lines.last.timestamp) {
      return lines.last;
    }

    // 尋找當前位置對應的歌詞
    for (int i = 0; i < lines.length - 1; i++) {
      if (position >= lines[i].timestamp && position < lines[i + 1].timestamp) {
        return lines[i];
      }
    }

    return lines.last;
  }

  // 獲取即將顯示的歌詞（下一行）
  LyricLine? getNextLine(Duration position) {
    if (lines.isEmpty) return null;

    for (int i = 0; i < lines.length - 1; i++) {
      if (position >= lines[i].timestamp && position < lines[i + 1].timestamp) {
        return lines[i + 1];
      }
    }

    return null;
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}
