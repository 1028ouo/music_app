import 'package:flutter/material.dart';
import 'album_page.dart';
import 'artist_page.dart';
import 'now_playing_widget.dart';
import 'services/spotify_service.dart';
import 'models/artist.dart';
import 'models/playing_song.dart';
import 'models/recent_track.dart';
import 'models/playlist.dart';
import 'widgets/custom_bottom_navigation.dart'; // 新增導入自定義導航欄

// 修改全局變量，改為存儲完整的歌曲信息
final ValueNotifier<PlayingSong?> currentlyPlayingSong =
    ValueNotifier<PlayingSong?>(null);

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SpotifyService _spotifyService = SpotifyService();
  List<Artist> _artists = [];
  List<RecentTrack> _recentTracks = [];
  List<Playlist> _playlists = []; // 新增播放清單列表
  bool _isLoading = false;
  bool _isLoadingRecent = false;
  bool _isLoadingPlaylists = false; // 新增播放清單加載狀態

  @override
  void initState() {
    super.initState();
    _loadArtists();
    _loadRecentlyPlayed();
    _loadPlaylists(); // 初始化時加載播放清單
  }

  // 添加一個方法來處理Spotify API的調用
  Future<void> _refreshSpotifyToken(BuildContext context) async {
    try {
      await _spotifyService.refreshAccessToken();
      debugPrint('成功刷新令牌');
      _loadArtists(); // 刷新令牌後重新載入藝術家
    } catch (e) {
      debugPrint('刷新令牌時出錯: $e');
      // 可以在此處理錯誤，例如顯示一個Snackbar
    }
  }

  Future<void> _loadArtists() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 這裡使用您在API回應中提供的藝術家ID
      final List<String> artistIds = [
        '7tYKF4w9nC0nq9CsPZTHyP', // SZA
        '1McMsnEElThX1knmY4oliG', // Olivia Rodrigo
        '6bDWAcdtVR3WHz2xtiIPUi', // Fujii Kaze
        '1SIocsqdEefUTE6XKGUiVS', // BABYMONSTER
      ];

      final response = await _spotifyService.getArtists(artistIds);

      if (response.containsKey('artists')) {
        final List<dynamic> artistsJson = response['artists'];
        setState(() {
          _artists =
              artistsJson
                  .map((artistJson) => Artist.fromJson(artistJson))
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('獲取藝術家時出錯: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 添加一個方法來加載最近播放的歌曲
  Future<void> _loadRecentlyPlayed() async {
    if (_isLoadingRecent) return;

    setState(() {
      _isLoadingRecent = true;
    });

    try {
      final response = await _spotifyService.getRecentlyPlayed(limit: 5);

      if (response.containsKey('items')) {
        final List<dynamic> tracksJson = response['items'];
        setState(() {
          _recentTracks =
              tracksJson
                  .map((trackJson) => RecentTrack.fromJson(trackJson))
                  .toList();
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      debugPrint('獲取最近播放歌曲時出錯: $e');
      setState(() {
        _isLoadingRecent = false;
      });
    }
  }

  // 添加一個方法來加載用戶的播放清單
  Future<void> _loadPlaylists() async {
    if (_isLoadingPlaylists) return;

    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      final response = await _spotifyService.getUserPlaylists(limit: 6);

      if (response.containsKey('items')) {
        final List<dynamic> playlistsJson = response['items'];
        setState(() {
          _playlists =
              playlistsJson
                  .map((playlistJson) => Playlist.fromJson(playlistJson))
                  .toList();
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      debugPrint('獲取播放清單時出錯: $e');
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (
              BuildContext context,
              bool innerBoxIsScrolled,
            ) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.blue,
                  elevation: 4,
                  pinned: false,
                  floating: true,
                  title: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ];
            },
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingPlaylists
                      ? const Center(
                        child: SizedBox(
                          height: 100,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                      )
                      : GridView.builder(
                        padding: EdgeInsets.zero,
                        controller: ScrollController(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 3,
                            ),
                        itemCount: _playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = _playlists[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AlbumPage(
                                        albumTitle: playlist.name,
                                        playlistId: playlist.id,
                                        imageUrl:
                                            playlist.imageUrl, // 傳遞播放清單封面 URL
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                    child: Image.network(
                                      playlist.imageUrl,
                                      width: 55,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recently Played',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingRecent
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                      : _recentTracks.isEmpty
                      ? const Text(
                        'No recently played tracks',
                        style: TextStyle(color: Colors.white70),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentTracks.length,
                        itemBuilder: (context, index) {
                          final track = _recentTracks[index];
                          return GestureDetector(
                            onTap: () {
                              currentlyPlayingSong.value = PlayingSong(
                                title: track.title,
                                artist: track.artist,
                                imageUrl: track.imageUrl,
                                backgroundColor: Colors.black,
                              );
                            },
                            child: Container(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    track.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: ValueListenableBuilder<PlayingSong?>(
                                  valueListenable: currentlyPlayingSong,
                                  builder: (context, currentSong, child) {
                                    return Text(
                                      track.title,
                                      style: TextStyle(
                                        color:
                                            currentSong?.title == track.title
                                                ? Colors.yellow[700]
                                                : Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                subtitle: Text(
                                  track.artist,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  track.formattedDuration,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 24),
                  const Text(
                    'Artists',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _artists.length,
                              itemBuilder: (context, index) {
                                final artist = _artists[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ArtistPage(
                                              artistName: artist.name,
                                              artistId: artist.id,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: NetworkImage(
                                            artist.imageUrl,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          artist.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<PlayingSong?>(
            valueListenable: currentlyPlayingSong,
            builder: (context, playingSong, child) {
              if (playingSong != null) {
                return NowPlayingWidget(
                  songTitle: playingSong.title,
                  artistName: playingSong.artist,
                  imageUrl: playingSong.imageUrl,
                  backgroundColor: playingSong.backgroundColor,
                  onClose: () {
                    currentlyPlayingSong.value = null;
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 0, // 在首頁設置為 0
        onTap: (index) {
          if (index == 1) {
            // 導航到音樂庫頁面
            Navigator.pushNamed(context, '/library');
          }
        },
      ),
    );
  }
}
