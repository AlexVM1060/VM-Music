
import 'package:flutter/material.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:myapp/offline_video_player_page.dart'; // Importar la nueva página
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class PlaylistDetailsPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final downloadService = Provider.of<DownloadService>(context);
    final videoManager = Provider.of<VideoPlayerManager>(context, listen: false);
    final isAutoDownload = downloadService.isPlaylistAutoDownload(playlist.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Descargar todo',
            onPressed: () {
              downloadService.downloadPlaylistVideos(playlist.videos);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando descarga de la playlist...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Descarga automática'),
            subtitle: const Text('Los nuevos vídeos se descargarán automáticamente'),
            value: isAutoDownload,
            onChanged: (bool value) {
              downloadService.setPlaylistAutoDownload(playlist.name, value);
            },
          ),
          Expanded(
            child: FutureBuilder<List<DownloadedVideo>>(
              future: downloadService.getDownloadedVideos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final downloadedVideos = snapshot.data!;
                return ListView.builder(
                  itemCount: playlist.videos.length,
                  itemBuilder: (context, index) {
                    final video = playlist.videos[index];
                    final downloadedVideo = downloadedVideos.firstWhereOrNull(
                      (v) => v.videoId == video.videoId,
                    );

                    return ListTile(
                      leading: Image.network(video.thumbnailUrl, width: 100, fit: BoxFit.cover),
                      title: Text(video.title),
                      subtitle: Text(video.channelTitle),
                      trailing: downloadedVideo != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        if (downloadedVideo != null) {
                          // Navegar a la página de reproducción offline
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfflineVideoPlayerPage(video: downloadedVideo),
                            ),
                          );
                        } else {
                          // Reproducir online como antes
                          videoManager.play(video.videoId);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
