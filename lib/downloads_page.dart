import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<FileSystemEntity> _songs = [];
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() => _currentlyPlayingPath = null);
        }
      }
    });
  }

  Future<void> _loadSongs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final directory = Directory(dir.path);
      if (!await directory.exists()) {
        if (mounted) setState(() => _songs = []);
        return;
      }
      final allFiles = directory.listSync();
      if (mounted) {
        setState(() {
          _songs = allFiles.where((file) => file.path.endsWith('.m4a')).toList();
        });
      }
    } catch (e, s) {
      developer.log('Error al cargar las canciones', error: e, stackTrace: s);
    }
  }

  Future<void> _playSong(String path) async {
    try {
      if (_currentlyPlayingPath == path) {
        _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
      } else {
        await _audioPlayer.setAudioSource(AudioSource.file(path));
        setState(() => _currentlyPlayingPath = path);
        _audioPlayer.play();
      }
    } catch (e, s) {
      developer.log('Error al reproducir la canción', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reproducir la canción.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSongs,
        child: Column(
          children: [
            if (_songs.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Aún no has descargado ninguna canción.',
                      style: TextStyle(fontSize: 16)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final file = _songs[index];
                    final isPlaying = _currentlyPlayingPath == file.path;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isPlaying
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(
                          p.basenameWithoutExtension(file.path),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: StreamBuilder<PlayerState>(
                          stream: _audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState = playerState?.processingState;
                            final playing = playerState?.playing ?? false;

                            if (isPlaying && (processingState == ProcessingState.loading ||
                                    processingState == ProcessingState.buffering)) {
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              );
                            }
                            return IconButton(
                              icon: Icon(isPlaying && playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              iconSize: 32,
                              onPressed: () => _playSong(file.path),
                            );
                          },
                        ),
                        onTap: () => _playSong(file.path),
                      ),
                    );
                  },
                ),
              ),
            if (_currentlyPlayingPath != null) _buildPlaybackProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackProgressIndicator() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioPlayer.duration ?? Duration.zero;
        final progress = (duration.inMilliseconds > 0)
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
      },
    );
  }
}
