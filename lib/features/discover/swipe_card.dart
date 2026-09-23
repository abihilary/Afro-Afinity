import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../models/profile.dart';

class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.profile,
    required this.rotation,
    required this.position,
    required this.likeProgress,
    required this.nopeProgress,
    this.compact = false,
  });

  final DiscoverProfile profile;
  final double rotation;
  final Offset position;
  final double likeProgress;
  final double nopeProgress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Transform.translate(
      offset: position,
      child: Transform.rotate(
        angle: rotation,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .58),
                blurRadius: 30,
                offset: const Offset(0, 17),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                profile.imageUrl.startsWith('http')
                    ? Image.network(
                        profile.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _ImageFallback(),
                      )
                    : Image.asset(
                        profile.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _ImageFallback(),
                      ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .34, .68, 1],
                      colors: [
                        Color(0x24000000),
                        Colors.transparent,
                        Color(0xA8000000),
                        Color(0xFA0B0C10),
                      ],
                    ),
                  ),
                ),
                if (!compact) ...[
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _TopPill(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Active now',
                      dark: true,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _TopPill(
                      icon: Icons.near_me_rounded,
                      label: profile.distance,
                    ),
                  ),
                  Positioned(
                    top: 75,
                    left: 18,
                    child: _SwipeLabel(
                      text: 'LIKE',
                      color: const Color(0xFF56E69A),
                      opacity: likeProgress,
                      angle: -.10,
                    ),
                  ),
                  Positioned(
                    top: 75,
                    right: 18,
                    child: _SwipeLabel(
                      text: 'NOPE',
                      color: const Color(0xFFFF647C),
                      opacity: nopeProgress,
                      angle: .10,
                    ),
                  ),
                ],
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: compact ? 15 : 18,
                  child: compact
                      ? Text(
                          '${profile.name}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : _ProfileDetails(profile: profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.darkSurface,
    alignment: Alignment.center,
    child: const Icon(Icons.person_rounded, color: Colors.white24, size: 96),
  );
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${profile.name}, ${profile.age}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ),
            if (profile.verified)
              const Icon(
                Icons.verified_rounded,
                color: AppColors.gold,
                size: 20,
              ),
            const SizedBox(width: 8),
            const _MoreButton(),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white70,
              size: 15,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                profile.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
          decoration: BoxDecoration(
            color: const Color(0xC913141A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
          ),
          child: Text(
            profile.prompt.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: .15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: profile.interests
              .map(
                (interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: const Color(0xB820222A),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .24),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? const Color(0xB5111217) : const Color(0xEAF5F3F0),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? .22 : .45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: dark ? const Color(0xFFFFB347) : AppColors.black,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.black,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x8A17181D),
        border: Border.all(color: Colors.white.withValues(alpha: .45)),
      ),
      child: const Icon(
        Icons.more_horiz_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({
    required this.text,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  final String text;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
