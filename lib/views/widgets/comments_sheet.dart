import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/video_feed_controller.dart';
import '../../models/video_item.dart';

class CommentsSheet extends StatelessWidget {
  final String videoId;

  const CommentsSheet({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoFeedController>();
    final textCtrl = TextEditingController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        final VideoItem? video =
        controller.videos.firstWhereOrNull((v) => v.id == videoId);
        if (video == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${video.commentsCount})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: video.comments.isEmpty
                  ? const Center(child: Text('No comments yet.'))
                  : ListView.separated(
                itemCount: video.comments.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (_, index) => Text(video.comments[index]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    controller.addComment(videoId, textCtrl.text);
                    textCtrl.clear();
                  },
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}