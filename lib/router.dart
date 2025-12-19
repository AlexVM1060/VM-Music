import 'package:go_router/go_router.dart';
import 'package:myapp/main.dart'; // Importa el AppShell

// 1. Define la configuración del router
final GoRouter router = GoRouter(
  // 2. Define la lista de rutas de la aplicación
  routes: <RouteBase>[
    // 3. Define la ruta raíz ('/')
    GoRoute(
      path: '/',
      builder: (context, state) {
        // Esta ruta inicial apunta a la estructura principal de la app.
        return const AppShell();
      },
      // Aquí se podrían añadir sub-rutas en el futuro, por ejemplo:
      // routes: <RouteBase>[
      //   GoRoute(
      //     path: 'settings',
      //     builder: (context, state) => const SettingsPage(),
      //   ),
      // ],
    ),
  ],
);
