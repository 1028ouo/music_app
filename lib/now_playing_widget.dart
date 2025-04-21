import 'package:flutter/material.dart';
import 'music_page.dart'; // 匯入音樂頁面
import 'package:palette_generator/palette_generator.dart'; // 導入調色板生成器
import 'services/just_audio_service.dart'; // 添加導入

class NowPlayingWidget extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final VoidCallback onClose;
  final String imageUrl; // 新增參數：歌曲圖片URL
  final Color backgroundColor; // 新增參數：背景顏色
  final String? previewUrl; // 添加預覽URL參數

  const NowPlayingWidget({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.onClose,
    required this.imageUrl, // 必要參數
    this.backgroundColor = Colors.blue, // 默認顏色
    this.previewUrl, // 可為null的預覽URL
  });

  @override
  State<NowPlayingWidget> createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Color _extractedColor = Colors.blue; // 默認顏色
  bool _isColorExtracted = false;

  final AudioPlayerService audioPlayerService =
      AudioPlayerService(); // 初始化音頻播放器服務

  // 當前歌曲狀態
  String _currentTitle = '';
  String _currentArtist = '';
  String _currentImageUrl = '';
  String? _currentPreviewUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 旋轉一圈的時間
    )..repeat(); // 無限旋轉

    // 初始化本地狀態
    _currentTitle = widget.songTitle;
    _currentArtist = widget.artistName;
    _currentImageUrl = widget.imageUrl;
    _currentPreviewUrl = widget.previewUrl;

    // 添加對當前歌曲變化的監聽
    audioPlayerService.currentSong.addListener(_updateCurrentSong);

    // 當組件初始化時提取顏色
    _extractColorFromImage();
  }

  void _updateCurrentSong() {
    final currentSong = audioPlayerService.currentSong.value;
    if (currentSong != null && mounted) {
      setState(() {
        _currentTitle = currentSong.title;
        _currentArtist = currentSong.artist;
        _currentImageUrl = currentSong.imageUrl;
        _currentPreviewUrl = currentSong.previewUrl;
        // 使用當前歌曲的背景色
        _extractedColor = currentSong.backgroundColor;
      });
    }
  }

  @override
  void didUpdateWidget(NowPlayingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果圖片URL變更，重新提取顏色
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColorFromImage();
    }
  }

  // 從圖片提取顏色 - 與 music_page 邏輯相似但色調更暗
  Future<void> _extractColorFromImage() async {
    if (widget.imageUrl.isEmpty) return;

    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.imageUrl),
      );

      setState(() {
        // 獲取主色調
        Color extractedColor =
            paletteGenerator.dominantColor?.color ?? Colors.black87;

        // 將顏色調暗
        _extractedColor = _darkenColor(extractedColor);
        _isColorExtracted = true;
      });
    } catch (e) {
      debugPrint('提取顏色時出錯: $e');
    }
  }

  // 調暗顏色方法
  Color _darkenColor(Color color) {
    // 降低 RGB 分量以使顏色更暗
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }

  @override
  void dispose() {
    audioPlayerService.currentSong.removeListener(_updateCurrentSong);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用提取的顏色或默認顏色
    final Color backgroundColor =
        _isColorExtracted ? _extractedColor : widget.backgroundColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPage(
              songTitle: _currentTitle, // 使用當前歌曲標題
              artistName: _currentArtist, // 使用當前歌手
              imageUrl: _currentImageUrl, // 使用當前圖片
              musicUrl: _currentPreviewUrl ?? '', // 使用當前預覽URL
            ),
          ),
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
          decoration: BoxDecoration(
            color: backgroundColor, // 使用提取的顏色
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(3, 5), // 右下方陰影
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(-2, 3), // 左下方陰影
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              RotationTransition(
                turns: _controller, // 使用動畫控制器實現旋轉
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: _currentImageUrl.isNotEmpty
                      ? NetworkImage(_currentImageUrl) // 使用網絡圖片
                      : const AssetImage('assets/image/record.png')
                          as ImageProvider, // 備用圖片
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTitle, // 使用當前標題
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1, // 明確設置最大行數為 1
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentArtist, // 使用當前藝術家
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1, // 明確設置最大行數為 1
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
