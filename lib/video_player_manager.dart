import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoPlayerManager extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  String? _currentVideoId;
  bool _isMinimized = false;
  bool _isFullScreen = false;

  final AudioHandler _audioHandler;
  VideoPlayerController? _videoPlayerController;
  String? _videoStreamUrl;
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoChannelTitle;
  bool _isInBackground = false;

  VideoPlayerManager(this._audioHandler);

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;

  void setPlayerData({
    required VideoPlayerController controller,
    String? streamUrl,
    required String title,
    required String thumbnailUrl,
    required String channelTitle,
  }) {
    _videoPlayerController = controller;
    _videoStreamUrl = streamUrl;
    _videoTitle = title;
    _videoThumbnailUrl = thumbnailUrl;
    _videoChannelTitle = channelTitle;
  }

  Future<void> play(String videoId) async {
    if (_currentVideoId != null) {
      close();
    }
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(videoId);
      _historyService.addVideoToHistory(
        VideoHistory(
          videoId: video.id.value,
          title: video.title,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          channelTitle: video.author,
          watchedAt: DateTime.now(),
        ),
      );
    } finally {
      yt.close();
    }

    notifyListeners();
  }

  Future<void> playLocal(DownloadedVideo video) async {
    if (_currentVideoId != null) {
      close();
    }
    _currentVideoId = video.videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

    // Inicia la reproducción desde el archivo local
    _videoPlayerController = VideoPlayerController.file(File(video.filePath));
    await _videoPlayerController!.initialize();

    setPlayerData(
      controller: _videoPlayerController!,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      channelTitle: video.channelTitle,
    );

    notifyListeners();
    _videoPlayerController!.play();
  }

  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null ||
        _videoStreamUrl == null ||
        !_videoPlayerController!.value.isPlaying) {
      return;
    }

    final position = await _videoPlayerController!.position;
    if (position == null) return;

    await _videoPlayerController!.pause();

    final mediaItem = MediaItem(
      id: _videoStreamUrl!,
      title: _videoTitle ?? 'Video sin título',
    );
    await _audioHandler.addQueueItem(mediaItem);
    await _audioHandler.seek(position);
    await _audioHandler.play();

    _isInBackground = true;
  }

  Future<void> switchToForegroundVideo() async {
    if (!_isInBackground || _videoPlayerController == null) return;

    final backgroundPosition = _audioHandler.playbackState.value.updatePosition;

    await _audioHandler.stop();

    await _videoPlayerController!.seekTo(backgroundPosition);
    await _videoPlayerController!.play();

    _isInBackground = false;
  }

  void minimize() {
    if (!_isMinimized) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  void maximize() {
    if (_isMinimized) {
      _isMinimized = false;
      notifyListeners();
    }
  }

  void close() {
    _videoPlayerController?.pause();
    _audioHandler.stop();

    _currentVideoId = null;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;
    _videoPlayerController = null;
    _videoStreamUrl = null;
    _videoTitle = null;
    _videoThumbnailUrl = null;
    _videoChannelTitle = null;

    notifyListeners();
  }

  void setFullScreen(bool isFullScreen) {
    if (_isFullScreen != isFullScreen) {
      _isFullScreen = isFullScreen;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
