import 'package:get/get.dart';
import '../controllers/video_feed_controller.dart';
import '../services/network_service.dart';
import '../services/video_repository.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoFeedController>(
          () => VideoFeedController(
        repository: VideoRepository(),
        networkService: Get.find<NetworkService>(),
      ),
    );
  }
}