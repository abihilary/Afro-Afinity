import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// The Afro Affinity logo lock-up for the sign-in and sign-up screens: the
/// swan-heart mark, the name, and the tagline. The mark is the 512 px master
/// from the website's brand folder; the name is set as text so it stays sharp
/// at any size (the site's wordmark image is only 205 px wide).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.markSize = 88, this.showTagline = true});

  final double markSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: .28),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/mark.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'AFRO AFFINITY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.2,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          const Text(
            'Rooted in Culture, Connected by Heart',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD0A956),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: .4,
            ),
          ),
        ],
      ],
    );
  }
}
