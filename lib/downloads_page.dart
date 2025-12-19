import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  String? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final directory = Directory(dir.path);
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
      if (_audioPlayer.playing && _audioPlayer.audioSource?.toString().contains(path) == true) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setAudioSource(AudioSource.file(path));
        _audioPlayer.play();
        if (mounted) {
          setState(() {
            _currentlyPlaying = p.basenameWithoutExtension(path);
          });
        }
      }
    } catch (e, s) {
      developer.log('Error al reproducir la canción', error: e, stackTrace: s);
      if (mounted) {
        _showErrorDialog(
            'No se pudo reproducir la canción. El archivo podría estar dañado.');
      }
    }
  }

  void _showErrorDialog(String message, {String title = 'Error'}) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mis Descargas'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loadSongs,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _songs.isEmpty
                  ? const Center(
                      child: Text('Aún no has descargado ninguna canción.'),
                    )
                  : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final file = _songs[index];
                        final fileName = p.basenameWithoutExtension(file.path);

                        return CupertinoListTile(
                          title: Text(fileName),
                          leading: const Icon(CupertinoIcons.music_note),
                          onTap: () => _playSong(file.path),
                        );
                      },
                    ),
            ),
            if (_currentlyPlaying != null) _buildPlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentlyPlaying ?? 'Ninguna canción seleccionada',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer.duration ?? Duration.zero;
              return CupertinoSlider(
                value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                min: 0.0,
                max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              );
            },
          ),
          StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                return const CupertinoActivityIndicator();
              } else if (playing != true) {
                return CupertinoButton(
                  onPressed: () => _playSong(_audioPlayer.audioSource?.toString() ?? ''),
                  child: const Icon(CupertinoIcons.play_arrow_solid, size: 40),
                );
              } else if (processingState != ProcessingState.completed) {
                return CupertinoButton(
                  onPressed: _audioPlayer.pause,
                  child: const Icon(CupertinoIcons.pause_solid, size: 40),
                );
              } else {
                return CupertinoButton(
                    onPressed: () => _audioPlayer.seek(Duration.zero),
                    child: const Icon(CupertinoIcons.refresh, size: 40));
              }
            },
          ),
        ],
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final VoidCallback? onTap;

  const CupertinoListTile({
    super.key,
    required this.title,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(child: title),
          ],
        ),
      ),
    );
  }
}
