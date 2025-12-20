import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  Offset _dragOffset = const Offset(200, 400);
  final _ytExplode = YoutubeExplode();
  List<Video> _relatedVideos = [];
  String _videoTitle = '';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        playsInline: false, // Needed for iOS PiP
      ),
    );

    _controller.loadVideoById(videoId: widget.videoId);
    _controller.playVideo(); // Autoplay

    _controller.setFullScreenListener(_onFullScreenChange);

    _fetchRelatedVideos();
    _fetchVideoTitle();
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

  void _onFullScreenChange(bool isFullScreen) {
    final manager = Provider.of<VideoPlayerManager>(context, listen: false);
    if (mounted && manager.isFullScreen != isFullScreen) {
      manager.setFullScreen(isFullScreen);
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.loadVideoById(videoId: widget.videoId);
      _fetchRelatedVideos();
      _fetchVideoTitle();
    }
  }

  Future<void> enterPictureInPictureMode() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await SystemChannels.platform.invokeMethod('SystemChrome.enterPictureInPictureMode');
      } on PlatformException catch (e) {
        log("Error entering PiP mode: ${e.message}");
      }
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
        maxSimultaneousDrags: isMinimized ? 1 : 0,
        onDragEnd: (details) {
          final size = MediaQuery.of(context).size;
          double dx = details.offset.dx;
          double dy = details.offset.dy;

          if (dx < 0) dx = 0;
          if (dx > size.width - minimizedWidth) {
            dx = size.width - minimizedWidth;
          }
          if (dy < 0) dy = 0;
          if (dy > size.height - minimizedHeight) {
            dy = size.height - minimizedHeight;
          }

          setState(() {
            _dragOffset = Offset(dx, dy);
          });
        },
        child:
            _buildPlayerContent(isMinimized, minimizedWidth, minimizedHeight),
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
                  aspectRatio: 16 / 9,
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
                // Show PiP button only on Android
                if (defaultTargetPlatform == TargetPlatform.android)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: enterPictureInPictureMode,
                      child: const Icon(Icons.picture_in_picture_alt,
                          color: Colors.white, size: 30),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _videoTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                      final manager =
                          Provider.of<VideoPlayerManager>(context, listen: false);
                      manager.play(video.id.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
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
          YoutubePlayer(controller: _controller),
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: manager.close,
              child: const Icon(CupertinoIcons.xmark,
                  color: Colors.white, size: 20),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: manager.maximize,
              child:
                  const Icon(Icons.open_in_full, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    _ytExplode.close();
    super.dispose();
  }
}
