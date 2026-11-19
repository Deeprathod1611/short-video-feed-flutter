import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_feed_controller.dart';
import 'widgets/video_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final VideoFeedController controller = Get.find<VideoFeedController>();
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value && controller.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.videos.isEmpty && controller.errorMsg.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorMsg.value!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchInitialVideos,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        _pageController ??= PageController(
          initialPage: controller.currentIndex.value,
        );

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshFeed,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: controller.videos.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  return VideoCard(item: controller.videos[index]);
                },
              ),
            ),

            // Top Network / Pagination Status Banner
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildStatusBanner(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusBanner() {
    final online = controller.networkService.isOnline.value;
    final error = controller.errorMsg.value;
    final loadingMore = controller.isMoreLoading.value;

    if (online && error == null && !loadingMore) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              !online
                  ? 'You are offline. Loaded videos can still play.'
                  : (error ?? 'Loading more videos...'),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          if (error != null)
            TextButton(
              onPressed: controller.loadMoreVideos,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}