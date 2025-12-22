import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/models/video.dart';
import 'package:hive/hive.dart';

class DownloadService with ChangeNotifier {
  final yt.YoutubeExplode _youtubeExplode = yt.YoutubeExplode();
  final Box<DownloadedVideo> _downloadedVideoBox = Hive.box<DownloadedVideo>('downloaded_videos');
  final Box _settingsBox = Hive.box('settings');

  DownloadService() {
    _initialize();
  }

  void _initialize() {
    _downloadedVideoBox.watch().listen((event) {
      notifyListeners();
    });
    _settingsBox.watch().listen((event) {
      notifyListeners();
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> downloadVideo(Video video) async {
    await _requestPermissions();

    if (_downloadedVideoBox.containsKey(video.videoId)) {
      return;
    }

    try {
      final streamManifest = await _youtubeExplode.videos.streamsClient.getManifest(video.videoId);
      final streamInfo = streamManifest.muxed.last;

      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = path.join(documentsDir.path, '${video.videoId}.mp4');
      final file = File(filePath);

      final stream = _youtubeExplode.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();

      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      // Descargar miniatura
      final thumbnailPath = path.join(documentsDir.path, '${video.videoId}.jpg');
      final thumbnailResponse = await http.get(Uri.parse(video.thumbnailUrl));
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailResponse.bodyBytes);

      final downloadedVideo = DownloadedVideo(
        videoId: video.videoId,
        title: video.title,
        thumbnailUrl: video.thumbnailUrl,
        channelTitle: video.channelTitle,
        filePath: filePath,
        localThumbnailPath: thumbnailPath,
      );

      await _downloadedVideoBox.put(video.videoId, downloadedVideo);
      notifyListeners();
    } catch (e) {
      // Manejar el error
    }
  }

  Future<void> downloadPlaylistVideos(List<Video> videos) async {
    for (final video in videos) {
      await downloadVideo(video);
    }
  }

  Future<List<DownloadedVideo>> getDownloadedVideos() async {
    return _downloadedVideoBox.values.toList();
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      final video = _downloadedVideoBox.get(videoId);
      if (video != null) {
        final videoFile = File(video.filePath);
        if (await videoFile.exists()) {
          await videoFile.delete();
        }

        final thumbnailFile = File(video.localThumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }

        await _downloadedVideoBox.delete(videoId);
        notifyListeners();
      }
    } catch (e) {
      // Manejar el error
    }
  }

  bool isPlaylistAutoDownload(String playlistName) {
    return _settingsBox.get('auto_download_$playlistName', defaultValue: false);
  }

  void setPlaylistAutoDownload(String playlistName, bool value) {
    _settingsBox.put('auto_download_$playlistName', value);
  }

  void addDownloadedVideoForTest(DownloadedVideo video) {
    _downloadedVideoBox.put(video.videoId, video);
    notifyListeners();
  }

  bool isVideoDownloaded(String videoId) {
    return _downloadedVideoBox.containsKey(videoId);
  }

  DownloadedVideo? getDownloadedVideo(String videoId) {
    return _downloadedVideoBox.get(videoId);
  }
}
