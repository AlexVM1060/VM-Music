
import 'package:hive/hive.dart';
import 'package:myapp/models/playlist.dart';
import 'package:myapp/models/video_history.dart';

class PlaylistService {
  static const String _boxName = 'playlists';

  Future<Box<Playlist>> get _box async => await Hive.openBox<Playlist>(_boxName);

  Future<void> createPlaylist(String name) async {
    final box = await _box;
    if (box.values.any((p) => p.name == name)) {
      throw Exception('Playlist with this name already exists');
    }
    await box.add(Playlist(name: name));
  }

  Future<void> addVideoToPlaylist(String playlistName, VideoHistory video) async {
    final box = await _box;
    final playlist = box.values.firstWhere((p) => p.name == playlistName);
    if (playlist.videos.any((v) => v.videoId == video.videoId)) {
      return; // Video already in the playlist
    }
    playlist.videos.add(video);
    await playlist.save();
  }

  Future<void> removeVideoFromPlaylist(
      String playlistName, String videoId) async {
    final box = await _box;
    final playlist = box.values.firstWhere((p) => p.name == playlistName);
    playlist.videos.removeWhere((v) => v.videoId == videoId);
    await playlist.save();
  }

  Future<List<Playlist>> getPlaylists() async {
    final box = await _box;
    final playlists = box.values.toList();
    // Ensure 'Favorites' playlist exists
    if (!playlists.any((p) => p.name == 'Videos favoritos')) {
      await createPlaylist('Videos favoritos');
      return await getPlaylists(); // Re-fetch the list
    }
    return playlists;
  }
}
