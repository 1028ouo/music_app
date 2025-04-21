import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'now_playing_widget.dart';
import 'home_page.dart'; // 匯入全域變數
import 'models/playing_song.dart'; // 導入 PlayingSong 模型
import 'models/track.dart'; // 導入 Track 模型
import 'services/spotify_service.dart'; // 導入 SpotifyService
import 'widgets/custom_bottom_navigation.dart'; // 新增導入自定義導航欄

class AlbumPage extends StatefulWidget {
  final String albumTitle;
  final String? playlistId; // 播放清單 ID 參數
  final String? imageUrl; // 新增播放清單封面 URL 參數

  const AlbumPage({
    super.key,
    required this.albumTitle,
    this.playlistId,
    this.imageUrl, // 新參數
  });

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage>
    with SingleTickerProviderStateMixin {
  Color _dominantColor = Colors.blue; // 預設主色調
  late PaletteGenerator _paletteGenerator;
  final SpotifyService _spotifyService = SpotifyService();
  List<Track> _tracks = []; // 儲存曲目
  bool _isLoading = false;
  String _albumImageUrl = 'https://via.placeholder.com/150'; // 預設圖片

  // 新增動畫控制器
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // 初始化旋轉動畫控制器
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10), // 轉一圈需要10秒
      vsync: this,
    );

    // 啟動連續旋轉動畫
    _rotationController.repeat();

    // 如果提供了封面圖片 URL，則使用它
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _albumImageUrl = widget.imageUrl!;
    }
    _updatePalette();
    if (widget.playlistId != null) {
      _loadPlaylistTracks();
    }
  }

  @override
  void dispose() {
    // 釋放動畫控制器資源
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylistTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await _spotifyService.getPlaylistTracks(widget.playlistId!);

      if (response.containsKey('items')) {
        final List<dynamic> tracksJson = response['items'];
        setState(() {
          _tracks =
              tracksJson.map((trackJson) => Track.fromJson(trackJson)).toList();
        });
      }
    } catch (e) {
      debugPrint('獲取播放清單曲目時出錯: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(_albumImageUrl),
    );
    setState(() {
      _dominantColor = _paletteGenerator.dominantColor?.color ?? Colors.blue;
    });
  }

  Future<Color> _extractDominantColor(String imageUrl) async {
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 20,
      );

      Color extractedColor;
      final Color? vibrantColor = paletteGenerator.vibrantColor?.color;
      final Color? lightVibrantColor =
          paletteGenerator.lightVibrantColor?.color;
      final Color? darkVibrantColor = paletteGenerator.darkVibrantColor?.color;

      // 優先使用暗色調
      if (darkVibrantColor != null) {
        extractedColor = darkVibrantColor;
      } else if (vibrantColor != null) {
        extractedColor = vibrantColor;
      } else if (lightVibrantColor != null) {
        extractedColor = lightVibrantColor;
      } else if (paletteGenerator.dominantColor != null) {
        extractedColor = paletteGenerator.dominantColor!.color;
      } else {
        return Colors.black; // 默認黑色
      }

      // 使顏色變暗
      return _darkenColor(extractedColor);
    } catch (e) {
      debugPrint('提取顏色時出錯: $e');
      return Colors.black;
    }
  }

  // 添加一個方法使顏色變暗
  Color _darkenColor(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    // 將亮度降低到原來的60%左右
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: _dominantColor, // 使用動態主色調
                  elevation: 4,
                  pinned: true,
                  floating: true,
                  title: Text(widget.albumTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24)),
                ),
              ];
            },
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_dominantColor, Colors.black], // 動態漸層背景
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(42, -2), // 下層圖片右移
                        child: RotationTransition(
                          turns: _rotationController,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16), // 圓角
                            child: Image.asset(
                              'assets/image/cd.png', // CD 圖片
                              fit: BoxFit.cover,
                              width: 210,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-42, 0), // 上層圖片左移
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16), // 圓角
                          child: Image.network(
                            _albumImageUrl,
                            width: 180,
                            height: 180, // 正方形
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.playlistId != null
                        ? 'Playlist Songs'
                        : 'Album Songs',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tracks.isEmpty ? 5 : _tracks.length,
                          itemBuilder: (context, index) {
                            if (_tracks.isEmpty) {
                              // 使用模擬資料
                              String songTitle = 'Song Title $index';
                              String imageUrl = _albumImageUrl;

                              return _buildTrackListItem(songTitle,
                                  'Artist Name', imageUrl, null, index);
                            } else {
                              // 使用實際曲目資料
                              final track = _tracks[index];
                              return _buildTrackListItem(
                                track.name,
                                track.artistsText,
                                track.imageUrl,
                                track.durationText,
                                index,
                              );
                            }
                          },
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
        currentIndex: 0, // 改為0來高亮Home按鈕
        onTap: (index) {
          if (index == 0) {
            // 導航回主頁
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            // 導航到Library頁面
            Navigator.pushNamed(context, '/library');
          }
        },
      ),
    );
  }

  // 建立曲目列表項目
  Widget _buildTrackListItem(String title, String artist, String imageUrl,
      [String? duration, int? index]) {
    return GestureDetector(
      onTap: () async {
        // 提取封面顏色並設置播放狀態
        final Color trackColor = await _extractDominantColor(imageUrl);

        currentlyPlayingSong.value = PlayingSong(
          title: title,
          artist: artist,
          imageUrl: imageUrl,
          backgroundColor: trackColor,
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != null)
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (index != null) const SizedBox(width: 16), // 寬度從12改為16
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0), // 加上.0保持一致
              child: Image.network(
                imageUrl,
                width: 55, // 寬度從60改為55
                fit: BoxFit.cover, // 移除高度屬性
              ),
            ),
          ],
        ),
        title: ValueListenableBuilder<PlayingSong?>(
          valueListenable: currentlyPlayingSong,
          builder: (context, playingSong, child) {
            return Text(
              title,
              style: TextStyle(
                color: playingSong?.title == title
                    ? Colors.yellow[700] // 鵝黃色
                    : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        subtitle: Text(
          artist,
          style: const TextStyle(color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: duration != null
            ? Container(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  duration,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            : const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }
}
