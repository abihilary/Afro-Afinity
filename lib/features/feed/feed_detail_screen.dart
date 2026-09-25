import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/safe_image.dart';
import '../../models/feed.dart';
import '../../models/feed_store.dart';
import '../../models/profile.dart';

import '../chat/chat_screen.dart';
import '../discover/profile_detail_sheet.dart';

class FeedDetailScreen extends StatefulWidget {
  const FeedDetailScreen({super.key, required this.post});

  final FeedPost post;

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  final _commentController = TextEditingController();
  final FeedStore _feedStore = FeedStore.instance;

  final List<_FeedComment> _comments = [
    _FeedComment(
      authorName: 'Jelani',
      authorAvatar:
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=900&q=90',
      text: 'Stuttgart looks so serene! ✨',
      timeAgo: '1h ago',
    ),
    _FeedComment(
      authorName: 'Nadia',
      authorAvatar:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=90',
      text: 'Love this photo so much! 📸',
      timeAgo: '45m ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _feedStore.addListener(_refresh);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _feedStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(
        0,
        _FeedComment(
          authorName: 'Kofi',
          authorAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=90',
          text: text,
          timeAgo: 'Just now',
        ),
      );
      _commentController.clear();
    });

    _feedStore.addComment(widget.post.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment added! 💬'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.purple,
      ),
    );
  }

  void _openAuthorProfile() {
    final profile = DiscoverProfile(
      id: widget.post.authorId,
      name: widget.post.authorName,
      age: 26,
      location: widget.post.location.formatted,
      distance: '5 km away',
      imageUrl: widget.post.authorAvatar,
      bio: widget.post.caption,
      prompt: 'What’s your dream travel destination?',
      interests: const ['Afrobeats', 'Travel', 'Culture', 'Photography'],
      verified: widget.post.isAuthorVerified,
      premium: true,
    );
    ProfileDetailSheet.show(context, profile);
  }

  void _messageAuthor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          name: widget.post.authorName,
          imageUrl: widget.post.authorAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final mediaUrl = post.media.isNotEmpty ? post.media.first.url : '';

    return ParticleBurstOverlay(
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: AppBar(
          backgroundColor: ThemeColors.background(context),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ThemeColors.text(context),
              size: 20,
            ),
          ),
          title: Text(
            'Post Detail',
            style: TextStyle(
              color: ThemeColors.text(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _openAuthorProfile,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SafeImage(
                                    urlOrPath: post.authorAvatar,
                                    width: 46,
                                    height: 46,
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _openAuthorProfile,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: TextStyle(
                                          color: ThemeColors.text(context),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (post.isAuthorVerified) ...[
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: AppColors.purple,
                                          size: 16,
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: post.visibility == 'public'
                                              ? AppColors.pink
                                                  .withValues(alpha: 0.15)
                                              : AppColors.purple
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          post.visibility == 'public'
                                              ? '🌐 Public'
                                              : '🔒 Private',
                                          style: TextStyle(
                                            color: post.visibility == 'public'
                                                ? AppColors.pink
                                                : AppColors.purple,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: AppColors.gold,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        post.location.formatted,
                                        style: TextStyle(
                                          color: ThemeColors.mutedText(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Full Photo Display with Double-Tap Heart Burst
                    if (mediaUrl.isNotEmpty)
                      GestureDetector(
                        onDoubleTap: () {
                          _feedStore.toggleLike(post.id);
                          ParticleBurstOverlay.trigger(context, emoji: '❤️');
                        },
                        child: SafeImage(
                          urlOrPath: mediaUrl,
                          width: double.infinity,
                          height: 360,
                        ),
                      ),

                    // Caption
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        post.caption,
                        style: TextStyle(
                          color: ThemeColors.text(context),
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Action Buttons Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          PressableScale(
                            onTap: () {
                              _feedStore.toggleLike(post.id);
                              if (post.isLiked) {
                                ParticleBurstOverlay.trigger(context,
                                    emoji: '❤️');
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  post.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: post.isLiked
                                      ? AppColors.pink
                                      : ThemeColors.text(context),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likeCount} Likes',
                                  style: TextStyle(
                                    color: post.isLiked
                                        ? AppColors.pink
                                        : ThemeColors.text(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: ThemeColors.text(context),
                                size: 21,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.commentCount} Comments',
                                style: TextStyle(
                                  color: ThemeColors.text(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          PressableScale(
                            onTap: _messageAuthor,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.near_me_rounded,
                                    color: AppColors.gold,
                                    size: 15,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 28),

                    // Comments Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'COMMENTS (${_comments.length})',
                        style: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comments List
                    ..._comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SafeImage(
                                urlOrPath: comment.authorAvatar,
                                width: 36,
                                height: 36,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ThemeColors.surface(context),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: ThemeColors.border(context)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: TextStyle(
                                            color: ThemeColors.text(context),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          comment.timeAgo,
                                          style: TextStyle(
                                            color:
                                                ThemeColors.mutedText(context),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: TextStyle(
                                        color: ThemeColors.text(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Comment Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: ThemeColors.surface(context),
                border: Border(
                    top: BorderSide(color: ThemeColors.border(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: ThemeColors.background(context),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: ThemeColors.border(context)),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: ThemeColors.text(context)),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: ThemeColors.mutedText(context),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressableScale(
                    onTap: _addComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.pink, AppColors.purple],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedComment {
  const _FeedComment({
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.timeAgo,
  });

  final String authorName;
  final String authorAvatar;
  final String text;
  final String timeAgo;
}
