import 'package:flutter/material.dart';

class PulsingIndicator extends StatefulWidget {
  const PulsingIndicator({
    super.key,
    required this.child,
    this.pulseColor = const Color(0xFF22C55E),
    this.minScale = 0.95,
    this.maxScale = 1.12,
  });

  final Widget child;
  final Color pulseColor;
  final double minScale;
  final double maxScale;

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.65,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.pulseColor.withValues(alpha: _glowAnimation.value),
                blurRadius: 10 * _scaleAnimation.value,
                spreadRadius: 2 * _scaleAnimation.value,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
