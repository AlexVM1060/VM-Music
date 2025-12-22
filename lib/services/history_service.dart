
import 'package:hive/hive.dart';
import 'package:myapp/models/video_history.dart';

class HistoryService {
  static const String _boxName = 'history';

  Future<Box<VideoHistory>> get _box async =>
      await Hive.openBox<VideoHistory>(_boxName);

  Future<void> addVideoToHistory(VideoHistory video) async {
    final box = await _box;
    // Remove if already exists to avoid duplicates and update watchedAt
    final existing = box.values.firstWhere((v) => v.videoId == video.videoId, orElse: () => null as VideoHistory);
    if (existing != null) {
      await existing.delete();
    }
    await box.add(video);
  }

  Future<List<VideoHistory>> getHistory() async {
    final box = await _box;
    return box.values.toList().reversed.toList();
  }

  Future<void> clearHistory() async {
    final box = await _box;
    await box.clear();
  }
}
