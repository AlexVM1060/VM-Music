
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';

// Centraliza el manejo del estado del reproductor y el ciclo de vida de la app.
class VideoPlayerManager extends ChangeNotifier with WidgetsBindingObserver {
  final HistoryService _historyService = HistoryService();
  final AudioHandler _audioHandler;

  String? _currentVideoId;
  bool _isMinimized = false;
  bool _isFullScreen = false;

  VideoPlayerController? _videoPlayerController;
  String? _videoStreamUrl;
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoChannelTitle;
  bool _isLocal = false;
  bool _isInBackground = false;

  // Constructor
  VideoPlayerManager(this._audioHandler);

  // Getters
  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;
  bool get isInBackground => _isInBackground;

  // Inicializador para el observador del ciclo de vida
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController?.dispose();
    _audioHandler.stop();
    super.dispose();
  }

  // MÉTODO DE CICLO DE VIDA CENTRALIZADO Y CORREGIDO
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden: // Caso añadido para ser exhaustivo
        // Si hay un video cargado (reproduciendo o pausado), pasa a modo audio.
        if (_videoPlayerController != null && !_isInBackground) {
          switchToBackgroundAudio();
        }
        break;
      case AppLifecycleState.resumed:
        // Si estábamos en modo audio, vuelve al video.
        if (_isInBackground) {
          switchToForegroundVideo();
        }
        break;
    }
  }

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
      await close(); // Cierra completamente el video anterior
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
    if (_videoPlayerController == null || _videoStreamUrl == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }
    if (_isInBackground) return;

    _isInBackground = true;
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
    notifyListeners();
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
    await _videoPlayerController?.dispose();
    await _audioHandler.stop();

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
}
