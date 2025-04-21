import 'package:flutter/material.dart';
import 'models/lyrics_model.dart';
import 'services/just_audio_service.dart';

class LyricsPage extends StatefulWidget {
  final String title;
  final String artist;
  final LyricsModel? lyricsModel;
  final Color backgroundColor;

  const LyricsPage({
    super.key,
    required this.title,
    required this.artist,
    required this.lyricsModel,
    required this.backgroundColor,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  int _currentLineIndex = 0;
  final AudioPlayerService audioPlayerService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 滾動到當前歌詞位置
  void _scrollToCurrentLine(int lineIndex) {
    if (widget.lyricsModel == null ||
        widget.lyricsModel!.lines.isEmpty ||
        lineIndex >= widget.lyricsModel!.lines.length ||
        !_scrollController.hasClients) {
      return;
    }

    // 計算需要滾動到的位置
    double scrollPosition = lineIndex * 50.0; // 假設每行歌詞高度為50

    // 確保不會滾動超出邊界
    if (scrollPosition > _scrollController.position.maxScrollExtent) {
      scrollPosition = _scrollController.position.maxScrollExtent;
    }

    // 平滑滾動到目標位置
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌詞', style: TextStyle(color: Colors.white)),
        backgroundColor: widget.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.backgroundColor,
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.artist,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: widget.lyricsModel == null
                  ? const Center(
                      child: Text(
                        '沒有可用的歌詞',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                  : ValueListenableBuilder<Duration>(
                      valueListenable: audioPlayerService.currentPosition,
                      builder: (context, position, _) {
                        // 獲取當前應該顯示的歌詞行
                        final currentLine =
                            widget.lyricsModel!.getCurrentLine(position);

                        // 找到當前行的索引
                        if (currentLine != null) {
                          final lineIndex =
                              widget.lyricsModel!.lines.indexOf(currentLine);
                          if (lineIndex != _currentLineIndex &&
                              lineIndex >= 0) {
                            _currentLineIndex = lineIndex;
                            // 當歌詞切換到新行時，滾動到該位置
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToCurrentLine(_currentLineIndex);
                            });
                          }
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          itemCount: widget.lyricsModel!.lines.length,
                          itemBuilder: (context, index) {
                            final line = widget.lyricsModel!.lines[index];
                            final bool isCurrent = currentLine == line;

                            return FadeTransition(
                              opacity: _animationController,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 8.0),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.lightBlue
                                        : Colors.white70,
                                    fontSize: isCurrent ? 20 : 16,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            // 播放控制器
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 進度條
                  ValueListenableBuilder<Duration>(
                    valueListenable: audioPlayerService.currentPosition,
                    builder: (context, position, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: audioPlayerService.totalDuration,
                        builder: (context, duration, _) {
                          return Slider(
                            value: position.inSeconds.toDouble(),
                            max: duration.inSeconds.toDouble() > 0
                                ? duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (value) {
                              audioPlayerService
                                  .seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: Colors.lightBlue,
                            inactiveColor: Colors.white24,
                          );
                        },
                      );
                    },
                  ),
                  // 時間顯示和控制按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<Duration>(
                        valueListenable: audioPlayerService.currentPosition,
                        builder: (context, position, _) {
                          return Text(
                            audioPlayerService.formatDuration(position),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white),
                            onPressed: () => audioPlayerService.playPrevious(),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: audioPlayerService.isPlaying,
                            builder: (context, isPlaying, _) {
                              return IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 48,
                                  color: Colors.white,
                                ),
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
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white),
                            onPressed: () => audioPlayerService.playNext(),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<Duration>(
                        valueListenable: audioPlayerService.totalDuration,
                        builder: (context, duration, _) {
                          return Text(
                            audioPlayerService.formatDuration(duration),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
