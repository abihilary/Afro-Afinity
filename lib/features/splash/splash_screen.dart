import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/gradients.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: .86,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;

      final authService = ref.read(authServiceProvider.notifier);

      // Try to get current session
      var session = Supabase.instance.client.auth.currentSession;

      // If session is null, try to recover it from local storage explicitly
      // although supabase_flutter should do this, sometimes a small delay or
      // explicit check helps on some platforms.
      if (session == null) {
        debugPrint('No current session found, checking for recoverable session...');
        // In some versions of supabase_flutter, we might need to wait for
        // the auth state to be initialized.
        await Future.delayed(const Duration(milliseconds: 500));
        session = Supabase.instance.client.auth.currentSession;
      }

      if (session != null) {
        debugPrint('Session recovered: ${session.user?.email}');
        final completed = await authService.hasCompletedOnboarding();
        if (completed) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else {
        debugPrint('No session available, redirecting to login');
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.black,
                    AppColors.terracottaDark.withValues(alpha: .28),
                    AppColors.black,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: -180,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: .18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(scale: _scale.value, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.white.withValues(alpha: .06),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: .35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: .18),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.gold.createShader(bounds),
                      child: const Text(
                        'AA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Affinity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Rooted in Culture, Connected by Heart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: .4,
                    ),
                  ),

                  const SizedBox(height: 42),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(delay: 0),
                      const SizedBox(width: 7),
                      _Dot(delay: 140),
                      const SizedBox(width: 7),
                      _Dot(delay: 280),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'PREMIUM BLACK • 2026',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward(from: 0);
      }
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
      opacity: Tween<double>(begin: .35, end: 1).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold,
        ),
      ),
    );
  }
}
