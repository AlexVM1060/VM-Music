
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:myapp/models/downloaded_video.dart';

class OfflineVideoPlayerPage extends StatefulWidget {
  final DownloadedVideo video;

  const OfflineVideoPlayerPage({super.key, required this.video});

  @override
  _OfflineVideoPlayerPageState createState() => _OfflineVideoPlayerPageState();
}

class _OfflineVideoPlayerPageState extends State<OfflineVideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.video.filePath);
      if (!await file.exists()) {
        throw Exception('El archivo de vídeo no existe en la ruta especificada.');
      }
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al reproducir: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el vídeo: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: _buildPlayer(),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }
    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }
    return const Text('Error desconocido', style: TextStyle(color: Colors.red));
  }
}
