import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'create_post_sheet.dart';
import 'feed_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedStore _feedStore = FeedStore.instance;

  @override
  void initState() {
    super.initState();
    _feedStore.addListener(_refresh);
  }

  @override
  void dispose() {
    _feedStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _openAuthorProfile(FeedPost post) {
    final profile = DiscoverProfile(
      id: post.authorId,
      name: post.authorName,
      age: 26,
      location: post.location.formatted,
      distance: '5 km away',
      imageUrl: post.authorAvatar,
      bio: post.caption,
      prompt: 'What’s your dream travel destination?',
      interests: const ['Afrobeats', 'Travel', 'Culture', 'Photography'],
      verified: post.isAuthorVerified,
      premium: true,
    );
    ProfileDetailSheet.show(context, profile);
  }

  void _openPostDetail(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedDetailScreen(post: post),
      ),
    );
  }

  void _messageAuthor(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          name: post.authorName,
          imageUrl: post.authorAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _feedStore.posts;

    return ParticleBurstOverlay(
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: AppBar(
          backgroundColor: ThemeColors.background(context),
          elevation: 0,
          title: Text(
            'Feeds',
            style: TextStyle(
              color: ThemeColors.text(context),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PressableScale(
                onTap: () => CreatePostSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.pink, AppColors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: posts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dynamic_feed_rounded,
                      color: AppColors.gold,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No feed posts yet',
                      style: TextStyle(
                        color: ThemeColors.text(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Be the first to share a moment!',
                      style: TextStyle(
                        color: ThemeColors.mutedText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _AnimatedFeedCard(
                    index: index,
                    child: _FeedCardItem(
                      post: post,
                      onCardTap: () => _openPostDetail(post),
                      onAvatarTap: () => _openAuthorProfile(post),
                      onMessageTap: () => _messageAuthor(post),
                      onLikeTap: () {
                        _feedStore.toggleLike(post.id);
                        if (post.isLiked) {
                          ParticleBurstOverlay.trigger(context, emoji: '❤️');
                        }
                      },
                    ),
                  );
                },
              ),
        bottomNavigationBar: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: ThemeColors.surface(context),
            border: Border(
              top: BorderSide(
                color: ThemeColors.border(context),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FeedNavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                onTap: () => context.go('/discover'),
              ),
              _FeedNavItem(
                icon: Icons.favorite_border_rounded,
                label: 'Likes',
                badge: '12',
                onTap: () => context.push('/likes'),
              ),
              _FeedNavItem(
                icon: Icons.dynamic_feed_rounded,
                label: 'Feeds',
                active: true,
                onTap: () {},
              ),
              _FeedNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                dot: true,
                onTap: () => context.push('/chat'),
              ),
              _FeedNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedCardItem extends StatelessWidget {
  const _FeedCardItem({
    required this.post,
    required this.onCardTap,
    required this.onAvatarTap,
    required this.onMessageTap,
    required this.onLikeTap,
  });

  final FeedPost post;
  final VoidCallback onCardTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onMessageTap;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.media.isNotEmpty ? post.media.first.url : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ThemeColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header Row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SafeImage(
                          urlOrPath: post.authorAvatar,
                          width: 44,
                          height: 44,
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
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onAvatarTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: TextStyle(
                                color: ThemeColors.text(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (post.isAuthorVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.purple,
                                size: 15,
                              ),
                            ],
                            const SizedBox(width: 8),
                            // Visibility Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: post.visibility == 'public'
                                    ? AppColors.pink.withValues(alpha: 0.15)
                                    : AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                post.visibility == 'public'
                                    ? '🌐 Public'
                                    : '🔒 Private',
                                style: TextStyle(
                                  color: post.visibility == 'public'
                                      ? AppColors.pink
                                      : AppColors.purple,
                                  fontSize: 9.5,
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
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              post.location.formatted,
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• 2h ago',
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 10.5,
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

          // Photo Media & Caption (Tap to view Post Detail)
          GestureDetector(
            onTap: onCardTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mediaUrl.isNotEmpty)
                  ClipRRect(
                    child: SafeImage(
                      urlOrPath: mediaUrl,
                      width: double.infinity,
                      height: 280,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Text(
                    post.caption,
                    style: TextStyle(
                      color: ThemeColors.text(context),
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Bar (Like, Comment, Message, Share)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              children: [
                // Like Action
                PressableScale(
                  onTap: onLikeTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: post.isLiked ? AppColors.pink : ThemeColors.text(context),
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: post.isLiked
                                ? AppColors.pink
                                : ThemeColors.text(context),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Comment Action
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: ThemeColors.text(context),
                        size: 19,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(
                          color: ThemeColors.text(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Direct Message Button
                PressableScale(
                  onTap: onMessageTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          color: AppColors.gold,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Message',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11.5,
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
        ],
      ),
    );
  }
}

class _FeedNavItem extends StatelessWidget {
  const _FeedNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.badge,
    this.dot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final String? badge;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : Colors.white54;

    return SizedBox(
      width: 62,
      child: PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -12,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4771),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  if (dot)
                    Positioned(
                      right: -4,
                      top: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5578),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedFeedCard extends StatefulWidget {
  const _AnimatedFeedCard({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedFeedCard> createState() => _AnimatedFeedCardState();
}

class _AnimatedFeedCardState extends State<_AnimatedFeedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
