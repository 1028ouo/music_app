import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'home_page.dart';
import 'library_page.dart'; // 導入新的Library頁面

Future<void> main() async {
  // 確保 Flutter 引擎已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化背景音樂服務
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_app.channel.audio',
    androidNotificationChannelName: 'Music App Audio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Music App',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'Music App'),
        '/library': (context) => const LibraryPage(), // 註冊Library頁面路由
      },
    );
  }
}
