class Playlist {
  final String id;
  final String name;
  final String imageUrl;
  final String ownerName;
  final int tracksCount;

  Playlist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerName,
    required this.tracksCount,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    // 獲取封面圖像URL，如果有的話
    String imageUrl = 'https://via.placeholder.com/60';
    if (json['images'] != null && json['images'].isNotEmpty) {
      imageUrl = json['images'][0]['url'];
    }

    return Playlist(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      ownerName: json['owner']['display_name'] ?? 'Unknown',
      tracksCount: json['tracks']['total'] ?? 0,
    );
  }
}
