import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'now_playing_widget.dart';
import 'home_page.dart';
import 'models/artist.dart';
import 'models/track.dart';
import 'models/playing_song.dart'; // 新導入
import 'services/spotify_service.dart';
import 'widgets/custom_bottom_navigation.dart'; // 新增導入自定義導航欄

class ArtistPage extends StatefulWidget {
  final String artistName;
  final String? artistId;

  const ArtistPage({
    super.key,
    required this.artistName,
    this.artistId,
  });

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final SpotifyService _spotifyService = SpotifyService();
  Artist? _artist;
  List<Track> _topTracks = []; // 新增熱門歌曲列表
  bool _isLoading = true;
  Color _dominantColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.artistId != null) {
      _loadArtistDetails();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArtistDetails() async {
    try {
      final response = await _spotifyService.getArtists([widget.artistId!]);
      if (response.containsKey('artists') && response['artists'].isNotEmpty) {
        final artistJson = response['artists'][0];
        setState(() {
          _artist = Artist.fromJson(artistJson);
        });

        // 提取圖片主色調
        await _updateDominantColor(_artist!.imageUrl);

        // 獲取熱門歌曲
        await _loadTopTracks();
      }
    } catch (e) {
      debugPrint('獲取藝術家詳情時出錯: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTopTracks() async {
    try {
      final topTracksResponse =
          await _spotifyService.getArtistTopTracks(widget.artistId!);
      if (topTracksResponse.containsKey('tracks')) {
        final List<dynamic> tracksJson = topTracksResponse['tracks'];
        setState(() {
          _topTracks =
              tracksJson.map((trackJson) => Track.fromJson(trackJson)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('獲取熱門歌曲時出錯: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDominantColor(String imageUrl) async {
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 20,
      );

      // 偏向明亮的顏色
      final Color? vibrantColor = paletteGenerator.vibrantColor?.color;
      final Color? lightVibrantColor =
          paletteGenerator.lightVibrantColor?.color;

      setState(() {
        if (lightVibrantColor != null) {
          _dominantColor = lightVibrantColor;
        } else if (vibrantColor != null) {
          _dominantColor = vibrantColor;
        } else if (paletteGenerator.dominantColor != null) {
          _dominantColor = paletteGenerator.dominantColor!.color;
        }
      });
    } catch (e) {
      debugPrint('提取顏色時出錯: $e');
    }
  }

  // 修改方法：從圖片URL提取顏色並使其變暗
  Future<Color> _extractDominantColor(String imageUrl) async {
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 20,
      );

      // 偏向明亮的顏色
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
      return Colors.black; // 出錯時返回黑色
    }
  }

  // 添加一個方法使顏色變暗
  Color _darkenColor(Color color) {
    // 降低明度，使顏色更暗
    final HSLColor hsl = HSLColor.fromColor(color);
    // 將亮度降低到原來的60%左右
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: _dominantColor,
                      expandedHeight: 300.0,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(widget.artistName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.white)),
                        background: _artist != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    _artist!.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          _dominantColor.withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(color: _dominantColor),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _dominantColor.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: _artist != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Followers: ${_artist!.followers}',
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                          if (_artist!.genres.isNotEmpty) ...[
                                            Wrap(
                                              children: _artist!.genres
                                                  .map((genre) => Chip(
                                                        label: Text(genre),
                                                        backgroundColor:
                                                            _dominantColor
                                                                .withOpacity(
                                                                    0.3),
                                                      ))
                                                  .toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        '熱門歌曲',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      // 使用實際的熱門歌曲數據
                                      ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _topTracks.length,
                                        itemBuilder: (context, index) {
                                          final track = _topTracks[index];
                                          return GestureDetector(
                                            onTap: () async {
                                              // 提取歌曲封面顏色
                                              final Color trackColor =
                                                  await _extractDominantColor(
                                                      track.imageUrl);
                                              currentlyPlayingSong.value =
                                                  PlayingSong(
                                                title: track.name,
                                                artist: track.artistsText,
                                                imageUrl: track.imageUrl,
                                                backgroundColor: trackColor,
                                              );
                                            },
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 0),
                                              leading: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      track.imageUrl,
                                                      fit: BoxFit.cover,
                                                      width: 55,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              title: ValueListenableBuilder<
                                                  PlayingSong?>(
                                                valueListenable:
                                                    currentlyPlayingSong,
                                                builder: (context, playingSong,
                                                    child) {
                                                  return Text(
                                                    track.name,
                                                    style: TextStyle(
                                                      color:
                                                          playingSong?.title ==
                                                                  track.name
                                                              ? Colors.yellow[
                                                                  700] // 鵝黃色
                                                              : Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  );
                                                },
                                              ),
                                              subtitle: Text(
                                                track.artistsText,
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Container(
                                                padding:
                                                    EdgeInsets.only(right: 8.0),
                                                child: Text(
                                                  track.durationText,
                                                  style: const TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('無法獲取藝術家詳情'),
                                  ),
                                ),
                        ),
                      ]),
                    ),
                  ],
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
}
