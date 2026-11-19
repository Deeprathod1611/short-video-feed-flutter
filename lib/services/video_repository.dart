import 'dart:math';
import '../models/video_item.dart';

class VideoRepository {
  final Random _random = Random();

  static const List<String> _sampleVideos = [
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ];

  Future<List<VideoItem>> getVideos({
    required int page,
    required int limit,
  }) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));

    if (page > 0 && _random.nextInt(100) < 12) {
      throw Exception('Failed to load more videos. Please retry.');
    }

    const int totalAvailable = 20;
    final int start = page * limit;
    if (start >= totalAvailable) {
      return [];
    }

    final int count = min(limit, totalAvailable - start);
    return List.generate(count, (i) {
      final int index = start + i;
      return VideoItem(
        id: 'video_$index',
        url: _sampleVideos[index % _sampleVideos.length],
        username: '@user_${index + 1}',
        caption: 'Short video #${index + 1} - smooth playback and clean scroll.',
        likes: 150 + (index * 25),
        commentsCount: 2 + index,
        shares: 5 + index,
        comments: [
          'Nice video!',
          'Smooth playback on scroll.',
        ],
      );
    });
  }
}