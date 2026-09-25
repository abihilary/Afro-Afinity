import 'package:flutter/foundation.dart';

import 'feed.dart';

class FeedStore extends ChangeNotifier {
  FeedStore._();

  static final FeedStore instance = FeedStore._();

  final List<FeedPost> _posts = [
    FeedPost(
      id: 'post_9f72ab',
      authorId: 'user_amara',
      authorName: 'Amara',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=90',
      isAuthorVerified: true,
      type: 'photo',
      caption: 'Beautiful evening in Stuttgart ✨',
      media: [
        const FeedMedia(
          id: 'media_001',
          type: 'image',
          url: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1080&q=90',
          thumbnailUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=400&q=90',
          position: 0,
          width: 1080,
          height: 1350,
        ),
      ],
      location: const FeedLocation(city: 'Stuttgart', country: 'Germany'),
      visibility: 'public',
      commentsEnabled: true,
      likeCount: 89,
      commentCount: 12,
      shareCount: 4,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    FeedPost(
      id: 'post_8e31bc',
      authorId: 'user_jelani',
      authorName: 'Jelani',
      authorAvatar: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=900&q=90',
      isAuthorVerified: true,
      type: 'photo',
      caption: 'Nairobi sunsets hit different 🌇🔥 #AfricanAffinity #SunsetMagic',
      media: [
        const FeedMedia(
          id: 'media_002',
          type: 'image',
          url: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?auto=format&fit=crop&w=1080&q=90',
          thumbnailUrl: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?auto=format&fit=crop&w=400&q=90',
          position: 0,
          width: 1080,
          height: 1350,
        ),
      ],
      location: const FeedLocation(city: 'Nairobi', country: 'Kenya'),
      visibility: 'public',
      commentsEnabled: true,
      likeCount: 142,
      commentCount: 18,
      shareCount: 9,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    FeedPost(
      id: 'post_7d12ea',
      authorId: 'user_nadia',
      authorName: 'Nadia',
      authorAvatar: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=90',
      isAuthorVerified: true,
      type: 'photo',
      caption: 'Weekend vibes in Yaoundé 🌺 Good food, great music, genuine people.',
      media: [
        const FeedMedia(
          id: 'media_003',
          type: 'image',
          url: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1080&q=90',
          thumbnailUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=90',
          position: 0,
          width: 1080,
          height: 1350,
        ),
      ],
      location: const FeedLocation(city: 'Yaoundé', country: 'Cameroon'),
      visibility: 'private',
      commentsEnabled: true,
      likeCount: 65,
      commentCount: 8,
      shareCount: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
  ];

  List<FeedPost> get posts => List.unmodifiable(_posts);

  void addPost(FeedPost post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void toggleLike(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      if (post.isLiked) {
        post.isLiked = false;
        post.likeCount--;
      } else {
        post.isLiked = true;
        post.likeCount++;
      }
      notifyListeners();
    }
  }

  void addComment(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index].commentCount++;
      notifyListeners();
    }
  }
}
