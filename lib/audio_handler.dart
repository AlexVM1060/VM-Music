import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<MyAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Music Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = <AudioSource>[];

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _loadEmptyPlaylist();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(ConcatenatingAudioSource(children: _playlist));
    } catch (e) {
      // Manejar el error
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final yt = YoutubeExplode();
    for (var item in mediaItems) {
      final streamInfo = await yt.videos.streamsClient.getManifest(item.id);
      final audioStream = streamInfo.audioOnly.withHighestBitrate();
      final audioSource = AudioSource.uri(audioStream.url);
      _playlist.add(audioSource);
    }
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
    await _player.setAudioSource(ConcatenatingAudioSource(children: _playlist));
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final yt = YoutubeExplode();
    final streamInfo = await yt.videos.streamsClient.getManifest(mediaItem.id);
    final audioStream = streamInfo.audioOnly.withHighestBitrate();
    final audioSource = AudioSource.uri(audioStream.url, tag: mediaItem);
    _playlist.add(audioSource);
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
    await _player.setAudioSource(ConcatenatingAudioSource(children: _playlist));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
