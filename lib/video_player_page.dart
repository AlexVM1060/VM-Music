import 'dart:async';
import 'dart:developer';

import 'package:better_player/better_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final _ytExplode = YoutubeExplode();
  List<Video> _relatedVideos = [];
  String _videoTitle = '';
  Offset _dragOffset = const Offset(200, 400);
  bool _isLoading = true;
  String? _videoUrl;
  Video? _currentVideo;

  late final VideoPlayerManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = Provider.of<VideoPlayerManager>(context, listen: false);
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
      final videoUrl = streamInfo.url;

      if (videoUrl.toString().isEmpty) {
        throw Exception('No valid stream URL found');
      }

      final video = await _ytExplode.videos.get(VideoId(widget.videoId));

      if (mounted) {
        setState(() {
          _videoUrl = videoUrl.toString();
          _videoTitle = video.title;
          _currentVideo = video; // Guardamos el objeto de vídeo actual
          _isLoading = false;
        });
        _fetchRelatedVideos();
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
        _manager.close();
      }
    }
  }

  Future<void> _fetchRelatedVideos() async {
    if (_currentVideo == null) return;
    try {
      final relatedVideos = await _ytExplode.videos.getRelatedVideos(_currentVideo!);
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
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _ytExplode.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMinimized = context.select((VideoPlayerManager m) => m.isMinimized);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_videoUrl == null) {
      return const SizedBox.shrink();
    }

    final playerWidget = BetterPlayer.network(
      _videoUrl!,
      betterPlayerConfiguration: BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(),
      ),
    );

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
          child: _buildMinimizedLayout(250.0, 140.6, playerWidget),
        ),
        maxSimultaneousDrags: isMinimized ? 1 : 0,
        onDragEnd: (details) {
          final size = MediaQuery.of(context).size;
          double dx = details.offset.dx;
          double dy = details.offset.dy;

          if (dx < 0) dx = 0;
          if (dx > size.width - 250.0) dx = size.width - 250.0;
          if (dy < 0) dy = 0;
          if (dy > size.height - 140.6) dy = size.height - 140.6;

          setState(() {
            _dragOffset = Offset(dx, dy);
          });
        },
        child: _buildPlayerContent(isMinimized, 250.0, 140.6, playerWidget),
      ),
    );
  }

  Widget _buildPlayerContent(
      bool isMinimized, double minWidth, double minHeight, Widget player) {
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: player,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _manager.minimize,
                    child: const Icon(CupertinoIcons.chevron_down,
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
                      _manager.play(video.id.value);
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
