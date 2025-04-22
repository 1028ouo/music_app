import '../models/playing_song.dart';

List<PlayingSong> localSongs = [
  const PlayingSong(
    id: 1,
    title: 'Good Days',
    artist: 'SZA',
    imageUrl:
        'https://i.scdn.co/image/ab67616d0000b2733097b1375ab17ae5bf302a0a',
    previewUrl: 'assets/audio/GoodDays.mp3',
  ),
  const PlayingSong(
    id: 2,
    title: 'All The Stars (with SZA)',
    artist: 'Kendrick Lamar, SZA',
    imageUrl:
        'https://i.scdn.co/image/ab67616d0000b273a8f9bf75a4f4ba99439800b3',
    previewUrl: 'assets/audio/AllTheStars.mp3', // 確保檔案存在於 assets/audio/
  ),
  const PlayingSong(
    id: 3,
    title: 'BMF',
    artist: 'SZA',
    imageUrl:
        'https://cdn-images.dzcdn.net/images/cover/e4a1c9d6f882cd797cb85413382427ae/1900x1900-000000-80-0-0.jpg',
    previewUrl: 'assets/audio/BMF.mp3', // 添加音訊文件路徑
  ),
  const PlayingSong(
    id: 4,
    title: 'luther (with sza)',
    artist: 'Kendrick Lamar, SZA',
    imageUrl:
        'https://i.scdn.co/image/ab67616d0000b273d9985092cd88bffd97653b58',
    previewUrl: 'assets/audio/luther.mp3', // 添加音訊文件路徑
  ),
  const PlayingSong(
    id: 5,
    title: 'Snooze',
    artist: 'SZA',
    imageUrl:
        'https://i.scdn.co/image/ab67616d0000b27370dbc9f47669d120ad874ec1',
    previewUrl: 'assets/audio/Snooze.mp3', // 添加音訊文件路徑
  ),
];

// 添加這行，讓 localMusicData 成為 localSongs 的別名
// 這樣 audio_player_service.dart 中的 localMusicData 引用就能正常工作
List<PlayingSong> get localMusicData => localSongs;
