import 'package:flutter/material.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';

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
            child: playlist.videos.isEmpty
                ? const Center(child: Text('Esta playlist no tiene vídeos.'))
                : ListView.builder(
                    itemCount: playlist.videos.length,
                    itemBuilder: (context, index) {
                      final video = playlist.videos[index];
                      return ListTile(
                        leading: Image.network(video.thumbnailUrl, width: 100, fit: BoxFit.cover),
                        title: Text(video.title),
                        subtitle: Text(video.channelTitle),
                        onTap: () {
                          videoManager.play(video.videoId);
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
