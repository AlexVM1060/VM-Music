import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Gestor de estado para el reproductor de vídeo.
// Utiliza ChangeNotifier para notificar a los widgets cuando hay cambios.
class VideoPlayerManager extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  String? _currentVideoId;
  bool _isMinimized = false;
  bool _isFullScreen = false;

  // Nuevas propiedades para el audio en segundo plano
  final AudioHandler _audioHandler;
  VideoPlayerController? _videoPlayerController;
  String? _videoStreamUrl;
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoChannelTitle;
  bool _isInBackground = false; // Flag para saber si está en modo audio de fondo

  VideoPlayerManager(this._audioHandler); // Inyectar AudioHandler

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;

  // Función para registrar los datos del reproductor cuando está listo
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

  // Función para iniciar la reproducción de un nuevo vídeo
  Future<void> play(String videoId) async {
    if (_currentVideoId != null) {
      close(); // Cierra el vídeo y audio actual si lo hay
    }
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

    // Save to history
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

  // Cambia a modo de solo audio en segundo plano
  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null ||
        _videoStreamUrl == null ||
        !_videoPlayerController!.value.isPlaying) {
      return;
    }

    final position = await _videoPlayerController!.position;
    if (position == null) return;

    // Pausa el vídeo
    await _videoPlayerController!.pause();

    // Inicia el audio en segundo plano con audio_service
    final mediaItem = MediaItem(
      id: _videoStreamUrl!,
      title: _videoTitle ?? 'Video sin título',
      artist: _videoChannelTitle,
      artUri: _videoThumbnailUrl != null ? Uri.parse(_videoThumbnailUrl!) : null,
      duration: _videoPlayerController!.value.duration,
    );
    // Pasamos el item a la cola y buscamos la posición correcta
    await _audioHandler.addQueueItem(mediaItem);
    await _audioHandler.seek(position);
    await _audioHandler.play();

    _isInBackground = true;
  }

  // Vuelve a la reproducción de vídeo en primer plano
  Future<void> switchToForegroundVideo() async {
    if (!_isInBackground || _videoPlayerController == null) return;

    // Obtiene la posición actual del audio en segundo plano
    final backgroundPosition = _audioHandler.playbackState.value.updatePosition;

    // Detiene el audio en segundo plano
    await _audioHandler.stop();

    // Reanuda el vídeo desde la posición correcta
    await _videoPlayerController!.seekTo(backgroundPosition);
    await _videoPlayerController!.play();

    _isInBackground = false;
  }

  // Función para minimizar el reproductor (modo PiP)
  void minimize() {
    if (!_isMinimized) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  // Función para maximizar el reproductor desde el modo PiP
  void maximize() {
    if (_isMinimized) {
      _isMinimized = false;
      notifyListeners();
    }
  }

  // Función para cerrar el reproductor
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
