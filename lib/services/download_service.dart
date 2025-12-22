import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/downloaded_video.dart';
import 'package:myapp/models/video_history.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

class DownloadService with ChangeNotifier {
  static const String _downloadsBoxName = 'downloads';
  static const String _autoDownloadBoxName = 'auto_download_playlists';
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  final Map<String, double> _downloadProgress = {};
  final Map<String, DownloadStatus> _downloadStatus = {};
  Set<String> _autoDownloadPlaylists = {};

  Future<Box<DownloadedVideo>> get _downloadsBox async => await Hive.openBox<DownloadedVideo>(_downloadsBoxName);
  Future<Box<String>> get _autoDownloadBox async => await Hive.openBox<String>(_autoDownloadBoxName);

  DownloadService() {
    _loadAutoDownloadPlaylists();
    loadDownloadedVideos();
  }

  Future<void> _loadAutoDownloadPlaylists() async {
    final box = await _autoDownloadBox;
    _autoDownloadPlaylists = box.values.toSet();
    notifyListeners();
  }

  Future<void> setPlaylistAutoDownload(String playlistName, bool enabled) async {
    final box = await _autoDownloadBox;
    if (enabled) {
      await box.put(playlistName, playlistName);
      _autoDownloadPlaylists.add(playlistName);
    } else {
      await box.delete(playlistName);
      _autoDownloadPlaylists.remove(playlistName);
    }
    notifyListeners();
  }

  bool isPlaylistAutoDownload(String playlistName) {
    return _autoDownloadPlaylists.contains(playlistName);
  }

  Future<void> downloadPlaylistVideos(List<VideoHistory> videos) async {
    for (final video in videos) {
      final isDownloaded = (await _downloadsBox).containsKey(video.videoId);
      if (!isDownloaded) {
        downloadVideo(video.videoId, video.title, video.thumbnailUrl, video.channelTitle);
      }
    }
  }

  Future<List<DownloadedVideo>> getDownloadedVideos() async {
    final box = await _downloadsBox;
    return box.values.toList();
  }

  Future<void> downloadVideo(String videoId, String title, String thumbnailUrl, String channelTitle) async {
    final isAlreadyDownloaded = (await _downloadsBox).containsKey(videoId);
    if (_downloadStatus[videoId] == DownloadStatus.downloading || isAlreadyDownloaded) return;

    _downloadStatus[videoId] = DownloadStatus.downloading;
    _downloadProgress[videoId] = 0.0;
    notifyListeners();

    try {
      final streamManifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = streamManifest.muxed.withHighestBitrate();
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$videoId.mp4';

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

      final box = await _downloadsBox;
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
    final box = await _downloadsBox;
    final video = box.get(videoId);
    if (video != null) {
      final file = File(video.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await box.delete(videoId);
      _downloadStatus.remove(videoId);
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
    final box = await _downloadsBox;
    final videos = box.values;
    for (var video in videos) {
      _downloadStatus[video.videoId] = DownloadStatus.downloaded;
    }
    notifyListeners();
  }
}
