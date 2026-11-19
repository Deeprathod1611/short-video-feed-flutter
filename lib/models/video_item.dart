class VideoItem {
  final String id;
  final String url;
  final String username;
  final String caption;
  final int likes;
  final int commentsCount;
  final int shares;
  final bool isLiked;
  final List<String> comments;

  const VideoItem({
    required this.id,
    required this.url,
    required this.username,
    required this.caption,
    required this.likes,
    required this.commentsCount,
    required this.shares,
    this.isLiked = false,
    this.comments = const [],
  });

  VideoItem copyWith({
    String? id,
    String? url,
    String? username,
    String? caption,
    int? likes,
    int? commentsCount,
    int? shares,
    bool? isLiked,
    List<String>? comments,
  }) {
    return VideoItem(
      id: id ?? this.id,
      url: url ?? this.url,
      username: username ?? this.username,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}