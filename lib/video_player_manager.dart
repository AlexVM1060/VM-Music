import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';

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
  bool _isLocal = false; 

  VideoPlayerManager(this._audioHandler);

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;
  bool get isInBackground => _isInBackground;

  void setPlayerData({
    required VideoPlayerController controller,
    String? streamUrl,
    required String title,
    required String thumbnailUrl,
    required String channelTitle,
    bool isLocal = false,
  }) {
    _videoPlayerController = controller;
    _videoStreamUrl = streamUrl;
    _videoTitle = title;
    _videoThumbnailUrl = thumbnailUrl;
    _videoChannelTitle = channelTitle;
    _isLocal = isLocal;
  }

  Future<void> play(String videoId, {bool isLocalVideo = false}) async {
    if (_currentVideoId != null) {
      close();
    }
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;
    _isLocal = isLocalVideo;

    if (!_isLocal) {
      _historyService.addVideoToHistory(
        VideoHistory(
          videoId: videoId,
          title: _videoTitle ?? '',
          thumbnailUrl: _videoThumbnailUrl ?? '',
          channelTitle: _videoChannelTitle ?? '',
          watchedAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null ||
        _videoStreamUrl == null ||
        !_videoPlayerController!.value.isPlaying) {
      return;
    }
    if (_isInBackground) return;

    final position = _videoPlayerController!.value.position;
    await _videoPlayerController!.pause();

    final mediaItem = MediaItem(
      id: _videoStreamUrl!,
      title: _videoTitle ?? 'Video sin título',
      artUri: _videoThumbnailUrl != null ? Uri.parse(_videoThumbnailUrl!) : null,
      artist: _videoChannelTitle,
      extras: <String, dynamic>{'isLocal': _isLocal},
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

    if (_videoPlayerController!.value.isInitialized) {
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

  void close() {
    _videoPlayerController?.dispose();
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
    _isLocal = false;

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
    _audioHandler.stop();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
