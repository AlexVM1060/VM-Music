import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:rxdart/rxdart.dart';

Stream<PositionData> get positionDataStream =>
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioHandler.playbackState.map((state) => state.position).distinct(),
        audioHandler.playbackState
            .map((state) => state.bufferedPosition)
            .distinct(),
        audioHandler.mediaItem.map((item) => item?.duration).distinct(),
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero));

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Color _backgroundColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem?.artUri != null) {
        _updateBackgroundColor(mediaItem!.artUri!);
      }
    });
  }

  void _updateBackgroundColor(Uri artUri) async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(artUri.toString()),
    );
    setState(() {
      _backgroundColor = paletteGenerator.dominantColor?.color ?? Colors.black;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _backgroundColor,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.queue_music),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => const QueueScreen(),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<MediaItem?>(
                stream: audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  if (mediaItem == null) {
                    return const Center(
                      child: Text('No song is playing'),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (mediaItem.artUri != null)
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1 - (_animationController.value * 0.1),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  mediaItem.artUri.toString(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          mediaItem.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mediaItem.artist ?? '',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<PositionData>(
                          stream: positionDataStream,
                          builder: (context, snapshot) {
                            final positionData = snapshot.data;
                            return SeekBar(
                              duration: positionData?.duration ?? Duration.zero,
                              position: positionData?.position ?? Duration.zero,
                              bufferedPosition:
                                  positionData?.bufferedPosition ?? Duration.zero,
                              onChangeEnd: audioHandler.seek,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              iconSize: 40,
                              color: Colors.white,
                              onPressed: audioHandler.skipToPrevious,
                            ),
                            StreamBuilder<PlaybackState>(
                              stream: audioHandler.playbackState,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                if (playing) {
                                  _animationController.forward();
                                } else {
                                  _animationController.reverse();
                                }
                                return IconButton(
                                  icon: Icon(
                                    playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  ),
                                  iconSize: 60,
                                  color: Colors.white,
                                  onPressed: () {
                                    if (playing) {
                                      audioHandler.pause();
                                    } else {
                                      audioHandler.play();
                                    }
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              iconSize: 40,
                              color: Colors.white,
                              onPressed: audioHandler.skipToNext,
                            ),
                          ],
                        ),
                      ],
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
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        return ListView.builder(
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final mediaItem = queue[index];
            return ListTile(
              leading: Image.network(mediaItem.artUri.toString()),
              title: Text(mediaItem.title),
              subtitle: Text(mediaItem.artist ?? ''),
              onTap: () {
                audioHandler.skipToQueueItem(index);
              },
            );
          },
        );
      },
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SliderTheme(
          data: _sliderThemeData.copyWith(
            thumbShape: HiddenThumbComponentShape(),
            activeTrackColor: Colors.blue.shade100,
            inactiveTrackColor: Colors.grey.shade300,
          ),
          child: ExcludeSemantics(
            child: Slider(
              min: 0.0,
              max: widget.duration.inMilliseconds.toDouble(),
              value: widget.bufferedPosition.inMilliseconds.toDouble(),
              onChanged: (value) {},
            ),
          ),
        ),
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: (_dragValue ?? widget.position.inMilliseconds.toDouble())
              .clamp(0.0, widget.duration.inMilliseconds.toDouble()),
          onChanged: (value) {
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged!(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(Duration(milliseconds: value.round()));
            }
            _dragValue = null;
          },
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                  .firstMatch("$_remaining")
                  ?.group(1) ??
                  '$_remaining'),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}