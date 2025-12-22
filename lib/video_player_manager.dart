import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/video_history.dart';
import 'package:myapp/services/history_service.dart';
import 'package:video_player/video_player.dart';

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
  Duration? _videoDuration;
  bool _isLocal = false;
  bool _isInBackground = false;

  // Posición centralizada y sincronizada
  Duration _currentPosition = Duration.zero;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  VoidCallback? _videoPlayerListener;

  VideoPlayerManager(this._audioHandler);

  AudioHandler get audioHandler => _audioHandler;
  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;
  bool get isFullScreen => _isFullScreen;
  bool get isInBackground => _isInBackground;
  Duration get currentPosition => _currentPosition; // Getter para la posición

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController?.removeListener(_videoPlayerListener ?? () {});
    _videoPlayerController?.dispose();
    _playbackStateSubscription?.cancel();
    _audioHandler.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_videoPlayerController != null && !_isInBackground) {
          switchToBackgroundAudio();
        }
        break;
      case AppLifecycleState.resumed:
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
    Duration? duration,
    bool isLocal = false,
  }) {
    _videoPlayerController = controller;
    _videoStreamUrl = streamUrl;
    _videoTitle = title;
    _videoThumbnailUrl = thumbnailUrl;
    _videoChannelTitle = channelTitle;
    _videoDuration = duration;
    _isLocal = isLocal;

    // Sincronizar posición desde el reproductor de video
    _videoPlayerListener = () {
      if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
        _currentPosition = _videoPlayerController!.value.position;
      }
    };
    _videoPlayerController!.addListener(_videoPlayerListener!);

    if (!_isLocal) {
      _historyService.addVideoToHistory(
        VideoHistory(
          videoId: _currentVideoId!,
          title: _videoTitle ?? '',
          thumbnailUrl: _videoThumbnailUrl ?? '',
          channelTitle: _videoChannelTitle ?? '',
          watchedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> play(String videoId, {bool isLocalVideo = false}) async {
    if (_currentVideoId != null) {
      await close();
    }
    _currentVideoId = videoId;
    _isMinimized = false;
    _isFullScreen = false;
    _isInBackground = false;
    _isLocal = isLocalVideo;
    _currentPosition = Duration.zero; // Resetear posición

    notifyListeners();
  }

  Future<void> switchToBackgroundAudio() async {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;
    if (_isInBackground) return;

    _isInBackground = true;
    _currentPosition = _videoPlayerController!.value.position;
    await _videoPlayerController!.pause();

    final mediaItem = MediaItem(
      id: _videoStreamUrl ?? _currentVideoId!,
      title: _videoTitle ?? 'Video sin título',
      artUri: _videoThumbnailUrl != null ? Uri.parse(_videoThumbnailUrl!) : null,
      artist: _videoChannelTitle,
      duration: _videoDuration,
      extras: <String, dynamic>{'isLocal': _isLocal},
    );

    await _audioHandler.playMediaItem(mediaItem);
    await _audioHandler.seek(_currentPosition);

    // Sincronizar posición desde el audio en segundo plano
    _playbackStateSubscription = _audioHandler.playbackState.listen((playbackState) {
      _currentPosition = playbackState.updatePosition;
    });

    notifyListeners();
  }

  Future<void> switchToForegroundVideo() async {
    if (!_isInBackground || _videoPlayerController == null) return;

    // Cancelar la suscripción al estado del audio
    await _playbackStateSubscription?.cancel();
    _playbackStateSubscription = null;

    await _audioHandler.stop();

    if (_videoPlayerController!.value.isInitialized) {
      // Usar la posición sincronizada
      await _videoPlayerController!.seekTo(_currentPosition);
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
    _videoPlayerController?.removeListener(_videoPlayerListener ?? () {});
    await _videoPlayerController?.dispose();
    await _playbackStateSubscription?.cancel();
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
    _videoDuration = null;
    _isLocal = false;
    _currentPosition = Duration.zero;
    _playbackStateSubscription = null;
    _videoPlayerListener = null;

    notifyListeners();
  }

  void setFullScreen(bool isFullScreen) {
    if (_isFullScreen != isFullScreen) {
      _isFullScreen = isFullScreen;
      notifyListeners();
    }
  }
}
