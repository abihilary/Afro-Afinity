import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';

/// Shown while the session restores and `/me` loads. The router's redirect
/// moves on as soon as `/me` answers; this screen only has to handle the
/// case where it does not (offline, server down).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.3),
            radius: 1.1,
            colors: [Color(0xFF2A1B0E), AppColors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/images/mark.png', width: 104, height: 104)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: .96, end: 1.04, duration: 1400.ms, curve: Curves.easeInOut),
              const SizedBox(height: 22),
              Image.asset('assets/images/wordmark.png', width: 190).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 10),
              const Text('Love, rooted in culture',
                  style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: .4)),
              const SizedBox(height: 40),
              if (me.hasError) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(errorText(me.error!),
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.4)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                  onPressed: () => ref.invalidate(meProvider),
                  child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                TextButton(onPressed: signOut, child: const Text('Sign out', style: TextStyle(color: Colors.white54))),
              ] else
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
