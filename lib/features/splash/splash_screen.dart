import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/gradients.dart';
import '../../core/widgets/safe_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  static const String _coupleImageUrl =
      'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2'
      '?w=1600&q=90&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _scale = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
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
        fit: StackFit.expand,
        children: [
          // ============================================================
          // 1. COUPLE BACKGROUND
          // ============================================================
          //
          // IMPORTANT:
          // This layer is NOT inside the entrance animation.
          // Therefore the couple remains visible for the entire splash.
          //
          const Positioned.fill(
            child: SafeImage(
              urlOrPath: _coupleImageUrl,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // ============================================================
          // 2. CINEMATIC DARK OVERLAY
          // ============================================================
          //
          // Much lighter than the previous 0.94 bottom overlay.
          // The photograph remains clearly visible.
          //
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.48),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                    stops: const [
                      0.0,
                      0.32,
                      0.68,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // 3. SUBTLE CINEMATIC VIGNETTE
          // ============================================================
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                    ],
                    stops: const [
                      0.52,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // 4. GOLD AMBIENT LIGHT
          // ============================================================
          Positioned(
            top: -130,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 390,
                height: 390,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.16),
                      AppColors.gold.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [
                      0.0,
                      0.38,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // 5. FOREGROUND CONTENT
          // ============================================================
          //
          // ONLY the content is animated.
          // The photograph underneath NEVER fades away.
          //
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // AA LOGO
                        // ==================================================
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black.withValues(alpha: 0.34),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.62),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.24),
                                blurRadius: 38,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return AppGradients.gold.createShader(bounds);
                            },
                            child: const Text(
                              'AA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // AFFINITY
                        // ==================================================
                        const Text(
                          'Affinity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 14,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 9),

                        // ==================================================
                        // TAGLINE
                        // ==================================================
                        const Text(
                          'Rooted in Culture, Connected by Heart',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 0.35,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),

                        // ==================================================
                        // LOADING DOTS
                        // ==================================================
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(delay: 0),
                            const SizedBox(width: 8),
                            _Dot(delay: 140),
                            const SizedBox(width: 8),
                            _Dot(delay: 280),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // FOOTER
                        // ==================================================
                        const Text(
                          'PREMIUM BLACK • 2026',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// LOADING DOT
// ========================================================================

class _Dot extends StatefulWidget {
  const _Dot({
    required this.delay,
  });

  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(
      Duration(milliseconds: widget.delay),
          () {
        if (!mounted) return;

        _controller.repeat(reverse: true);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.30,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold,
        ),
      ),
    );
  }
}