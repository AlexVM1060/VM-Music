import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _ytExplode = YoutubeExplode();
  List<Video> _searchResults = [];

  void _search() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final searchResults = await _ytExplode.search.search(query);
      setState(() {
        _searchResults = searchResults.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search on YouTube',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final video = _searchResults[index];
                return ListTile(
                  leading: Image.network(video.thumbnails.mediumResUrl),
                  title: Text(video.title),
                  subtitle: Text(video.author),
                  onTap: () {
                    final mediaItem = MediaItem(
                      id: video.id.value,
                      title: video.title,
                      artist: video.author,
                      artUri: Uri.parse(video.thumbnails.highResUrl),
                    );
                    audioHandler.addQueueItem(mediaItem);
                    audioHandler.play();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
