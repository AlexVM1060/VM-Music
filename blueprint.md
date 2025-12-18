
# Visor de Vídeos de YouTube con Estilo iOS

## Descripción General

Esta aplicación permite a los usuarios buscar y ver vídeos de YouTube directamente dentro de la aplicación de Flutter, con una interfaz de usuario diseñada para imitar la apariencia nativa de iOS utilizando los widgets de Cupertino.

## Funcionalidades

*   **Búsqueda de Vídeos:** Un campo de texto de estilo iOS permite a los usuarios buscar vídeos.
*   **Lista de Resultados:** Muestra una lista de vídeos con miniaturas y títulos, con un diseño similar a las listas de iOS.
*   **Reproducción de Vídeos:** Al tocar un vídeo, se reproduce en el reproductor de YouTube integrado.
*   **Indicadores Nativos:** Utiliza indicadores de actividad de iOS.

## Plan Actual

1.  **Refactorización a Cupertino:**
    *   Reemplazar `MaterialApp` con `CupertinoApp`.
    *   Cambiar `Scaffold` por `CupertinoPageScaffold`.
    *   Sustituir `AppBar` por `CupertinoNavigationBar`.
    *   Convertir `TextField` a `CupertinoTextField`.
    *   Cambiar `ElevatedButton` por `CupertinoButton`.
    *   Reemplazar `CircularProgressIndicator` por `CupertinoActivityIndicator`.
    *   Ajustar el diseño de la lista de resultados para que se asemeje al estilo de iOS.
2.  **Verificación y Pruebas:**
    *   Asegurarse de que toda la funcionalidad (búsqueda, reproducción) siga funcionando correctamente.
    *   Verificar que el diseño se vea limpio y nativo en un dispositivo o simulador de iOS.
