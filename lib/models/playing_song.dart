import 'package:flutter/material.dart';

class PlayingSong {
  final int? id;
  final String title;
  final String artist;
  final String imageUrl;
  final Color backgroundColor;
  final String? previewUrl;

  const PlayingSong({
    this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.backgroundColor = Colors.blue,
    this.previewUrl,
  });

  PlayingSong copyWith({
    int? id,
    String? title,
    String? artist,
    String? imageUrl,
    Color? backgroundColor,
    String? previewUrl,
  }) {
    return PlayingSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      previewUrl: previewUrl ?? this.previewUrl,
    );
  }
}
