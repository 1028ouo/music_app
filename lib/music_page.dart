import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'services/just_audio_service.dart';
import 'dart:async'; // 添加 Timer 的引入
import 'package:marquee/marquee.dart'; // 添加 Marquee 套件引入
import 'models/lyrics_model.dart';
import 'data/sample_lyrics.dart';
import 'lyrics_page.dart'; // Import the LyricsPage class

class MusicPage extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String imageUrl;
  final String? musicUrl; // 修改為可空類型

  const MusicPage({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.imageUrl,
    this.musicUrl, // 預覽URL可為null
  });

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  Color _dominantColor = Colors.black87;
  late PaletteGenerator _paletteGenerator;
  double _volume = 0.5;
  bool _imageLoading = false; // 追蹤圖片加載狀態
  Timer? _paletteTimer; // 用於延遲調色板更新
  bool _showLyrics = false; // 追蹤歌詞顯示狀態
  LyricsModel? _lyricsModel;

  // 定義本地狀態來跟踪當前歌曲
  String _currentTitle = '';
  String _currentArtist = '';
  String _currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    // 初始化本地狀態
    _currentTitle = widget.songTitle;
    _currentArtist = widget.artistName;
    _currentImageUrl = widget.imageUrl;

    _updatePalette();
    _initializeAudio();

    // 添加對當前歌曲變化的監聽
    audioPlayerService.currentSong.addListener(_onCurrentSongChanged);

    // 載入歌詞
    _loadLyrics();
  }

  @override
  void dispose() {
    // 取消定時器
    _paletteTimer?.cancel();
    // 移除監聽器
    audioPlayerService.currentSong.removeListener(_onCurrentSongChanged);
    super.dispose();
  }

  // 當當前歌曲改變時的回調函數
  void _onCurrentSongChanged() {
    if (audioPlayerService.currentSong.value != null) {
      final newSong = audioPlayerService.currentSong.value!;

      // 如果圖片相同，不需要重新加載
      if (_currentImageUrl == newSong.imageUrl) {
        setState(() {
          _currentTitle = newSong.title;
          _currentArtist = newSong.artist;
        });
        return;
      }

      setState(() {
        _currentTitle = newSong.title;
        _currentArtist = newSong.artist;
        _currentImageUrl = newSong.imageUrl;
        _imageLoading = true; // 設置圖片加載狀態
      });

      // 使用計時器延遲調色板更新，避免在歌曲快速切換時執行不必要的更新
      _paletteTimer?.cancel();
      _paletteTimer = Timer(const Duration(milliseconds: 300), () {
        _updatePaletteForNewImage();
      });

      // 載入新歌曲的歌詞
      _loadLyrics();
    }
  }

  Future<void> _initializeAudio() async {
    await audioPlayerService.init();
    setState(() {
      _volume = audioPlayerService.volumeLevel.value;
    });

    // 檢查當前播放的歌曲是否與我們要播放的歌曲相同
    final currentSong = audioPlayerService.currentSong.value;
    final isSameSong =
        currentSong != null &&
        currentSong.title == widget.songTitle &&
        currentSong.artist == widget.artistName;

    // 如果是不同的歌曲，或者當前沒有播放的歌曲，才重新加載並播放
    if (!isSameSong) {
      debugPrint(
        "播放新歌曲: ${widget.songTitle} by ${widget.artistName}, URL: ${widget.musicUrl}",
      );

      // 檢查 musicUrl 是否為空
      if (widget.musicUrl == null || widget.musicUrl!.isEmpty) {
        debugPrint("警告：歌曲URL為空，將嘗試播放但可能會失敗");
      }

      await audioPlayerService.loadAndPlay(
        audioUrl: widget.musicUrl,
        title: widget.songTitle,
        artist: widget.artistName,
        imageUrl: widget.imageUrl,
        backgroundColor: _dominantColor,
      );
    }
    // 如果是相同的歌曲，只確保背景顏色更新
    else if (currentSong != null) {
      audioPlayerService.currentSong.value = currentSong.copyWith(
        backgroundColor: _dominantColor,
      );
    }
  }

  Future<void> _updatePalette() async {
    try {
      _paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(
          _currentImageUrl.isNotEmpty
              ? _currentImageUrl
              : 'https://i.kfs.io/album/global/209967368,2v1/fit/500x500.jpg',
        ),
        size: const Size(200, 200), // 減小圖片大小以加速處理
      );

      if (mounted) {
        setState(() {
          _dominantColor =
              _paletteGenerator.dominantColor?.color ?? Colors.black87;
          _imageLoading = false; // 更新完成後重置圖片加載狀態
        });

        // 如果已有當前歌曲，更新背景色
        if (audioPlayerService.currentSong.value != null) {
          audioPlayerService.currentSong.value = audioPlayerService
              .currentSong
              .value!
              .copyWith(backgroundColor: _dominantColor);
        }
      }
    } catch (e) {
      debugPrint('更新調色板時出錯: $e');
      if (mounted) {
        setState(() {
          _imageLoading = false; // 錯誤時也要重置圖片加載狀態
        });
      }
    }
  }

  // 當圖片更新時更新色調
  Future<void> _updatePaletteForNewImage() async {
    if (!mounted) return;

    try {
      _paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(
          _currentImageUrl.isNotEmpty
              ? _currentImageUrl
              : 'https://i.kfs.io/album/global/209967368,2v1/fit/500x500.jpg',
        ),
        size: const Size(200, 200), // 減小圖片大小以加速處理
        maximumColorCount: 8, // 減少顏色數量以加速處理
      );

      if (!mounted) return;

      setState(() {
        _dominantColor =
            _paletteGenerator.dominantColor?.color ?? Colors.black87;
        _imageLoading = false; // 更新完成後重置圖片加載狀態
      });

      // 更新當前歌曲的背景色
      if (audioPlayerService.currentSong.value != null) {
        audioPlayerService.currentSong.value = audioPlayerService
            .currentSong
            .value!
            .copyWith(backgroundColor: _dominantColor);
      }
    } catch (e) {
      debugPrint('更新調色板時出錯: $e');
      if (mounted) {
        setState(() {
          _imageLoading = false; // 錯誤時也要重置圖片加載狀態
        });
      }
    }
  }

  // 載入歌詞方法
  void _loadLyrics() {
    final lyrics = SampleLyrics.getLyricsByTitle(_currentTitle);
    if (lyrics != null) {
      setState(() {
        _lyricsModel = LyricsModel.fromLRC(
          lyrics,
          _currentTitle,
          _currentArtist,
        );
      });
    } else {
      setState(() {
        _lyricsModel = null;
      });
    }
  }

  // 刪除現有的 _showLyricsDialog 方法，並替換成導航到歌詞頁面的方法
  void _navigateToLyricsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LyricsPage(
              title: _currentTitle,
              artist: _currentArtist,
              lyricsModel: _lyricsModel,
              backgroundColor: _dominantColor,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: _dominantColor),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_dominantColor, Colors.black, _dominantColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child:
                                _currentImageUrl.isNotEmpty
                                    ? Image.network(
                                      _currentImageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.black45,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        debugPrint('圖片加載錯誤: $error');
                                        return Image.asset(
                                          'assets/image/record.png',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                    : Image.asset(
                                      'assets/image/record.png',
                                      fit: BoxFit.cover,
                                    ),
                          ),
                          if (_imageLoading)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // 將文字部分修改為可滾動的形式
                  SizedBox(
                    height: 30,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ValueListenableBuilder<double>(
                      valueListenable: audioPlayerService.titleWidth,
                      builder: (context, width, _) {
                        return width > MediaQuery.of(context).size.width * 0.8
                            ? Marquee(
                              text: _currentTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 20.0,
                              velocity: 30.0,
                              pauseAfterRound: const Duration(seconds: 1),
                              startPadding: 10.0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration: const Duration(
                                milliseconds: 500,
                              ),
                              decelerationCurve: Curves.easeOut,
                            )
                            : Text(
                              _currentTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: ValueListenableBuilder<double>(
                      valueListenable: audioPlayerService.artistWidth,
                      builder: (context, width, _) {
                        return width > MediaQuery.of(context).size.width * 0.7
                            ? Marquee(
                              text: _currentArtist,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 20.0,
                              velocity: 25.0,
                              pauseAfterRound: const Duration(seconds: 1),
                              startPadding: 10.0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration: const Duration(
                                milliseconds: 500,
                              ),
                              decelerationCurve: Curves.easeOut,
                            )
                            : Text(
                              _currentArtist,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            );
                      },
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: audioPlayerService.errorMessage,
                    builder: (context, errorMsg, _) {
                      if (errorMsg != null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            errorMsg,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // 進度條
                  ValueListenableBuilder<Duration>(
                    valueListenable: audioPlayerService.currentPosition,
                    builder: (context, position, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: audioPlayerService.totalDuration,
                        builder: (context, duration, _) {
                          return Slider(
                            value: position.inSeconds.toDouble(),
                            max:
                                duration.inSeconds.toDouble() > 0
                                    ? duration.inSeconds.toDouble()
                                    : 1.0,
                            onChanged: (value) {
                              audioPlayerService.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                          );
                        },
                      );
                    },
                  ),
                  // 時間顯示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: audioPlayerService.currentPosition,
                      builder: (context, position, _) {
                        return ValueListenableBuilder<Duration>(
                          valueListenable: audioPlayerService.totalDuration,
                          builder: (context, duration, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  audioPlayerService.formatDuration(position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  audioPlayerService.formatDuration(duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // 控制按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 組合播放模式按鈕
                      ValueListenableBuilder<LoopModeCustom>(
                        valueListenable: audioPlayerService.loopMode,
                        builder: (context, mode, _) {
                          IconData iconData;
                          Color iconColor;

                          switch (mode) {
                            case LoopModeCustom.off:
                              iconData = Icons.shuffle;
                              iconColor = Colors.white;
                              break;
                            case LoopModeCustom.shuffle:
                              iconData = Icons.shuffle;
                              iconColor = Colors.lightBlue;
                              break;
                            case LoopModeCustom.all:
                              iconData = Icons.repeat;
                              iconColor = Colors.lightBlue;
                              break;
                            case LoopModeCustom.one:
                              iconData = Icons.repeat_one;
                              iconColor = Colors.lightBlue;
                              break;
                          }

                          return IconButton(
                            icon: Icon(iconData, color: iconColor),
                            iconSize: 36,
                            onPressed:
                                () => audioPlayerService.togglePlayMode(),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        color: Colors.white,
                        iconSize: 36,
                        onPressed:
                            () => audioPlayerService.playPrevious(), // 更改為播放上一首
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: audioPlayerService.isPlaying,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            color: Colors.white,
                            iconSize: 48,
                            onPressed: () {
                              if (isPlaying) {
                                audioPlayerService.pause();
                              } else {
                                audioPlayerService.play();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
                        iconSize: 36,
                        onPressed:
                            () =>
                                audioPlayerService
                                    .playNext(), // 修改為播放下一首改為播放下一首
                      ),
                      IconButton(
                        icon: const Icon(Icons.lyrics),
                        color: Colors.white,
                        iconSize: 36,
                        onPressed: () {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                          // 導航到歌詞頁面
                          _navigateToLyricsPage();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 音量控制
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_down, color: Colors.white),
                        Expanded(
                          child: ValueListenableBuilder<double>(
                            valueListenable: audioPlayerService.volumeLevel,
                            builder: (context, volume, _) {
                              return Slider(
                                value: volume,
                                onChanged: (value) {
                                  setState(() {
                                    _volume = value;
                                  });
                                  audioPlayerService.setVolume(value);
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white24,
                              );
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: audioPlayerService.isBuffering,
              builder: (context, isBuffering, _) {
                if (isBuffering) {
                  return Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
