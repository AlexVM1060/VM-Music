import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final YoutubePlayerController _controller;
  final TextEditingController _textController = TextEditingController();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = false;
  final Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'iL18_4G62SM', // Default video
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
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
      // Handle search errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playVideo(String videoId) {
    _controller.load(videoId);
  }

  Future<void> _downloadAudio(Video video) async {
    final videoId = video.id.value;
    setState(() {
      _isDownloading[videoId] = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        // Handle permission denial
        return;
      }

      // Get the audio stream
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final stream = _youtubeExplode.videos.streamsClient.get(streamInfo);

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/${video.title.replaceAll(r'[/\\:*?"<>|]', '_')}.m4a';
      final file = File(filePath);

      // Download the stream
      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();
    } catch (e) {
      // Handle download error
    } finally {
      setState(() {
        _isDownloading[videoId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Buscar en YouTube'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Material(
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: CupertinoColors.systemRed,
                  progressColors: const ProgressBarColors(
                    playedColor: CupertinoColors.systemRed,
                    handleColor: CupertinoColors.systemRed,
                  ),
                ),
              ),
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

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: CupertinoColors.secondarySystemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _playVideo(videoId),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      video.thumbnails.mediumResUrl,
                                      width: 120,
                                      height: 67.5,
                                      fit: BoxFit.cover,
                                    ),
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
    _controller.dispose();
    _textController.dispose();
    _youtubeExplode.close();
    super.dispose();
  }
}
