
# VM Player: Reproductor de Vídeo con Búsqueda y PiP

## Descripción General

VM Player es una aplicación de vídeo moderna y funcional que te permite buscar y reproducir vídeos de YouTube de una manera sencilla y elegante. La aplicación cuenta con un reproductor de vídeo flotante (Picture-in-Picture) que te permite seguir viendo tus vídeos mientras navegas por otras partes de la aplicación.

## Funcionalidades Implementadas

### Estilo y Diseño

*   **Tema Moderno:** La aplicación utiliza Material 3, con un tema oscuro y claro que se adapta a las preferencias del sistema.
*   **Tipografía Elegante:** Se utiliza `GoogleFonts` para una apariencia de texto limpia y moderna.
*   **Diseño Intuitivo:** La interfaz es limpia, con una barra de búsqueda prominente y una navegación inferior clara.

### Búsqueda de Vídeos

*   **Búsqueda en YouTube:** La aplicación utiliza la librería `youtube_explode_dart` para buscar vídeos en YouTube.
*   **Resultados Relevantes:** Muestra una lista de vídeos con sus miniaturas, títulos y canales.
*   **Navegación Sencilla:** Al tocar un vídeo, se abre el reproductor.

### Reproductor de Vídeo

*   **Reproductor Flotante (PiP):** El reproductor de vídeo puede minimizarse a una ventana flotante que permanece visible mientras navegas por la aplicación.
    *   **Arrastrable:** Puedes mover el reproductor flotante a cualquier parte de la pantalla.
    *   **Controles Básicos:** El reproductor minimizado tiene botones para cerrar o maximizar el vídeo.
*   **Reproducción en Segundo Plano:** La reproducción de audio continúa incluso cuando la aplicación está en segundo plano.
*   **Controles Avanzados:** El reproductor a pantalla completa ofrece controles completos, como reproducción/pausa, barra de progreso, control de volumen y modo de pantalla completa.
*   **Vídeos Relacionados:** Debajo del reproductor, se muestra una lista de vídeos relacionados para que puedas seguir explorando contenido.

## Plan de Implementación Actual

*   **Integración de `better_player`:** Se ha reemplazado `chewie` y `video_player` por `better_player` para una mejor gestión del modo Picture-in-Picture (PiP).
*   **Simplificación de la Gestión de Estado:** Se ha eliminado la dependencia de `audio_service` y se ha simplificado el `VideoPlayerManager` para que `better_player` se encargue de la reproducción en segundo plano.
*   **Ajuste de la Interfaz:** Se ha actualizado `video_player_page.dart` para que utilice `better_player` y muestre el botón de PiP de forma nativa.
*   **Configuración Nativa:** Se ha verificado la configuración de `build.gradle.kts` y `Info.plist` para asegurar el correcto funcionamiento del modo PiP en Android e iOS.
