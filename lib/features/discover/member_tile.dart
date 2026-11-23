import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/widgets/safe_image.dart';
import '../../models/member.dart';

/// A portrait tile for grids (Discover grid, search, likes, favourites).
/// A blurred row (no `see_likes`) has no username and opens nothing.
class MemberGridTile extends StatelessWidget {
  const MemberGridTile({super.key, required this.member, this.badge, this.onTap, this.footer});
  final MemberCard member;
  final String? badge;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final canOpen = !member.blurred && member.username != null;
    Widget image = SafeImage(urlOrPath: member.avatarUrl);
    if (member.blurred) {
      image = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: image);
    }
    return GestureDetector(
      onTap: onTap ?? (canOpen ? () => context.push('/u/${member.username}') : null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          image,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [.5, 1],
                colors: [Colors.transparent, Color(0xE6000000)],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: const TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ),
          if (member.online)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    member.blurred ? (member.age == null ? 'Someone' : 'Someone, ${member.age}') : member.age == null ? member.name : '${member.name}, ${member.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                if (member.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                ],
              ]),
              if (member.city != null || member.distanceLabel != null)
                Text(member.distanceLabel ?? member.city ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
              ?footer,
            ]),
          ),
        ]),
      ),
    );
  }
}

