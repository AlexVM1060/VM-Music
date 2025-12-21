import 'package:flutter/material.dart';

// Gestor de estado simplificado para el reproductor de vídeo
class VideoPlayerManager extends ChangeNotifier {
  String? _currentVideoId;
  bool _isMinimized = false;

  String? get currentVideoId => _currentVideoId;
  bool get isMinimized => _isMinimized;

  // Inicia la reproducción de un vídeo
  void play(String videoId) {
    _currentVideoId = videoId;
    _isMinimized = false;
    notifyListeners();
  }

  // Minimiza el reproductor
  void minimize() {
    if (!_isMinimized) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  // Maximiza el reproductor
  void maximize() {
    if (_isMinimized) {
      _isMinimized = false;
      notifyListeners();
    }
  }

  // Cierra el reproductor
  void close() {
    _currentVideoId = null;
    _isMinimized = false;
    notifyListeners();
  }
}
