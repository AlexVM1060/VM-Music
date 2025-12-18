
# Visor de Vídeos de YouTube

## Descripción General

Esta aplicación permite a los usuarios ver vídeos de YouTube directamente dentro de la aplicación de Flutter. La aplicación utilizará el paquete `youtube_player_flutter` para mostrar el reproductor de vídeo.

## Funcionalidades

*   **Reproductor de YouTube Integrado:** Muestra un reproductor de vídeo de YouTube en la pantalla principal.
*   **Controles de Reproducción:** Permite a los usuarios reproducir, pausar, y controlar el vídeo.
*   **Interfaz Sencilla:** Una interfaz de usuario limpia y sencilla con una barra de aplicación y el reproductor de vídeo.

## Plan Actual

1.  **Agregar Dependencia:** Añadir el paquete `youtube_player_flutter` a `pubspec.yaml`.
2.  **Crear la Interfaz de Usuario:**
    *   Crear un `StatefulWidget` para gestionar el estado del reproductor de vídeo.
    *   Inicializar un `YoutubePlayerController` con una URL de vídeo predeterminada.
    *   Añadir el widget `YoutubePlayer` al árbol de widgets.
    *   Diseñar una pantalla simple con un `Scaffold` y un `AppBar`.
3.  **Verificar y Probar:** Asegurarse de que el código compila sin errores y que el vídeo se reproduce correctamente en el emulador o la web.

