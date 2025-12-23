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
  bool _isMinimized = false;
  bool _isFullScreen = false;
  bool _isInBackground = false;

  // El manager YA NO es dueño del VideoPlayerController

  VideoPlayerManager(this._audioHandler);

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;

  Future<void> play(String videoId) async {
    // 1. Notifica que se está reproduciendo un nuevo vídeo
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;

    // 2. Detiene cualquier audio de fondo que pudiera estar sonando de un vídeo anterior
    await _audioHandler.stop();

    // 3. Añade al historial
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
      // No hacer nada si falla
    }

    notifyListeners();
  }

  Future<void> switchToBackgroundAudio(VideoPlayerController videoController, Video video) async {
    if (!videoController.value.isInitialized || _currentVideoId == null) {
      return;
    }

    final position = videoController.value.position;
    await videoController.pause();

    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(_currentVideoId!);
      final audioUrl = manifest.audioOnly.sortByBitrate().last.url;

      await _audioHandler.customAction('setSource', {
        'url': audioUrl.toString(),
        'title': video.title,
        'artist': video.author,
        'artUri': video.thumbnails.mediumResUrl,
        'duration': video.duration?.inMilliseconds ?? 0,
      });

      await _audioHandler.seek(position);
      await _audioHandler.play();

      _isInBackground = true;
    } catch (e) {
      // Si algo falla, reanuda el vídeo
       await videoController.play();
    }
  }

  Future<void> switchToForegroundVideo(VideoPlayerController videoController) async {
    if (!_isInBackground) return;

    final backgroundPosition = _audioHandler.playbackState.value.updatePosition;
    await _audioHandler.pause();

    if (videoController.value.isInitialized) {
      await videoController.seekTo(backgroundPosition);
      await videoController.play();
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
    // LIMPIEZA TOTAL del manager
    _currentVideoId = null;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;
    
    // El manager ordena al AudioHandler que se detenga y libere todo
    await _audioHandler.stop();

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
    _ytExplode.close();
    close();
    super.dispose();
  }
}
