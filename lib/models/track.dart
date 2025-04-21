class Track {
  final String id;
  final String name;
  final String imageUrl;
  final int durationMs;
  final List<String> artistNames;
  final String? previewUrl; // 添加預覽URL欄位

  Track({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.durationMs,
    required this.artistNames,
    this.previewUrl, // 可為null的預覽URL
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    // 處理播放清單曲目的特殊情況，曲目資訊可能包裝在 track 欄位中
    final trackJson = json.containsKey('track') ? json['track'] : json;

    List<String> artists = [];
    if (trackJson['artists'] != null) {
      artists = (trackJson['artists'] as List)
          .map((artist) => artist['name'] as String)
          .toList();
    }

    String imageUrl = '';
    if (trackJson['album'] != null &&
        trackJson['album']['images'] != null &&
        (trackJson['album']['images'] as List).isNotEmpty) {
      imageUrl = trackJson['album']['images'][0]['url'];
    }

    return Track(
      id: trackJson['id'],
      name: trackJson['name'],
      imageUrl: imageUrl,
      durationMs: trackJson['duration_ms'],
      artistNames: artists,
      previewUrl: trackJson['preview_url'], // 從API解析preview_url
    );
  }

  String get artistsText => artistNames.join(', ');

  String get durationText {
    final int minutes = durationMs ~/ 60000;
    final int seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // 檢查是否有預覽音頻
  bool get hasPreview => previewUrl != null && previewUrl!.isNotEmpty;
}
