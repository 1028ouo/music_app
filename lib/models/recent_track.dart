class RecentTrack {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String imageUrl;
  final String playedAt;
  final int durationMs;
  final String? previewUrl; // 添加預覽URL欄位

  RecentTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.imageUrl,
    required this.playedAt,
    required this.durationMs,
    this.previewUrl, // 可為null的預覽URL
  });

  factory RecentTrack.fromJson(Map<String, dynamic> json) {
    final track = json['track'];
    final album = track['album'];

    String imageUrl = 'https://via.placeholder.com/150';
    if (album['images'] != null && album['images'].isNotEmpty) {
      imageUrl = album['images'][0]['url'];
    }

    String artistId = '';
    if (track['artists'] != null && track['artists'].isNotEmpty) {
      artistId = track['artists'][0]['id'] ?? '';
    }

    return RecentTrack(
      id: track['id'] ?? '',
      title: track['name'] ?? 'Unknown Track',
      artist: track['artists'] != null && track['artists'].isNotEmpty
          ? track['artists'][0]['name']
          : 'Unknown Artist',
      artistId: artistId,
      imageUrl: imageUrl,
      playedAt: json['played_at'] ?? '',
      durationMs: track['duration_ms'] ?? 0,
      previewUrl: track['preview_url'], // 從API解析preview_url
    );
  }

  // 將毫秒轉換為格式化的時間字符串 (分:秒)
  String get formattedDuration {
    final int totalSeconds = (durationMs / 1000).round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // 檢查是否有預覽音頻
  bool get hasPreview => previewUrl != null && previewUrl!.isNotEmpty;
}
