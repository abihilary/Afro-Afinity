import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../models/profile.dart';

class MatchOverlay extends StatelessWidget {
  const MatchOverlay({
    super.key,
    required this.profile,
    required this.onMessage,
    required this.onMessageLater,
  });

  final DiscoverProfile profile;
  final VoidCallback onMessage;
  final VoidCallback onMessageLater;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .86),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: .16),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.gold,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'It’s a match!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${profile.name} liked each other.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 178,
                  height: 218,
                  child: Stack(
                    children: [
                      Transform.rotate(
                        angle: -.10,
                        child: _Avatar(imageUrl: profile.imageUrl),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Transform.rotate(
                          angle: .10,
                          child: _Avatar(imageUrl: profile.imageUrl),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Message'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onMessageLater,
                  child: const Text(
                    'Send a message later',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => Container(
        width: 128,
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.darkSurface,
              child: Icon(Icons.person_rounded, color: Colors.white24),
            ),
          ),
        ),
      );
}
