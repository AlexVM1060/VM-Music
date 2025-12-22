import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

class DownloadService with ChangeNotifier {
  static const String _boxName = 'downloads';
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  final Map<String, double> _downloadProgress = {};
  final Map<String, DownloadStatus> _downloadStatus = {};

  Future<Box<DownloadedVideo>> get _box async => await Hive.openBox<DownloadedVideo>(_boxName);

  Future<List<DownloadedVideo>> getDownloadedVideos() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> downloadVideo(String videoId, String title, String thumbnailUrl, String channelTitle) async {
    if (_downloadStatus[videoId] == DownloadStatus.downloading) return;

    _downloadStatus[videoId] = DownloadStatus.downloading;
    _downloadProgress[videoId] = 0.0;
    notifyListeners();

    try {
      final streamManifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = streamManifest.muxed.withHighestBitrate();
      final stream = _yt.videos.streamsClient.get(streamInfo);

      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$videoId.mp4';
      final file = File(filePath);

      await _dio.download(
        streamInfo.url.toString(),
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[videoId] = received / total;
            notifyListeners();
          }
        },
      );

      final downloadedVideo = DownloadedVideo(
        videoId: videoId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        channelTitle: channelTitle,
        filePath: filePath,
      );

      final box = await _box;
      await box.put(videoId, downloadedVideo);

      _downloadStatus[videoId] = DownloadStatus.downloaded;
      _downloadProgress.remove(videoId);
      notifyListeners();
    } catch (e) {
      _downloadStatus[videoId] = DownloadStatus.error;
      _downloadProgress.remove(videoId);
      notifyListeners();
    }
  }

  Future<void> deleteVideo(String videoId) async {
    final box = await _box;
    final video = await box.get(videoId);
    if (video != null) {
      final file = File(video.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await box.delete(videoId);
      _downloadStatus[videoId] = DownloadStatus.notDownloaded;
      notifyListeners();
    }
  }

  DownloadStatus getDownloadStatus(String videoId) {
    if (_downloadStatus.containsKey(videoId)) {
      return _downloadStatus[videoId]!;
    }
    return DownloadStatus.notDownloaded;
  }

  double getDownloadProgress(String videoId) {
    return _downloadProgress[videoId] ?? 0.0;
  }

   Future<void> loadDownloadedVideos() async {
    final box = await _box;
    final videos = box.values;
    for (var video in videos) {
      _downloadStatus[video.videoId] = DownloadStatus.downloaded;
    }
    notifyListeners();
  }

}
