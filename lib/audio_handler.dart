import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:video_player/video_player.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  VideoPlayerController? _controller;
  VideoPlayerController? get videoPlayerController => _controller;

  @override
  Future<void> play() async {
    if (_controller != null) {
      await _controller!.play();
      playbackState.add(playbackState.value.copyWith(playing: true));
    }
  }

  @override
  Future<void> pause() async {
    if (_controller != null) {
      await _controller!.pause();
      playbackState.add(playbackState.value.copyWith(playing: false));
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_controller != null) {
      await _controller!.seekTo(position);
    }
  }

  @override
  Future<void> stop() async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero);
      playbackState.add(playbackState.value.copyWith(playing: false));
    }
  }

  Future<void> setVideo(String url, {bool isLocal = false}) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    if (isLocal) {
      _controller = VideoPlayerController.file(File(url));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }
    await _controller!.initialize();
    mediaItem.add(
      MediaItem(
        id: url,
        title: 'Video',
        duration: _controller!.value.duration,
      ),
    );
    _controller!.addListener(() {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: _controller!.value.position,
          bufferedPosition: _controller!.value.buffered.isNotEmpty 
              ? _controller!.value.buffered.last.end 
              : Duration.zero,
          playing: _controller!.value.isPlaying,
        ),
      );
    });
  }
}
