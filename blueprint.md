# Blueprint

## Visión general

Esta es una aplicación de reproductor de video de YouTube que permite a los usuarios buscar y ver videos. También muestra una lista de videos relacionados con el que se está reproduciendo actualmente.

## Características

*   **Búsqueda de videos:** Los usuarios pueden buscar videos de YouTube.
*   **Reproductor de video:** Los usuarios pueden ver videos de YouTube.
*   **Videos relacionados:** Muestra una lista de videos relacionados con el que se está reproduciendo actualmente.
*   **Controles de reproducción:** Los usuarios pueden reproducir, pausar y buscar videos.
*   **Pantalla completa:** Los usuarios pueden ver videos en modo de pantalla completa.
*   **Minimizar:** Los usuarios pueden minimizar el reproductor de video para seguir navegando por la aplicación.

## Plan actual

### Añadir recomendaciones de videos relacionados

*   **Objetivo:** Mostrar una lista de videos relacionados con el que se está reproduciendo actualmente.
*   **Pasos:**
    1.  Añadir el paquete `youtube_explode_dart` a `pubspec.yaml`.
    2.  Obtener los videos relacionados usando `_ytExplode.videos.getRelatedVideos()`.
    3.  Mostrar los videos relacionados en un `ListView.builder`.
    4.  Permitir a los usuarios reproducir un video relacionado tocándolo.
