import 'dart:developer' as developer;
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
        mute: false, // Solución temporal: Activa el audio del reproductor principal
      ),
    )..addListener(_onPlayerStateChange);

    // Ya no llamamos a la función que da error 403
    // _fetchVideoInfoAndPlay();
  }

  void _onPlayerStateChange() {
    if (_controller.value.isReady && mounted) {
      setState(() {
        _videoTitle = _controller.metadata.title;
      });
    }
  }

  // --- Código para reproducción en segundo plano (DESACTIVADO TEMPORALMENTE) ---
  // Future<void> _fetchVideoInfoAndPlay() async {
  //   final yt = YoutubeExplode();
  //   try {
  //     final video = await yt.videos.get(widget.videoId);
  //     final manifest = await yt.videos.streamsClient.getManifest(widget.videoId);
  //     final audioUrl = manifest.audioOnly.withHighestBitrate().url;
  //
  //     final mediaItem = MediaItem(
  //       id: audioUrl.toString(),
  //       title: video.title,
  //       artist: video.author,
  //       artUri: Uri.parse(video.thumbnails.highResUrl),
  //     );
  //
  //     await audioHandler.addQueueItem(mediaItem);
  //     audioHandler.play();
  //
  //     if (mounted) {
  //       setState(() {
  //         _videoTitle = video.title;
  //       });
  //     }
  //   } catch (e, s) {
  //     developer.log(
  //       'Error al obtener la información del vídeo.',
  //       name: 'VideoPlayerPage',
  //       error: e,
  //       stackTrace: s,
  //     );
  //
  //     if (mounted) {
  //       setState(() {
  //         _videoTitle = 'Error al cargar el vídeo';
  //       });
  //     }
  //   } finally {
  //     yt.close();
  //   }
  // }
  // --------------------------------------------------------------------------

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
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    // Ya no es necesario, el audio se detiene con el reproductor
    // audioHandler.stop(); 
    super.dispose();
  }
}
