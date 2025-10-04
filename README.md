# 音樂中心
![Flutter](https://img.shields.io/badge/Flutter-3.x%2B-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x%2B-blue?logo=dart)

![專案封面](https://miro.medium.com/v2/resize:fit:4800/format:webp/1*uGIRWbFYb7JYKTlY3_grNQ.png)

## 教學影片與參考文章
- 展示影片： https://streamable.com/jlx1wo
- 教學文章（Medium）： https://medium.com/%E6%B5%B7%E5%A4%A7-ios-app-%E7%A8%8B%E5%BC%8F%E8%A8%AD%E8%A8%88/4-flutter-%E9%9F%B3%E6%A8%82%E4%B8%AD%E5%BF%83-d675b5923a64

## 目錄
- [功能特色](#功能特色)
- [技術堆疊](#技術堆疊)
- [安裝指南](#安裝指南)
- [專案結構](#專案結構)
- [使用說明](#使用說明)

## 功能特色
- 播放/暫停/跳轉基本播放控制
- 播放清單與曲目瀏覽
- 了解喜愛藝人與最近常聽的歌在 Spotify
- 音檔資源集中管理

## 技術堆疊
- 前端框架：Flutter
- 程式語言：Dart
- 音訊播放：just_audio、audio_service

## 安裝指南

### 必要條件
- Flutter (stable) 3.x+
- Dart 3.x+
- Android Studio / Xcode（依目標平台）
- 建議在專案根目錄執行：`flutter --version` 確認環境

### 安裝步驟
1. 取得專案原始碼
   - 將此專案下載至本機或以 Git 方式取得
2. 安裝相依
   - `flutter pub get`
3. 執行 App
   - Android: `flutter run -d android`
   - iOS: `flutter run -d ios`
4. 常用指令
   - 格式化：`dart format .`
   - 靜態分析：`flutter analyze`
   - 測試：`flutter test`
5. 資源與設定
   - 確認 `pubspec.yaml` 的 `assets:` 正確宣告（如 audio/images）
   - 若需環境變數，使用 `--dart-define` 注入（例：`flutter run --dart-define=API_BASE_URL=https://example.com`）
   - 加入 API 金鑰（必要）：
     - 在程式中宣告（擇一）：
       ```dart
       static const String authorizationHeader = '<YOUR_AUTHORIZATION_HEADER>';
       static const String refreshToken = '<YOUR_REFRESH_TOKEN>';
       static const String cookieValue = '<YOUR_COOKIE_VALUE>';
       ```
     - 或以 --dart-define 在執行時注入：
       ```bash
       flutter run \
         --dart-define=authorizationHeader=<YOUR_AUTHORIZATION_HEADER> \
         --dart-define=refreshToken=<YOUR_REFRESH_TOKEN> \
         --dart-define=cookieValue=<YOUR_COOKIE_VALUE>
       ```
   - 若使用第三方播放器套件（如 just_audio / audio_service），請依其平台設定文件完成 iOS/Android 設定

## 專案結構
```
/lib
├── main.dart                           # 應用程式
├── services/                           # 服務層
│   ├── just_audio_service.dart         # 音樂服務
│   └── spotify_service.dart            # 呼叫 Spotify API 相關服務
├── models/                             # 資料模型
├── widgets/                            # 通用組件
└── (pages)                             # 其餘介面
```

## 使用說明
1. 瀏覽曲目或播放清單後選擇歌曲
2. 使用播放器進行播放/暫停/跳轉等控制
3. 管理播放清單與瀏覽曲目資訊
4. 查看 Spotify 喜愛藝人與最近常聽內容

