import 'package:flutter/material.dart';

// Gestor de estado para el reproductor de vídeo.
// Utiliza ChangeNotifier para notificar a los widgets cuando hay cambios.
class VideoPlayerManager extends ChangeNotifier {
  String? _currentVideoId;
  bool _isMinimized = false;
  bool _isFullScreen = false;

  // Getter para saber el ID del vídeo actual
  String? get currentVideoId => _currentVideoId;

  // Getter para saber si el reproductor está minimizado
  bool get isMinimized => _isMinimized;

  // Getter para saber si el reproductor está en pantalla completa
  bool get isFullScreen => _isFullScreen;

  // Función para iniciar la reproducción de un nuevo vídeo
  void play(String videoId) {
    _currentVideoId = videoId;
    _isMinimized = false; // Siempre empieza en grande
    _isFullScreen = false; // Y no en pantalla completa
    notifyListeners(); // Notifica a los widgets que el estado ha cambiado
  }

  // Función para minimizar el reproductor
  void minimize() {
    if (!_isMinimized) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  // Función para maximizar el reproductor
  void maximize() {
    if (_isMinimized) {
      _isMinimized = false;
      notifyListeners();
    }
  }

  // Función para cerrar el reproductor
  void close() {
    _currentVideoId = null;
    _isMinimized = false;
    _isFullScreen = false;
    notifyListeners();
  }

  // Función para actualizar el estado de la pantalla completa
  void setFullScreen(bool isFullScreen) {
    if (_isFullScreen != isFullScreen) {
      _isFullScreen = isFullScreen;
      notifyListeners();
    }
  }
}
