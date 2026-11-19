import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/video_item.dart';
import '../services/network_service.dart';
import '../services/video_repository.dart';
import 'video_player_manager.dart';

class VideoFeedController extends GetxController with WidgetsBindingObserver {
  final VideoRepository repository;
  final NetworkService networkService;

  VideoFeedController({
    required this.repository,
    required this.networkService,
  });

  static const int _limit = 5;
  static const String _keyLastIndex = 'saved_feed_index';
  static const String _keyLikedIds = 'saved_liked_ids';

  final GetStorage _storage = GetStorage();
  final VideoPlayerManager playerManager = VideoPlayerManager();

  final RxList<VideoItem> videos = <VideoItem>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isMoreLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxnString errorMsg = RxnString();
  final RxInt playerTick = 0.obs; // UI ko notify karne ke liye jab player ready ho

  int _page = 0;
  Set<String> _likedIds = {};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    playerManager.onPlayerReady = () {
      playerTick.value++;
    };

    final savedLikes = _storage.read<List<dynamic>>(_keyLikedIds) ?? [];
    _likedIds = savedLikes.map((e) => e.toString()).toSet();

    fetchInitialVideos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      playerManager.pauseAll();
      _storage.write(_keyLastIndex, currentIndex.value);
    } else if (state == AppLifecycleState.resumed) {
      playerManager.resumeCurrent(videos, currentIndex.value);
    }
  }

  Future<void> fetchInitialVideos() async {
    if (!networkService.isOnline.value && videos.isEmpty) {
      errorMsg.value = 'No internet connection. Please connect and retry.';
      return;
    }

    isLoading.value = true;
    errorMsg.value = null;
    _page = 0;
    hasMore.value = true;

    try {
      final list = await repository.getVideos(page: _page, limit: _limit);
      videos.assignAll(list.map(_syncSavedLike).toList());

      if (list.length < _limit) {
        hasMore.value = false;
      }

      // Purani feed position restore karo
      final savedIndex = _storage.read<int>(_keyLastIndex) ?? 0;
      if (savedIndex > 0 && savedIndex < videos.length) {
        currentIndex.value = savedIndex;
      }

      playerManager.updateActiveWindow(
        videos: videos,
        activeIndex: currentIndex.value,
      );
    } catch (e) {
      errorMsg.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (!networkService.isOnline.value) {
      Get.snackbar('Offline', 'Internet connection required to refresh.');
      return;
    }

    errorMsg.value = null;
    _page = 0;
    hasMore.value = true;

    try {
      final list = await repository.getVideos(page: 0, limit: _limit);
      await playerManager.disposeAll();
      videos.assignAll(list.map(_syncSavedLike).toList());
      currentIndex.value = 0;
      _storage.write(_keyLastIndex, 0);

      if (list.length < _limit) {
        hasMore.value = false;
      }

      playerManager.updateActiveWindow(
        videos: videos,
        activeIndex: 0,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> loadMoreVideos() async {
    if (isMoreLoading.value ||
        !hasMore.value ||
        !networkService.isOnline.value) {
      return;
    }

    isMoreLoading.value = true;
    errorMsg.value = null;

    try {
      final nextPage = _page + 1;
      final list = await repository.getVideos(page: nextPage, limit: _limit);

      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        _page = nextPage;
        videos.addAll(list.map(_syncSavedLike));
        if (list.length < _limit) {
          hasMore.value = false;
        }
        playerManager.updateActiveWindow(
          videos: videos,
          activeIndex: currentIndex.value,
        );
      }
    } catch (e) {
      errorMsg.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isMoreLoading.value = false;
    }
  }

  Future<void> onPageChanged(int index) async {
    currentIndex.value = index;
    _storage.write(_keyLastIndex, index);

    playerManager.updateActiveWindow(
      videos: videos,
      activeIndex: index,
    );

    // End se 2 video pehle next page load kar lo
    if (index >= videos.length - 2) {
      await loadMoreVideos();
    }
  }

  void toggleLike(String videoId) {
    final idx = videos.indexWhere((v) => v.id == videoId);
    if (idx == -1) return;

    final current = videos[idx];
    final liked = !current.isLiked;
    final updatedLikes = liked ? current.likes + 1 : current.likes - 1;

    videos[idx] = current.copyWith(
      isLiked: liked,
      likes: updatedLikes < 0 ? 0 : updatedLikes,
    );

    if (liked) {
      _likedIds.add(videoId);
    } else {
      _likedIds.remove(videoId);
    }
    _storage.write(_keyLikedIds, _likedIds.toList());
  }

  void addComment(String videoId, String commentText) {
    final text = commentText.trim();
    if (text.isEmpty) return;

    final idx = videos.indexWhere((v) => v.id == videoId);
    if (idx == -1) return;

    final current = videos[idx];
    videos[idx] = current.copyWith(
      commentsCount: current.commentsCount + 1,
      comments: [...current.comments, text],
    );
  }

  void shareVideo(VideoItem item) {
    final idx = videos.indexWhere((v) => v.id == item.id);
    if (idx != -1) {
      videos[idx] = item.copyWith(shares: item.shares + 1);
    }
    Get.snackbar(
      'Shared',
      'Link copied for ${item.username}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  VideoItem _syncSavedLike(VideoItem item) {
    if (_likedIds.contains(item.id)) {
      return item.copyWith(isLiked: true, likes: item.likes + 1);
    }
    return item;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    playerManager.disposeAll();
    super.onClose();
  }
}