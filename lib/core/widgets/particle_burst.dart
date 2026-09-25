import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBurstOverlay extends StatefulWidget {
  const ParticleBurstOverlay({
    super.key,
    required this.child,
    this.particleEmoji = '❤️',
  });

  final Widget child;
  final String particleEmoji;

  static void trigger(BuildContext context, {String emoji = '❤️'}) {
    final state = context.findAncestorStateOfType<_ParticleBurstOverlayState>();
    state?.triggerBurst(emoji: emoji);
  }

  @override
  State<ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void triggerBurst({String? emoji}) {
    final particleEmoji = emoji ?? widget.particleEmoji;
    _particles.clear();

    for (int i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 80.0 + _random.nextDouble() * 140.0;
      final scale = 0.6 + _random.nextDouble() * 0.8;

      _particles.add(
        _Particle(
          dx: math.cos(angle) * speed,
          dy: math.sin(angle) * speed - 60.0,
          emoji: particleEmoji,
          scale: scale,
          rotation: (_random.nextDouble() - 0.5) * 0.8,
        ),
      );
    }

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.dx,
    required this.dy,
    required this.emoji,
    required this.scale,
    required this.rotation,
  });

  final double dx;
  final double dy;
  final String emoji;
  final double scale;
  final double rotation;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final particle in particles) {
      final currentPos = Offset(
        center.dx + particle.dx * progress,
        center.dy + particle.dy * progress - (progress * 40.0),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.emoji,
          style: TextStyle(
            fontSize: 24 * particle.scale,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(particle.rotation * progress);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
