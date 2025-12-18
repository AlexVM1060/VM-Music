
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

1.  **Reestructurar la UI para Pestañas:**
    *   Añadir los paquetes `path_provider`, `just_audio` y `permission_handler` a `pubspec.yaml`.
    *   Convertir la estructura principal a un `CupertinoTabScaffold`.
    *   Crear dos archivos separados: `search_page.dart` para la búsqueda y `downloads_page.dart` para las descargas.
    *   Mover la lógica de búsqueda existente a `search_page.dart`.

2.  **Implementar Funcionalidad de Descarga:**
    *   Añadir un botón de descarga a cada elemento de la lista en `search_page.dart`.
    *   Al pulsar, usar `youtube_explode_dart` para obtener el stream de audio.
    *   Usar `path_provider` para determinar la ruta de guardado.
    *   Gestionar el proceso de descarga y guardado del archivo.
    *   Mostrar un indicador de progreso de descarga.

3.  **Construir la Pantalla de Descargas (`downloads_page.dart`):**
    *   Al iniciar, escanear el directorio de la aplicación para encontrar archivos de audio (`.m4a`).
    *   Mostrar los archivos encontrados en una lista.
    *   Implementar un reproductor de audio usando `just_audio`.
    *   Al tocar un archivo, cargarlo en el reproductor y comenzar la reproducción.
    *   Diseñar una UI para el reproductor (play/pause, barra de progreso, título).
