import 'package:flutter/material.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/services/playlist_service.dart';
import 'package:myapp/video_player_manager.dart'; 
import 'package:provider/provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlaylist.name),
      ),
      body: _currentPlaylist.videos.isEmpty
          ? const Center(child: Text('Esta playlist no contiene videos.'))
          : ListView.builder(
              itemCount: _currentPlaylist.videos.length,
              itemBuilder: (context, index) {
                final video = _currentPlaylist.videos[index];
                return ListTile(
                  leading: Image.network(video.thumbnailUrl),
                  title: Text(video.title),
                  subtitle: Text(video.channelTitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await playlistService.removeVideoFromPlaylist(_currentPlaylist.name, video.videoId);
                      setState(() {
                        _currentPlaylist.videos.removeAt(index);
                      });
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video eliminado de la playlist')),
                      );
                    },
                  ),
                  onTap: () {
                    Provider.of<VideoPlayerManager>(context, listen: false).play(video.videoId);
                  },
                );
              },
            ),
    );
  }
}
