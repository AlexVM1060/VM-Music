import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoPlayerManager extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  final AudioHandler _audioHandler;

  String? _currentVideoId;
  VideoPlayerController? _videoPlayerController;
  String? _videoStreamUrl;
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoChannelTitle;

  bool _isMinimized = false;
  bool _isFullScreen = false;
  bool _isInBackground = false;

  VideoPlayerManager(this._audioHandler);

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  void setVideoData({
    required VideoPlayerController controller,
    required String streamUrl,
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
      await close();
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

  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null || _videoStreamUrl == null) return;

    final position = await _videoPlayerController!.position;
    if (position == null) return;

    await _videoPlayerController!.pause();

    final mediaItem = MediaItem(
      id: _videoStreamUrl!,
      title: _videoTitle ?? 'Video sin título',
      artist: _videoChannelTitle,
      artUri: _videoThumbnailUrl != null ? Uri.parse(_videoThumbnailUrl!) : null,
      duration: _videoPlayerController!.value.duration,
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

    if (_videoPlayerController?.value.isInitialized ?? false) {
      await _videoPlayerController!.seekTo(backgroundPosition);
      await _videoPlayerController!.play();
    }

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

  Future<void> close() async {
    await _videoPlayerController?.pause();
    await _audioHandler.stop();

    _currentVideoId = null;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

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
