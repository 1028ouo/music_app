import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // 添加這個導入
import 'dart:async';
import 'dart:math';
import '../models/playing_song.dart';
import '../data/local_music_data.dart'; // 添加導入本地音樂數據

// 保留現有的播放模式列舉
enum LoopModeCustom {
  off, // 無任何設置 (原 normal)
  shuffle, // 隨機播放
  all, // 全部循環 (原 repeatAll)
  one, // 單曲循環 (原 repeatOne)
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  // 通知器，用於觀察狀態變化
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isBuffering = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<double> volumeLevel = ValueNotifier(0.5);
  final ValueNotifier<PlayingSong?> currentSong = ValueNotifier(null);
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);
  final ValueNotifier<double> titleWidth = ValueNotifier(0.0);
  final ValueNotifier<double> artistWidth = ValueNotifier(0.0);
  final ValueNotifier<LoopModeCustom> loopMode = ValueNotifier(
    LoopModeCustom.off,
  );

  // 替換為 just_audio 相關的串流訂閱
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    isBuffering.value = true;

    try {
      // 設置監聽器，使用 just_audio 的串流
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
      });

      _processingStateSubscription = _player.processingStateStream.listen((
        state,
      ) {
        // 處理播放完成
        if (state == ProcessingState.completed) {
          currentPosition.value = totalDuration.value;

          // 根據播放模式處理播放完成後的行為
          switch (loopMode.value) {
            case LoopModeCustom.off:
              // 正常模式下自動播放下一首
              playNext();
              break;

            case LoopModeCustom.one:
              // 重新播放當前歌曲
              _player.seek(Duration.zero).then((_) => _player.play());
              break;

            case LoopModeCustom.all:
            case LoopModeCustom.shuffle: // 不管是全部循環還是隨機模式，都播放下一首
              playNext();
              break;
          }
        }
      });

      _positionSubscription = _player.positionStream.listen((newPosition) {
        currentPosition.value = newPosition;
      });

      _durationSubscription = _player.durationStream.listen((newDuration) {
        if (newDuration != null) {
          totalDuration.value = newDuration;
        }
      });

      await _player.setVolume(volumeLevel.value);
      _initialized = true;
    } catch (e) {
      debugPrint("音頻服務初始化錯誤: $e");
      errorMessage.value = "無法初始化音頻服務: $e";
    } finally {
      isBuffering.value = false;
    }
  }

  Future<void> loadAndPlay({
    required String? audioUrl,
    required String title,
    required String artist,
    required String imageUrl,
    Color backgroundColor = Colors.blue,
    int songIndex = -1,
  }) async {
    if (!_initialized) await init();

    errorMessage.value = null;
    isBuffering.value = true; // 開始加載

    try {
      // 更新當前索引
      currentIndex.value = songIndex;

      // 先設置歌曲資訊，不等待圖片加載
      currentSong.value = PlayingSong(
        title: title,
        artist: artist,
        imageUrl: imageUrl,
        backgroundColor: backgroundColor,
        previewUrl: audioUrl ?? "", // 確保即使 URL 為 null 也可以設置為空字符串
      );

      debugPrint("AudioPlayerService: 正在嘗試播放: $audioUrl");

      // 停止當前播放（只需要一次）
      try {
        await _player.stop();
      } catch (e) {
        debugPrint("停止當前播放時出錯: $e");
      }

      // 清除之前的狀態
      currentPosition.value = Duration.zero;

      // 為背景播放準備媒體項目
      final mediaItem = MediaItem(
        id: songIndex.toString(),
        album: "Music App",
        title: title,
        artist: artist,
        artUri: Uri.parse(imageUrl),
        duration: const Duration(minutes: 3), // 預設值，會在加載後更新
      );

      // 判斷是本地資源還是網路URL
      if (audioUrl != null && audioUrl.startsWith('assets/')) {
        try {
          debugPrint("加載本地資產: $audioUrl");

          // 使用 AudioSource 設置背景播放
          await _player.setAudioSource(
            AudioSource.asset(audioUrl, tag: mediaItem),
          );

          // 在播放前先設置一個監聽器，用於檢測播放開始
          final playingCompleter = Completer<void>();
          final subscription = _player.playerStateStream.listen((state) {
            if (state.playing && !playingCompleter.isCompleted) {
              // 檢測到開始播放後，將加載狀態設置為false
              isBuffering.value = false;
              playingCompleter.complete();
            }
          });

          await _player.play();

          // 確保在5秒內有回應，否則也要關閉加載指示器
          Future.delayed(const Duration(seconds: 2), () {
            if (!playingCompleter.isCompleted) {
              isBuffering.value = false;
              playingCompleter.complete();
            }
          });

          // 等待播放開始或超時
          await playingCompleter.future;

          // 清理監聽器
          subscription.cancel();

          debugPrint("AudioPlayerService: 本地音頻已加載 - 資產路徑: $audioUrl");
        } catch (assetError) {
          debugPrint("播放資產失敗: $assetError");
          errorMessage.value = "無法播放音頻資產: $assetError";
          isBuffering.value = false;
          throw assetError;
        }
      } else if (audioUrl != null && audioUrl.isNotEmpty) {
        // 明確檢查 URL 不為空字符串
        try {
          debugPrint("加載網絡音頻: $audioUrl");

          // 使用 AudioSource 設置背景播放
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem),
          );

          // 在播放前先設置一個監聽器，用於檢測播放開始
          final playingCompleter = Completer<void>();
          final subscription = _player.playerStateStream.listen((state) {
            if (state.playing && !playingCompleter.isCompleted) {
              // 檢測到開始播放後，將加載狀態設置為false
              isBuffering.value = false;
              playingCompleter.complete();
            }
          });

          await _player.play();

          // 確保在5秒內有回應，否則也要關閉加載指示器
          Future.delayed(const Duration(seconds: 2), () {
            if (!playingCompleter.isCompleted) {
              isBuffering.value = false;
              playingCompleter.complete();
            }
          });

          // 等待播放開始或超時
          await playingCompleter.future;

          // 清理監聽器
          subscription.cancel();

          debugPrint("AudioPlayerService: 網路音頻已加載並開始播放 - URL: $audioUrl");
        } catch (urlError) {
          debugPrint("播放網絡URL失敗: $urlError");
          errorMessage.value = "無法播放網路音頻: $urlError";
          isBuffering.value = false;
          throw urlError;
        }
      } else {
        // URL 為空時給出明確的提示並關閉加載指示器
        debugPrint("URL為空或無效，無法播放音頻");
        isBuffering.value = false;
      }

      // 測量標題和歌手名稱的寬度
      measureTextWidth(title, artist);
    } catch (e) {
      debugPrint("AudioPlayerService: 音頻加載錯誤: $e");
      errorMessage.value = "無法加載音頻: $e";
      isBuffering.value = false;
    } finally {
      // 添加另一層保障，確保無論如何，加載指示器最終會消失
      Future.delayed(const Duration(seconds: 3), () {
        if (isBuffering.value) {
          debugPrint("加載指示器超時關閉");
          isBuffering.value = false;
        }
      });
    }
  }

  // 播放控制
  Future<void> play() async {
    if (currentSong.value != null) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    currentPosition.value = Duration.zero;
    currentSong.value = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipForward([int seconds = 10]) async {
    await _player.seek(currentPosition.value + Duration(seconds: seconds));
  }

  Future<void> skipBackward([int seconds = 10]) async {
    await _player.seek(currentPosition.value - Duration(seconds: seconds));
  }

  Future<void> setVolume(double value) async {
    volumeLevel.value = value.clamp(0.0, 1.0);
    await _player.setVolume(volumeLevel.value);
  }

  // 切換到下一首歌曲
  Future<void> playNext() async {
    if (localSongs.isEmpty) return;

    // 先暫停當前播放，減少資源消耗
    await pause();

    // 如果當前歌曲正在加載中，不執行切換操作
    if (isBuffering.value) {
      debugPrint("當前歌曲正在加載中，無法切換至下一首");
      return;
    }

    // 設置標誌以表示正在加載歌曲
    isBuffering.value = true;

    int nextIndex;

    if (loopMode.value == LoopModeCustom.shuffle) {
      // 隨機模式：生成一個隨機索引，但避免與當前索引相同
      int randomIndex;
      do {
        randomIndex = Random().nextInt(localSongs.length);
      } while (randomIndex == currentIndex.value && localSongs.length > 1);
      nextIndex = randomIndex;
    } else {
      // 正常模式：播放下一首歌曲
      nextIndex =
          (currentIndex.value >= localSongs.length - 1 ||
                  currentIndex.value < 0)
              ? 0
              : currentIndex.value + 1;
    }

    PlayingSong nextSong = localSongs[nextIndex];

    // 預先清理當前播放器狀態
    try {
      await _player.stop();
    } catch (e) {
      debugPrint("停止當前播放時出錯: $e");
    }

    // 確保UI可以立即更新
    currentPosition.value = Duration.zero;

    // 確保在完整播放完成後再設置 isBuffering 為 false
    await loadAndPlay(
      audioUrl: nextSong.previewUrl,
      title: nextSong.title,
      artist: nextSong.artist,
      imageUrl: nextSong.imageUrl,
      backgroundColor: currentSong.value?.backgroundColor ?? Colors.blue,
      songIndex: nextIndex,
    );
  }

  // 切換到上一首歌曲
  Future<void> playPrevious() async {
    if (localSongs.isEmpty) return;

    // 先暫停當前播放，減少資源消耗
    await pause();

    // 如果當前歌曲正在加載中，不執行切換操作
    if (isBuffering.value) {
      debugPrint("當前歌曲正在加載中，無法切換至上一首");
      return;
    }

    // 設置標誌以表示正在加載歌曲
    isBuffering.value = true;

    int prevIndex;

    if (loopMode.value == LoopModeCustom.shuffle) {
      // 隨機模式：生成一個隨機索引，但避免與當前索引相同
      int randomIndex;
      do {
        randomIndex = Random().nextInt(localSongs.length);
      } while (randomIndex == currentIndex.value && localSongs.length > 1);
      prevIndex = randomIndex;
    } else {
      // 正常模式：播放上一首歌曲
      prevIndex =
          (currentIndex.value <= 0)
              ? localSongs.length - 1
              : currentIndex.value - 1;
    }

    PlayingSong prevSong = localSongs[prevIndex];

    // 預先清理當前播放器狀態
    try {
      await _player.stop();
    } catch (e) {
      debugPrint("停止當前播放時出錯: $e");
    }

    // 確保UI可以立即更新
    currentPosition.value = Duration.zero;

    await loadAndPlay(
      audioUrl: prevSong.previewUrl,
      title: prevSong.title,
      artist: prevSong.artist,
      imageUrl: prevSong.imageUrl,
      backgroundColor: currentSong.value?.backgroundColor ?? Colors.blue,
      songIndex: prevIndex,
    );
  }

  // 循環切換播放模式
  void togglePlayMode() async {
    switch (loopMode.value) {
      case LoopModeCustom.off:
        loopMode.value = LoopModeCustom.shuffle;
        // 設置隨機播放
        await _player.setShuffleModeEnabled(true);
        await _player.setLoopMode(LoopMode.off);
        break;
      case LoopModeCustom.shuffle:
        loopMode.value = LoopModeCustom.all;
        // 設置全部循環
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopModeCustom.all:
        loopMode.value = LoopModeCustom.one;
        // 設置單曲循環
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopModeCustom.one:
        loopMode.value = LoopModeCustom.off;
        // 設置正常模式
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  void measureTextWidth(String title, String artist) {
    final TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter artistPainter = TextPainter(
      text: TextSpan(text: artist, style: const TextStyle(fontSize: 18)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    titleWidth.value = titlePainter.width;
    artistWidth.value = artistPainter.width;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _player.dispose();

    // 釋放 ValueNotifier
    isPlaying.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    isBuffering.dispose();
    errorMessage.dispose();
    volumeLevel.dispose();
    currentSong.dispose();
    currentIndex.dispose();
    loopMode.dispose();
    titleWidth.dispose();
    artistWidth.dispose();
  }
}

// 全局單例實例
final audioPlayerService = AudioPlayerService();
