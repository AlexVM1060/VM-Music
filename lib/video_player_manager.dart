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
  final YoutubeExplode _ytExplode = YoutubeExplode();

  String? _currentVideoId;
  VideoPlayerController? _videoPlayerController;

  // Datos del video para la transferencia
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoChannelTitle;
  Duration? _videoDuration;

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
    required String title,
    required String thumbnailUrl,
    required String channelTitle,
    required Duration duration,
  }) {
    _videoPlayerController = controller;
    _videoTitle = title;
    _videoThumbnailUrl = thumbnailUrl;
    _videoChannelTitle = channelTitle;
    _videoDuration = duration;
  }

  Future<void> play(String videoId) async {
    if (_currentVideoId != null) {
      await close();
    }
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

    try {
      final video = await _ytExplode.videos.get(videoId);
      _historyService.addVideoToHistory(
        VideoHistory(
          videoId: video.id.value,
          title: video.title,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          channelTitle: video.author,
          watchedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print("Error getting video for history: $e");
    }

    notifyListeners();
  }

  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized ||
        _currentVideoId == null) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    await _videoPlayerController!.pause();

    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(_currentVideoId!);
      final audioUrl = manifest.audioOnly.sortByBitrate().last.url;

      // Comando atómico para preparar y reproducir
      await _audioHandler.customAction('prepareAndPlay', {
        'id': audioUrl.toString(),
        'title': _videoTitle ?? 'Video sin título',
        'artist': _videoChannelTitle,
        'artUri': _videoThumbnailUrl,
        'duration': _videoDuration?.inMilliseconds,
        'position': position.inMilliseconds,
      });

      _isInBackground = true;
    } catch (e) {
      print('Failed to switch to background audio: $e');
       // Si falla, reanuda el vídeo para no dejar al usuario en silencio
      if (_videoPlayerController != null && mounted) {
        await _videoPlayerController!.play();
      }
    }
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

  // Helper para saber si el manager sigue en uso
  bool _mounted = true;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    _ytExplode.close();
    close(); // Asegurarse de limpiar todo
    super.dispose();
  }
}
