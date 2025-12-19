
import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final List<String> videoIds;
  final int initialIndex;

  const VideoPlayerPage({
    super.key,
    required this.videoId,
    required this.videoIds,
    required this.initialIndex,
  });

  @override
  VideoPlayerPageState createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  late int _currentIndex;
  double _volume = 100;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true, // We use our custom controls
      ),
    )..addListener(_playerListener);
    _startHideControlsTimer();
  }

  void _playerListener() {
    if (mounted && _controller.value.isReady) {
      setState(() {
        _position = _controller.value.position;
        _duration = _controller.metadata.duration;
      });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _startHideControlsTimer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_playerListener);
    _controller.dispose();
    super.dispose();
  }

  void _playNext() {
    if (_currentIndex < widget.videoIds.length - 1) {
      _currentIndex++;
      _controller.load(widget.videoIds[_currentIndex]);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _controller.load(widget.videoIds[_currentIndex]);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  Widget _buildCustomControls() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: CupertinoColors.black.withAlpha(80),
              child: Column(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                        onPressed: _playPrevious,
                        child: const Icon(CupertinoIcons.backward_end_fill, color: Colors.white, size: 35),
                      ),
                      CupertinoButton(
                        onPressed: () {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          setState(() {});
                          _startHideControlsTimer();
                        },
                        child: Icon(
                          _controller.value.isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _playNext,
                        child: const Icon(CupertinoIcons.forward_end_fill, color: Colors.white, size: 35),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        // Video Progress Slider
                        if (_duration.inSeconds > 0)
                          Row(
                            children: [
                              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
                              Expanded(
                                child: CupertinoSlider(
                                  value: _position.inSeconds.toDouble(),
                                  min: 0,
                                  max: _duration.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    _controller.seekTo(Duration(seconds: value.toInt()));
                                    _startHideControlsTimer();
                                  },
                                  activeColor: Colors.red,
                                  thumbColor: Colors.red,
                                ),
                              ),
                              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
                            ],
                          ),
                        const SizedBox(height: 8),
                        // Volume Slider
                        Row(
                          children: [
                            const Icon(CupertinoIcons.volume_down, color: Colors.white70),
                            Expanded(
                              child: CupertinoSlider(
                                value: _volume,
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  setState(() {
                                    _volume = value;
                                    _controller.setVolume(value.toInt());
                                  });
                                  _startHideControlsTimer();
                                },
                                activeColor: Colors.white,
                                thumbColor: Colors.white,
                              ),
                            ),
                            const Icon(CupertinoIcons.volume_up, color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Reproductor'),
        backgroundColor: CupertinoColors.black.withAlpha(178),
        border: null,
      ),
      backgroundColor: Colors.black,
      child: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                  onReady: () {
                    if (mounted) {
                       setState(() {
                         _duration = _controller.metadata.duration;
                       });
                    }
                  },
                ),
              ),
              Positioned.fill(
                child: _buildCustomControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
