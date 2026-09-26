import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../models/profile.dart';
import 'discover_profiles.dart';
import 'swipe_card.dart';
import 'swipe_controller.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SwipeController controller = SwipeController();
  int currentIndex = 0;
  bool showGiftTip = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  DiscoverProfile? get currentProfile => currentIndex < discoverProfiles.length
      ? discoverProfiles[currentIndex]
      : null;

  void _completeSwipe() => setState(() => currentIndex++);

  Future<void> _swipe(SwipeDirection direction) async {
    if (currentProfile == null || controller.isAnimatingOut) return;
    await controller.swipe(direction, onComplete: _completeSwipe);
  }

  Future<void> _superLike() async {
    if (currentProfile == null || controller.isAnimatingOut) return;
    await controller.superLike(onComplete: _completeSwipe);
  }

  @override
  Widget build(BuildContext context) {
    final profile = currentProfile;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.8, -.9),
            radius: 1.25,
            colors: [Color(0xFF282115), AppColors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(onFilter: _showFilters),
              Expanded(
                child: profile == null ? _emptyState() : _cardArea(profile),
              ),
              if (profile != null) ...[
                _GiftTip(visible: showGiftTip),
                const SizedBox(height: 2),
                _ActionBar(
                  onUndo: _undo,
                  onNope: () => _swipe(SwipeDirection.left),
                  onSuperLike: _superLike,
                  onGift: _gift,
                  onLike: () => _swipe(SwipeDirection.right),
                ),
              ],
              const SizedBox(height: 5),
              const _BottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardArea(DiscoverProfile profile) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth - 36, 370.0);
        final height = math.min(box.maxHeight - 9, width / .75);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: width,
            height: height + 34,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => controller.update(details.delta),
              onPanEnd: (_) async {
                final result = await controller.endDrag();
                if (result != null) _completeSwipe();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (currentIndex + 1 < discoverProfiles.length)
                    Positioned(
                      top: 25,
                      left: 12,
                      child: SizedBox(
                        width: width - 24,
                        height: height,
                        child: Opacity(
                          opacity: .82,
                          child: SwipeCard(
                            profile: discoverProfiles[currentIndex + 1],
                            rotation: 0,
                            position: Offset.zero,
                            likeProgress: 0,
                            nopeProgress: 0,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: width,
                    height: height,
                    child: SwipeCard(
                      profile: profile,
                      rotation: controller.rotation,
                      position: controller.position,
                      likeProgress: controller.showingLike
                          ? controller.progress
                          : 0,
                      nopeProgress: controller.showingNope
                          ? controller.progress
                          : 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'You’re all caught up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'More people will arrive soon.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => currentIndex = 0),
            child: const Text('Start again'),
          ),
        ],
      ),
    ),
  );

  void _undo() {
    if (currentIndex == 0 || controller.isAnimatingOut) return;
    HapticFeedback.lightImpact();
    setState(() => currentIndex--);
  }

  void _gift() {
    HapticFeedback.selectionClick();
    setState(() => showGiftTip = !showGiftTip);
  }

  void _showFilters() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 36,
                child: Divider(color: Colors.white24, thickness: 3),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Discovery filters',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tune your distance and preferences.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onFilter});
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 11, 18, 8),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFF24262F),
          child: Text(
            'AA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'Affinity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const _CoinPill(),
        const SizedBox(width: 7),
        _HeaderIcon(icon: Icons.tune_rounded, onTap: onFilter),
        const SizedBox(width: 7),
        const _BadgeIcon(icon: Icons.notifications_none_rounded),
        const SizedBox(width: 7),
        _HeaderIcon(icon: Icons.dark_mode_rounded, onTap: () {}),
      ],
    ),
  );
}

class _CoinPill extends StatelessWidget {
  const _CoinPill();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(
      color: const Color(0xFF3A321C),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 16),
        SizedBox(width: 5),
        Text(
          '1,250',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 22,
    child: Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF202129),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    ),
  );
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      const _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: _noop),
      Positioned(
        top: 2,
        right: 3,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFFA84C),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
  static void _noop() {}
}

class _GiftTip extends StatelessWidget {
  const _GiftTip({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 180),
    child: IgnorePointer(
      ignoring: !visible,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF282A33),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'Gift 50 coins to stand out ✨',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onUndo,
    required this.onNope,
    required this.onSuperLike,
    required this.onGift,
    required this.onLike,
  });
  final VoidCallback onUndo, onNope, onSuperLike, onGift, onLike;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.replay_rounded,
          size: 42,
          color: const Color(0xFF8B8E98),
          onTap: onUndo,
        ),
        _ActionButton(
          icon: Icons.close_rounded,
          size: 50,
          color: const Color(0xFFFF6A78),
          onTap: onNope,
        ),
        _ActionButton(
          icon: Icons.star_rounded,
          size: 58,
          color: const Color(0xFF5AD9FF),
          onTap: onSuperLike,
        ),
        _ActionButton(
          icon: Icons.card_giftcard_rounded,
          size: 50,
          color: AppColors.gold,
          onTap: onGift,
        ),
        _ActionButton(
          icon: Icons.favorite_rounded,
          size: 58,
          color: const Color(0xFFFFA21E),
          onTap: onLike,
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: size / 2 + 5,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .18),
        border: Border.all(color: color.withValues(alpha: .82)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .18), blurRadius: 17),
        ],
      ),
      child: Icon(icon, color: color, size: size * .44),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();
  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF292A31))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.explore_rounded,
          label: 'Discover',
          active: true,
          onTap: () => context.go('/home'),
        ),
        _NavItem(
          icon: Icons.favorite_border_rounded,
          label: 'Likes',
          badge: '12',
          onTap: () => context.go('/likes'),
        ),
        _NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          dot: true,
          onTap: () => context.go('/chat'),
        ),
        _NavItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () => context.go('/profile'),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
  final bool active, dot;
  final String? badge;
  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (badge != null)
                  Positioned(right: -12, top: -8, child: _NavBadge(text: badge!)),
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
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFFFF4771),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
