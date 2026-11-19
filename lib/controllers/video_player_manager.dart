import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart';

class VideoPlayerManager {
  static const Map<String, String> _requestHeaders = {
    'User-Agent':
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
  };

  final Map<String, VideoPlayerController> _controllers = {};
  final Set<String> _loadingIds = {};
  final Set<String> _errorIds = {};
  Set<String> _activeWindowIds = {};
  Timer? _scrollDebounce;
  VoidCallback? onPlayerReady;

  VideoPlayerController? getController(String videoId) {
    return _controllers[videoId];
  }

  bool hasError(String videoId) => _errorIds.contains(videoId);

  /// Rapid scroll ke waqt turant init/dispose karne se bachata hai
  void updateActiveWindow({
    required List<VideoItem> videos,
    required int activeIndex,
  }) {
    if (videos.isEmpty) return;

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 180), () {
      _applyWindow(videos: videos, activeIndex: activeIndex);
    });
  }

  Future<void> _applyWindow({
    required List<VideoItem> videos,
    required int activeIndex,
  }) async {
    if (videos.isEmpty || activeIndex < 0 || activeIndex >= videos.length) {
      return;
    }

    final int start = (activeIndex - 1).clamp(0, videos.length - 1);
    final int end = (activeIndex + 1).clamp(0, videos.length - 1);

    final Set<String> neededIds = {};
    for (int i = start; i <= end; i++) {
      neededIds.add(videos[i].id);
    }
    _activeWindowIds = neededIds;

    // Window ke bahar ke purane controllers dispose karo
    final List<String> oldIds = _controllers.keys
        .where((id) => !neededIds.contains(id))
        .toList();

    for (final id in oldIds) {
      final controller = _controllers.remove(id);
      _errorIds.remove(id);
      if (controller != null) {
        await controller.pause();
        await controller.dispose();
      }
    }

    // 1. Pehle active video ko priority do
    final VideoItem activeItem = videos[activeIndex];
    final existingActive = _controllers[activeItem.id];
    if (existingActive != null && existingActive.value.isInitialized) {
      if (!existingActive.value.isPlaying) {
        await existingActive.play();
      }
    } else if (!_loadingIds.contains(activeItem.id)) {
      await _initController(activeItem, autoPlay: true);
    }

    // 2. Baaki window videos (previous / next) pause rakho aur preload karo
    for (int i = start; i <= end; i++) {
      if (i == activeIndex) continue;
      final item = videos[i];
      final existing = _controllers[item.id];
      if (existing != null && existing.value.isInitialized) {
        if (existing.value.isPlaying) {
          await existing.pause();
        }
      } else if (!_loadingIds.contains(item.id) &&
          !_errorIds.contains(item.id)) {
        // Adjacent video background mein preload hoga (autoPlay: false)
        unawaited(_initController(item, autoPlay: false));
      }
    }
  }

  Future<void> retryVideo(VideoItem item, {required bool autoPlay}) async {
    _errorIds.remove(item.id);
    _activeWindowIds.add(item.id);
    onPlayerReady?.call();
    await _initController(item, autoPlay: autoPlay);
  }

  Future<void> _initController(VideoItem item, {required bool autoPlay}) async {
    _loadingIds.add(item.id);
    _errorIds.remove(item.id);

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.url),
      httpHeaders: _requestHeaders,
    );

    try {
      await controller.initialize();
      await controller.setLooping(true);

      if (!_activeWindowIds.contains(item.id)) {
        await controller.dispose();
        return;
      }

      _controllers[item.id] = controller;

      if (autoPlay) {
        await controller.play();
      } else {
        await controller.pause();
      }
      onPlayerReady?.call();
    } catch (e) {
      debugPrint('Video init error (${item.id}): $e');
      if (_activeWindowIds.contains(item.id)) {
        _errorIds.add(item.id);
        onPlayerReady?.call();
      }
      await controller.dispose();
    } finally {
      _loadingIds.remove(item.id);
    }
  }

  Future<void> pauseAll() async {
    _scrollDebounce?.cancel();
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        await controller.pause();
      }
    }
  }

  Future<void> resumeCurrent(List<VideoItem> videos, int index) async {
    if (index < 0 || index >= videos.length) return;
    final controller = _controllers[videos[index].id];
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying) {
      await controller.play();
    }
  }

  Future<void> disposeAll() async {
    _scrollDebounce?.cancel();
    for (final controller in _controllers.values) {
      await controller.pause();
      await controller.dispose();
    }
    _controllers.clear();
    _loadingIds.clear();
    _errorIds.clear();
    _activeWindowIds.clear();
  }
}