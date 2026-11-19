import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/video_feed_controller.dart';
import '../../models/video_item.dart';
import 'comments_sheet.dart';

class VideoCard extends GetView<VideoFeedController> {
  final VideoItem item;

  const VideoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final player = controller.playerManager.getController(item.id);
        if (player != null && player.value.isInitialized) {
          player.value.isPlaying ? player.pause() : player.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player Area
          Obx(() {
            // playerTick observe karne se controller ready hote hi UI rebuild hoga
            controller.playerTick.value;
            final player = controller.playerManager.getController(item.id);

            if (controller.playerManager.hasError(item.id)) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load video stream',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller.playerManager.retryVideo(
                        item,
                        autoPlay: true,
                      ),
                      child: const Text('Retry Video'),
                    ),
                  ],
                ),
              );
            }

            if (player == null || !player.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio > 0
                    ? player.value.aspectRatio
                    : 9 / 16,
                child: VideoPlayer(player),
              ),
            );
          }),

          // Bottom Left Video Info
          Positioned(
            left: 16,
            right: 80,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.caption,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Right Side Action Buttons (Like, Comment, Share)
          Positioned(
            right: 12,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SideButton(
                  icon: item.isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: item.isLiked ? Colors.red : Colors.white,
                  count: '${item.likes}',
                  onTap: () => controller.toggleLike(item.id),
                ),
                const SizedBox(height: 18),
                _SideButton(
                  icon: Icons.comment_outlined,
                  count: '${item.commentsCount}',
                  onTap: () => Get.bottomSheet(
                    CommentsSheet(videoId: item.id),
                    isScrollControlled: true,
                  ),
                ),
                const SizedBox(height: 18),
                _SideButton(
                  icon: Icons.share_outlined,
                  count: '${item.shares}',
                  onTap: () => controller.shareVideo(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String count;
  final VoidCallback onTap;
  final Color iconColor;

  const _SideButton({
    required this.icon,
    required this.count,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}