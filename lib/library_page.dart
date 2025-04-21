import 'package:flutter/material.dart';
import 'widgets/custom_bottom_navigation.dart';
import 'now_playing_widget.dart';
import 'home_page.dart';
import 'models/playing_song.dart';
import 'data/local_music_data.dart';
import 'services/just_audio_service.dart' as audio_service; // 導入音頻播放服務

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // 確保音訊服務已初始化
    audio_service.audioPlayerService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverAppBar(
                backgroundColor: Colors.blue,
                elevation: 4,
                pinned: true,
                title: Text(
                  'Your Library',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Music Library',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Here is your music collection',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: localSongs.length,
                            itemBuilder: (context, index) {
                              final song = localSongs[index];
                              return GestureDetector(
                                onTap: () {
                                  // 確保有有效的音訊網址
                                  String? audioPath = song.previewUrl;
                                  if (audioPath == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('無法播放：找不到音樂資源'),
                                      ),
                                    );
                                    return;
                                  }

                                  debugPrint(
                                    "從資料庫嘗試播放: $audioPath，歌曲: ${song.title}",
                                  );

                                  // 設置全域播放狀態 (先設定，確保 UI 能快速更新)
                                  currentlyPlayingSong.value = PlayingSong(
                                    title: song.title,
                                    artist: song.artist,
                                    imageUrl: song.imageUrl,
                                    backgroundColor: Colors.blue,
                                    previewUrl: audioPath,
                                  );

                                  // 使用 AudioPlayerService 播放歌曲
                                  audio_service.audioPlayerService.loadAndPlay(
                                    audioUrl: audioPath,
                                    title: song.title,
                                    artist: song.artist,
                                    imageUrl: song.imageUrl,
                                    backgroundColor: Colors.blue,
                                    songIndex: index,
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
                                        song.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    title: ValueListenableBuilder<PlayingSong?>(
                                      valueListenable: currentlyPlayingSong,
                                      builder: (context, currentSong, child) {
                                        return Text(
                                          song.title,
                                          style: TextStyle(
                                            color:
                                                currentSong?.title == song.title
                                                    ? Colors.yellow[700]
                                                    : Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      '#${song.id}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
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
              ),
            ],
          ),
          // 播放控制器
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
                    // 關閉播放器同時停止音樂播放
                    audio_service.audioPlayerService.stop();
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
        currentIndex: 1, // 在Library頁設置為1，高亮Library按鈕
        onTap: (index) {
          if (index == 0) {
            // 返回首頁
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}
