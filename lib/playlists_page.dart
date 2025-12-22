import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/services/playlist_service.dart';
import 'package:provider/provider.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture =
          Provider.of<PlaylistService>(context, listen: false).getPlaylists();
    });
  }

  void _createPlaylist() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear nueva playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await Provider.of<PlaylistService>(context, listen: false)
                      .createPlaylist(controller.text);
                  
                  // Comprobación de seguridad
                  if (!context.mounted) return;
                  
                  Navigator.of(context).pop();
                  _loadPlaylists();
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Playlist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes playlists.'));
          }

          final playlists = snapshot.data!;
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.videos.length} videos'),
                onTap: () {
                  context.push('/playlist/${playlist.name}').then((_) => _loadPlaylists());
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        tooltip: 'Crear playlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}
