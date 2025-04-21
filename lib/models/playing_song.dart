import 'package:flutter/material.dart';

class PlayingSong {
  final int? id;
  final String title;
  final String artist;
  final String imageUrl;
  final Color backgroundColor;
  final String? previewUrl;
  final String? lyrics;

  const PlayingSong({
    this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.backgroundColor = Colors.blue,
    this.previewUrl,
    this.lyrics,
  });

  PlayingSong copyWith({
    int? id,
    String? title,
    String? artist,
    String? imageUrl,
    Color? backgroundColor,
    String? previewUrl,
    String? lyrics,
  }) {
    return PlayingSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      previewUrl: previewUrl ?? this.previewUrl,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  // 從Song建立PlayingSong的工廠建構方法
  factory PlayingSong.fromSong(PlayingSong song,
      {Color backgroundColor = Colors.blue}) {
    return PlayingSong(
      id: song.id,
      title: song.title,
      artist: song.artist,
      imageUrl: song.imageUrl,
      backgroundColor: backgroundColor,
      previewUrl: song.previewUrl,
      lyrics: song.lyrics,
    );
  }
}
