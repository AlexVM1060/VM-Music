import 'package:go_router/go_router.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/playlist_detail_page.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const AppShell();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'playlist/:name',
          builder: (context, state) {
            final playlistName = state.pathParameters['name']!;
            final playlist = Playlist(name: playlistName, videos: []);
            return PlaylistDetailPage(playlist: playlist);
          },
        ),
      ],
    ),
  ],
);
