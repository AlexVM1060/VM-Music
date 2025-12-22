import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class OfflineVideoPlayerPage extends StatefulWidget {
  final DownloadedVideo video;

  const OfflineVideoPlayerPage({super.key, required this.video});

  @override
  State<OfflineVideoPlayerPage> createState() => _OfflineVideoPlayerPageState();
}

class _OfflineVideoPlayerPageState extends State<OfflineVideoPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  Offset _dragOffset = const Offset(200, 400);

  late final VideoPlayerManager _manager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _manager = Provider.of<VideoPlayerManager>(context, listen: false);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Simplificado: El manager se encarga de la lógica.
      _manager.switchToBackgroundAudio();
    } else if (state == AppLifecycleState.resumed) {
      // Simplificado: El manager se encarga de la lógica.
      _manager.switchToForegroundVideo();
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(widget.video.filePath);
      if (!await file.exists()) {
        throw Exception('El archivo de video no existe');
      }

      _disposeControllers();

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();

      if (mounted) {
        _manager.play(widget.video.videoId, isLocalVideo: true);
        _manager.setPlayerData(
          controller: _videoPlayerController!,
          streamUrl: widget.video.filePath, 
          title: widget.video.title,
          thumbnailUrl: widget.video.thumbnailUrl,
          channelTitle: widget.video.channelTitle,
          isLocal: true,
        );

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error initializing offline player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir el video: $e')),
        );
        _manager.close();
      }
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  void didUpdateWidget(covariant OfflineVideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.videoId != widget.video.videoId) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMinimized = _manager.isMinimized;

    const double minimizedWidth = 250.0;
    const double minimizedHeight = 140.6;

    if (_isLoading && !isMinimized) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_chewieController == null || _chewieController!.videoPlayerController.value.isInitialized == false) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    final playerWidget = Chewie(controller: _chewieController!);

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
          child: _buildMinimizedLayout(minimizedWidth, minimizedHeight, playerWidget),
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
        child: _buildPlayerContent(isMinimized, minimizedWidth, minimizedHeight, playerWidget),
      ),
    );
  }

  Widget _buildPlayerContent(bool isMinimized, double minWidth, double minHeight, Widget player) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: isMinimized ? _manager.maximize : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isMinimized ? minWidth : screenSize.width,
        height: isMinimized ? minHeight : screenSize.height,
        child: Material(
          elevation: 4.0,
          child: isMinimized
              ? _buildMinimizedLayout(minWidth, minHeight, player)
              : _buildMaximizedLayout(player),
        ),
      ),
    );
  }

  Widget _buildMaximizedLayout(Widget player) {
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : player,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _manager.minimize,
                    child: const Icon(CupertinoIcons.chevron_down, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.video.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                   
                  
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizedLayout(double width, double height, Widget player) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          player,
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: _manager.close,
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
            ),
          ),
            Positioned(
            top: 0,
            left: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: _manager.maximize,
              child: const Icon(Icons.open_in_full, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
