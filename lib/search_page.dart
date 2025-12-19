import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = false;
  final Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchVideos() async {
    if (_textController.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _videos = [];
    });

    try {
      final query = _textController.text;
      final searchResult = await _youtubeExplode.search.search(query);
      setState(() {
        _videos = searchResult.toList();
      });
    } catch (e) {
      _showErrorDialog('No se pudieron obtener los videos. Inténtalo de nuevo.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // AHORA: Llama al VideoPlayerManager para que gestione la reproducción
  void _openVideoPlayer(int index) {
    final videoId = _videos[index].id.value;
    Provider.of<VideoPlayerManager>(context, listen: false).play(videoId);
  }

  Future<void> _downloadAudio(Video video) async {
    final videoId = video.id.value;
    setState(() {
      _isDownloading[videoId] = true;
    });

    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(video.id);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final stream = _youtubeExplode.videos.streamsClient.get(streamInfo);

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${video.title.replaceAll(r'[/\\:*?"<>|]', '_')}.m4a';
      final file = File(filePath);

      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      if (mounted) {
        _showErrorDialog('¡Descarga completa!', title: 'Éxito');
      }
    } catch (e, s) {
      developer.log('Error al descargar', error: e, stackTrace: s);
      if (mounted) {
        _showErrorDialog(
            'Ocurrió un error al descargar el audio. Por favor, inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading[videoId] = false;
        });
      }
    }
  }

  void _showErrorDialog(String message, {String title = 'Error'}) {
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
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('VM Player')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _textController,
                      placeholder: 'Escribe tu búsqueda...',
                      onSubmitted: (_) => _searchVideos(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton(
                    onPressed: _searchVideos,
                    child: const Icon(CupertinoIcons.search),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          final videoId = video.id.value;
                          final isCurrentlyDownloading =
                              _isDownloading[videoId] ?? false;

                          return GestureDetector(
                            onTap: () => _openVideoPlayer(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.secondarySystemBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      video.thumbnails.mediumResUrl,
                                      width: 120,
                                      height: 67.5,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          style: CupertinoTheme.of(context)
                                              .textTheme
                                              .textStyle
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          video.author,
                                          style: CupertinoTheme.of(
                                            context,
                                          ).textTheme.tabLabelTextStyle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoButton(
                                    onPressed: isCurrentlyDownloading
                                        ? null
                                        : () => _downloadAudio(video),
                                    child: isCurrentlyDownloading
                                        ? const CupertinoActivityIndicator()
                                        : const Icon(CupertinoIcons.down_arrow),
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
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _youtubeExplode.close();
    super.dispose();
  }
}
