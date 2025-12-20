import 'dart:async';
import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final _ytExplode = YoutubeExplode();
  List<Video> _relatedVideos = [];
  String _videoTitle = '';
  Offset _dragOffset = const Offset(200, 400);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(widget.videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();

      if (streamInfo.url.toString().isEmpty) {
        throw Exception('No valid stream URL found');
      }

      _videoPlayerController = VideoPlayerController.networkUrl(streamInfo.url);
      await _videoPlayerController?.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
          allowedScreenSleep: false,
          autoInitialize: true,
        );

        setState(() {
          _isLoading = false;
        });

        _fetchRelatedVideos();
        _fetchVideoTitle();
      }
    } catch (e) {
      log('Error initializing player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir el video: $e')),
        );
        // Cierra el reproductor si hay un error de inicialización
        Provider.of<VideoPlayerManager>(context, listen: false).close();
      }
    }
  }

  Future<void> _fetchVideoTitle() async {
    try {
      final video = await _ytExplode.videos.get(VideoId(widget.videoId));
      if (mounted) {
        setState(() {
          _videoTitle = video.title;
        });
      }
    } catch (e) {
      log('Error fetching video title: $e');
    }
  }

  Future<void> _fetchRelatedVideos() async {
    try {
      final video = await _ytExplode.videos.get(VideoId(widget.videoId));
      final relatedVideos = await _ytExplode.videos.getRelatedVideos(video);
      if (mounted) {
        setState(() {
          _relatedVideos = relatedVideos?.toList() ?? [];
        });
      }
    } catch (e) {
      log('Error fetching related videos: $e');
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    _ytExplode.close();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    final manager = Provider.of<VideoPlayerManager>(context);
    final isMinimized = manager.isMinimized;

    const double minimizedWidth = 250.0;
    const double minimizedHeight = 140.6;

    // Si está cargando y no está minimizado, muestra el indicador de carga
    if (_isLoading && !isMinimized) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    // Si hubo un error y no hay controlador, no muestra nada.
    if (_chewieController == null) {
      return const SizedBox.shrink();
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: isMinimized ? _dragOffset.dy : 0,
      left: isMinimized ? _dragOffset.dx : 0,
      right: isMinimized ? null : 0,
      bottom: isMinimized ? null : 0,
      child: Draggable(
        feedback: Material(
          elevation: 8.0,
          child: _buildMinimizedLayout(minimizedWidth, minimizedHeight),
        ),
        maxSimultaneousDrags: isMinimized ? 1 : 0,
        onDragEnd: (details) {
          final size = MediaQuery.of(context).size;
          double dx = details.offset.dx;
          double dy = details.offset.dy;

          if (dx < 0) dx = 0;
          if (dx > size.width - minimizedWidth) dx = size.width - minimizedWidth;
          if (dy < 0) dy = 0;
          if (dy > size.height - minimizedHeight) dy = size.height - minimizedHeight;

          setState(() {
            _dragOffset = Offset(dx, dy);
          });
        },
        child: _buildPlayerContent(isMinimized, minimizedWidth, minimizedHeight),
      ),
    );
  }

  Widget _buildPlayerContent(bool isMinimized, double minWidth, double minHeight) {
    final manager = Provider.of<VideoPlayerManager>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: isMinimized ? manager.maximize : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isMinimized ? minWidth : screenSize.width,
        height: isMinimized ? minHeight : screenSize.height,
        child: Material(
          elevation: 4.0,
          child: isMinimized ? _buildMinimizedLayout(minWidth, minHeight) : _buildMaximizedLayout(),
        ),
      ),
    );
  }

  Widget _buildMaximizedLayout() {
    final manager = Provider.of<VideoPlayerManager>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: manager.minimize,
                    child: const Icon(CupertinoIcons.chevron_down, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _videoTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Related Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _relatedVideos.length,
                itemBuilder: (context, index) {
                  final video = _relatedVideos[index];
                  return InkWell(
                    onTap: () {
                      manager.play(video.id.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Image.network(
                            video.thumbnails.mediumResUrl,
                            width: 120,
                            height: 67.5,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizedLayout(double width, double height) {
    final manager = Provider.of<VideoPlayerManager>(context, listen: false);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Chewie(controller: _chewieController!),
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: manager.close,
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: manager.maximize,
              child: const Icon(Icons.open_in_full, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
