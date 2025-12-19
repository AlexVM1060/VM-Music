import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:audio_service/audio_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  String _videoTitle = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true, // El audio se maneja por el AudioHandler
      ),
    );
    _fetchVideoInfoAndPlay();
  }

  Future<void> _fetchVideoInfoAndPlay() async {
    var yt = YoutubeExplode();
    try {
      var video = await yt.videos.get(widget.videoId);
      var manifest = await yt.videos.streamsClient.getManifest(widget.videoId);
      var audioUrl = manifest.audioOnly.withHighestBitrate().url;

      var mediaItem = MediaItem(
        id: audioUrl.toString(),
        title: video.title,
        artist: video.author,
        artUri: Uri.parse(video.thumbnails.highResUrl),
      );

      await audioHandler.addQueueItem(mediaItem);
      audioHandler.play();

      if (mounted) {
        setState(() {
          _videoTitle = video.title;
        });
      }
    } finally {
      yt.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _videoTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    // Detenemos el audio si el usuario sale de la pantalla
    audioHandler.stop();
    super.dispose();
  }
}
