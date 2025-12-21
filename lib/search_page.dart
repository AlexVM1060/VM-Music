import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum SearchState { initial, loading, success, error, noResults }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  List<Video> _videos = [];
  SearchState _searchState = SearchState.initial;
  final Map<String, bool> _isDownloading = {};

  Future<void> _searchVideos() async {
    if (_textController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searchState = SearchState.loading;
      _videos = [];
    });

    try {
      final query = _textController.text;
      final searchResult = await _youtubeExplode.search.search(query);
      if (!mounted) return;

      if (searchResult.isEmpty) {
        setState(() => _searchState = SearchState.noResults);
      } else {
        setState(() {
          _videos = searchResult.toList();
          _searchState = SearchState.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchState = SearchState.error);
      }
    }
  }

  void _openVideoPlayer(String videoId) {
    Provider.of<VideoPlayerManager>(context, listen: false).play(videoId);
  }

  Future<void> _downloadAudio(Video video) async {
    final videoId = video.id.value;
    if (!mounted) return;
    setState(() => _isDownloading[videoId] = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descarga de audio completa!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      developer.log('Error al descargar', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al descargar el audio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading[videoId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _textController,
      onSubmitted: (_) => _searchVideos(),
      decoration: InputDecoration(
        hintText: 'Buscar en YouTube...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildBody() {
    switch (_searchState) {
      case SearchState.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchState.error:
        return const Center(child: Text('Error al buscar. Inténtalo de nuevo.'));
      case SearchState.noResults:
        return const Center(child: Text('No se encontraron videos.'));
      case SearchState.initial:
        return Center(
          child: Text(
            'Busca algo para empezar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      case SearchState.success:
        return ListView.builder(
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            final video = _videos[index];
            final isDownloading = _isDownloading[video.id.value] ?? false;
            return VideoCard(
              video: video,
              isDownloading: isDownloading,
              onPlay: () => _openVideoPlayer(video.id.value),
              onDownload: () => _downloadAudio(video),
            );
          },
        );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _youtubeExplode.close();
    super.dispose();
  }
}

class VideoCard extends StatelessWidget {
  final Video video;
  final bool isDownloading;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const VideoCard({
    super.key,
    required this.video,
    required this.isDownloading,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  video.thumbnails.mediumResUrl,
                  width: 120,
                  height: 67.5,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.videocam_off_outlined, size: 67.5, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.author,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: isDownloading
                    ? const SizedBox(
                        width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0))
                    : const Icon(Icons.download_for_offline_outlined),
                onPressed: isDownloading ? null : onDownload,
                tooltip: 'Descargar audio',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
