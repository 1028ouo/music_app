class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final int popularity;
  final List<String> genres;
  final int followers;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.popularity,
    required this.genres,
    required this.followers,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // 取得第一個圖片URL，如果存在的話
    String imageUrl = 'https://via.placeholder.com/150';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      imageUrl = json['images'][0]['url'];
    }

    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      popularity: json['popularity'] ?? 0,
      genres: json['genres'] != null ? List<String>.from(json['genres']) : [],
      followers: json['followers'] != null ? json['followers']['total'] : 0,
    );
  }
}
