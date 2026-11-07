import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/safe_image.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  bool _seeLikesPerk = false;
  List<dynamic> _receivedLikes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikesData();
  }

  Future<void> _loadLikesData() async {
    try {
      final apiClient = ApiClient();
      
      // 1. Check /me for perks.see_likes
      final meRes = await apiClient.get('/me');
      if (meRes is Map) {
        final perks = meRes['perks'] ?? meRes['profile']?['perks'];
        if (perks is Map) {
          _seeLikesPerk = perks['see_likes'] == true;
        }
      }

      // 2. Fetch received likes
      final likesRes = await apiClient.get('/likes/received');
      List<dynamic> items = [];
      if (likesRes is List) {
        items = likesRes;
      } else if (likesRes is Map) {
        if (likesRes['items'] is List) {
          items = likesRes['items'];
        } else if (likesRes['likes'] is List) {
          items = likesRes['likes'];
        } else if (likesRes['data'] is List) {
          items = likesRes['data'];
        }
      }

      if (mounted) {
        setState(() {
          _receivedLikes = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading likes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUpgradeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, Color(0xFFFDE68A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'See who likes you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upgrade to Premium or unlock the See Likes perk to instantly reveal everyone who liked your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _seeLikesPerk = true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Upgrade to See Likes • 200 coins',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.background(context),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ThemeColors.text(context),
                  size: 20,
                ),
              )
            : null,
        title: Text(
          'Likes you',
          style: TextStyle(
            color: ThemeColors.text(context),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gold, Color(0xFFFDE68A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.black, size: 16),
                SizedBox(width: 4),
                Text('99+', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _seeLikesPerk ? 'Revealed Admirers' : 'Upgrade to see who liked you.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid of Likes
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _receivedLikes.isNotEmpty ? _receivedLikes.length : 6,
                    itemBuilder: (context, index) {
                      final item = _receivedLikes.isNotEmpty ? _receivedLikes[index] : null;
                      final other = item?['other'] ?? item;
                      final imageUrl = other?['avatar_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';
                      final name = other?['display_name'] ?? 'Admirer';

                      return GestureDetector(
                        onTap: _seeLikesPerk ? null : _showUpgradeSheet,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeImage(urlOrPath: imageUrl),
                              if (!_seeLikesPerk)
                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    child: Center(
                                      child: index == 1
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Premium',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.lock_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'RECENT ADMIRERS',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent admirers list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final names = ['Elena', 'Mika', 'Jade'];
                      final ages = [24, 28, 26];
                      final images = [
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
                        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80',
                        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&q=80',
                      ];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(images[index]),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${names[index]}, ${ages[index]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '1.2 mi • Liked your profile',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _seeLikesPerk ? () {} : _showUpgradeSheet,
                              icon: const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.gold,
                                child: Icon(Icons.favorite, color: Colors.black, size: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Upgrade Banner Card
                  if (!_seeLikesPerk)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E1A2E), Color(0xFF1E1424)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.pink.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.pink, AppColors.purple]),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'See who likes you',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Get premium for instant matches',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showUpgradeSheet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w800)),
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
