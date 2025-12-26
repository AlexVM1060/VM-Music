import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/now_playing_screen.dart';
import 'package:myapp/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final _pages = [
    const MusicListPage(),
    const SearchPage(),
    const LibraryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              final mediaItem = snapshot.data;
              if (mediaItem == null) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const NowPlayingScreen()));
                },
                child: Container(
                  color: Colors.black12,
                  child: ListTile(
                    leading: Image.network(mediaItem.artUri.toString()),
                    title: Text(mediaItem.title),
                    subtitle: Text(mediaItem.artist ?? ''),
                    trailing: StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return IconButton(
                          icon: Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                          ),
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
                  ),
                ),
              );
            },
          ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MusicListPage extends StatelessWidget {
  const MusicListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
      ),
      body: ListView.builder(
        itemCount: _exampleSongs.length,
        itemBuilder: (context, index) {
          final song = _exampleSongs[index];
          return ListTile(
            leading: Image.network(song.artUri.toString()),
            title: Text(song.title),
            subtitle: Text(song.artist ?? ''),
            onTap: () async {
              await audioHandler.addQueueItem(song);
              audioHandler.play();
            },
          );
        },
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: const Center(
        child: Text('Your music library'),
      ),
    );
  }
}

final _exampleSongs = [
  MediaItem(
    id: 'https://www.youtube.com/watch?v=nrhbJ2b-93c',
    title: 'Agua',
    artist: 'Tainy, J. Balvin',
    artUri: Uri.parse('https://i.ytimg.com/vi/nrhbJ2b-93c/maxresdefault.jpg'),
  ),
  MediaItem(
    id: 'https://www.youtube.com/watch?v=k4yXQkG2s1E',
    title: 'Dakiti',
    artist: 'Bad Bunny, Jhay Cortez',
    artUri: Uri.parse('https://i.ytimg.com/vi/k4yXQkG2s1E/maxresdefault.jpg'),
  ),
  MediaItem(
    id: 'https://www.youtube.com/watch?v=7i5-sA8T6f8',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    artUri: Uri.parse('https://i.ytimg.com/vi/7i5-sA8T6f8/maxresdefault.jpg'),
  ),
];
