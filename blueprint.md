# YouTube Music Downloader - Estilo iOS

## Descripción General

Esta aplicación permite a los usuarios buscar vídeos de YouTube, descargarlos como archivos de audio y reproducirlos sin conexión a través de un reproductor integrado. La interfaz está diseñada con los widgets de Cupertino para una experiencia nativa en iOS.

## Funcionalidades

*   **Navegación por Pestañas:** Una interfaz clara con dos secciones: "Buscar" y "Descargas".
*   **Búsqueda de Vídeos:** Permite a los usuarios buscar cualquier vídeo en YouTube.
*   **Descarga de Audio:** Un botón en cada resultado de búsqueda para descargar el vídeo como un archivo de audio (formato M4A).
*   **Lista de Descargas:** Una pestaña dedicada que muestra todos los audios descargados, listos para reproducir.
*   **Reproductor de Audio Integrado:** Permite reproducir, pausar y ver el progreso de los audios descargados sin salir de la aplicación.
*   **Reproducción de Vídeo Online:** Tocar la miniatura de un vídeo en los resultados de búsqueda lo reproduce directamente.

## Plan Actual

El objetivo es rediseñar completamente la experiencia de reproducción de vídeo para que se asemeje a la de YouTube e incluya la capacidad de reproducción de audio en segundo plano.

1.  **Añadir Dependencias Clave:**
    *   `youtube_player_flutter:` Para la interfaz del reproductor de vídeo.
    *   `audio_service` & `just_audio:` Para la gestión del audio en segundo plano.
    *   `youtube_explode_dart:` Para extraer los datos y streams del vídeo.

2.  **Configurar Plataformas para Background Playback:**
    *   **iOS:** Añadir `UIBackgroundModes` (`audio`) al archivo `Info.plist`.
    *   **Android:** Añadir el permiso `WAKE_LOCK` y declarar el servicio de `audio_service` en el `AndroidManifest.xml`.

3.  **Implementar un `AudioHandler` para `audio_service`:**
    *   Crear un servicio (`lib/audio_handler.dart`) que gestione la lógica del reproductor `just_audio` (cargar, reproducir, pausar, buscar) y comunique su estado al sistema operativo para los controles de la pantalla de bloqueo.

4.  **Reconstruir la Pantalla del Reproductor (`video_player_page.dart`):**
    *   Usar `youtube_explode_dart` para obtener el título del vídeo y la URL del stream de audio de mayor calidad.
    *   Inicializar el `AudioHandler` para que comience a reproducir el stream de audio en segundo plano.
    *   Implementar el widget `YoutubePlayer` en la parte superior de la pantalla para la visualización del vídeo.
    *   Asegurarse de que el `YoutubePlayer` esté silenciado (`mute: true`) para que no haya doble audio, ya que `audio_service` se encargará del sonido.
    *   Mostrar el título del vídeo debajo del reproductor.
    *   El widget `YoutubePlayer` proporcionará de forma nativa los controles de reproducción y el botón de pantalla completa.
