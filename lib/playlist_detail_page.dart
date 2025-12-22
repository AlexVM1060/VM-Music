import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/offline_video_player_page.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/services/playlist_service.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Playlist _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = Playlist(
      name: widget.playlist.name,
      videos: List.from(widget.playlist.videos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    final downloadService = Provider.of<DownloadService>(context);
    final videoManager = Provider.of<VideoPlayerManager>(context, listen: false);
    final isAutoDownload = downloadService.isPlaylistAutoDownload(_currentPlaylist.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Descargar todo',
            onPressed: () {
              final videosToDownload = _currentPlaylist.videos.map((videoHistory) => Video(
                videoId: videoHistory.videoId,
                title: videoHistory.title,
                thumbnailUrl: videoHistory.thumbnailUrl,
                channelTitle: videoHistory.channelTitle,
              )).toList();
              downloadService.downloadPlaylistVideos(videosToDownload);
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
              downloadService.setPlaylistAutoDownload(_currentPlaylist.name, value);
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
                return _currentPlaylist.videos.isEmpty
                    ? const Center(child: Text('Esta playlist no contiene videos.'))
                    : ListView.builder(
                        itemCount: _currentPlaylist.videos.length,
                        itemBuilder: (context, index) {
                          final video = _currentPlaylist.videos[index];
                          final downloadedVideo = downloadedVideos.firstWhereOrNull(
                            (v) => v.videoId == video.videoId,
                          );

                          Widget leadingWidget;
                          if (downloadedVideo != null) {
                            leadingWidget = Image.file(File(downloadedVideo.localThumbnailPath), width: 100, fit: BoxFit.cover);
                          } else {
                            leadingWidget = Image.network(video.thumbnailUrl, width: 100, fit: BoxFit.cover);
                          }

                          return ListTile(
                            leading: leadingWidget,
                            title: Text(video.title),
                            subtitle: Text(video.channelTitle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (downloadedVideo != null)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await playlistService.removeVideoFromPlaylist(
                                        _currentPlaylist.name, video.videoId);

                                    if (!context.mounted) return;

                                    setState(() {
                                      _currentPlaylist.videos.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Video eliminado de la playlist')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              if (downloadedVideo != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OfflineVideoPlayerPage(video: downloadedVideo),
                                  ),
                                );
                              } else {
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
