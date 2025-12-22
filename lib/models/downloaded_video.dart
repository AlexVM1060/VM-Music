import 'package:hive/hive.dart';

part 'downloaded_video.g.dart';

@HiveType(typeId: 3)
class DownloadedVideo extends HiveObject {
  @HiveField(0)
  final String videoId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String thumbnailUrl; // URL remota

  @HiveField(3)
  final String channelTitle;

  @HiveField(4)
  final String filePath; // Path al archivo de vídeo descargado

  @HiveField(5)
  final String localThumbnailPath; // Path a la miniatura descargada

  DownloadedVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.filePath,
    required this.localThumbnailPath,
  });
}
