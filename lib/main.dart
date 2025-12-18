import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'YouTube Player',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemRed),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final YoutubePlayerController _controller;
  final TextEditingController _textController = TextEditingController();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'iL18_4G62SM', // Default video
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  Future<void> _searchVideos() async {
    if (_textController.text.isEmpty) return;
    // Hide keyboard
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
      // Handle search errors if necessary
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playVideo(String videoId) {
    _controller.load(videoId);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('YouTube Player'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Player needs a Material ancestor for some UI elements
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
                      placeholder: 'Buscar videos en YouTube',
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
                          return GestureDetector(
                            onTap: () => _playVideo(video.id.value),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Image.network(
                                      video.thumbnails.mediumResUrl,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            video.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            video.author,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
    _controller.dispose();
    _textController.dispose();
    _youtubeExplode.close();
    super.dispose();
  }
}
