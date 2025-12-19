import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  Offset _dragOffset = const Offset(200, 400);

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    )..addListener(_onPlayerChange);
  }

  void _onPlayerChange() {
    final manager = Provider.of<VideoPlayerManager>(context, listen: false);
    if (manager.isFullScreen != _controller.value.isFullScreen) {
      manager.setFullScreen(_controller.value.isFullScreen);
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.load(widget.videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<VideoPlayerManager>(context);
    final isMinimized = manager.isMinimized;

    const double minimizedWidth = 200.0;
    const double minimizedHeight = 112.5;

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
        // SOLUCIÓN: Permite arrastrar solo si está minimizado.
        maxSimultaneousDrags: isMinimized ? 1 : 0,
        onDragEnd: (details) {
          final size = MediaQuery.of(context).size;
          double dx = details.offset.dx;
          double dy = details.offset.dy;

          // MEJORA: Evita que el reproductor se arrastre fuera de la pantalla.
          if (dx < 0) dx = 0;
          if (dx > size.width - minimizedWidth) dx = size.width - minimizedWidth;
          if (dy < 0) dy = 0;
          if (dy > size.height - minimizedHeight) {
            dy = size.height - minimizedHeight;
          }

          setState(() {
            _dragOffset = Offset(dx, dy);
          });
        },
        // SOLUCIÓN: El argumento 'child' ahora está al final.
        child: _buildPlayerContent(isMinimized, minimizedWidth, minimizedHeight),
      ),
    );
  }

  Widget _buildPlayerContent(
      bool isMinimized, double minWidth, double minHeight) {
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
          child: isMinimized
              ? _buildMinimizedLayout(minWidth, minHeight)
              : _buildMaximizedLayout(),
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
                YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  onReady: () => _controller.play(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: manager.minimize,
                    child: const Icon(CupertinoIcons.chevron_down,
                        color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _controller.metadata.title,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 18),
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
          YoutubePlayer(controller: _controller, showVideoProgressIndicator: false),
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: manager.close,
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerChange);
    _controller.dispose();
    super.dispose();
  }
}
