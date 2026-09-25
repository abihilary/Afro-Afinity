import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

enum SwipeDirection { left, right, superLike }

class SwipeController extends ChangeNotifier {
  static const double swipeThreshold = 110;

  Offset position = Offset.zero;
  bool isAnimatingOut = false;
  SwipeDirection? direction;

  double get rotation {
    return (position.dx / 420).clamp(-0.18, 0.18);
  }

  double get progress {
    return (position.dx.abs() / swipeThreshold).clamp(0.0, 1.0);
  }

  bool get showingLike => position.dx > 0;
  bool get showingNope => position.dx < 0;

  void update(Offset delta) {
    if (isAnimatingOut) return;

    position += delta;
    notifyListeners();
  }

  Future<SwipeDirection?> endDrag() async {
    if (isAnimatingOut) return null;

    if (position.dx.abs() < swipeThreshold) {
      position = Offset.zero;
      direction = null;
      notifyListeners();
      return null;
    }

    final selected = position.dx > 0
        ? SwipeDirection.right
        : SwipeDirection.left;

    await swipe(selected);
    return selected;
  }

  Future<void> swipe(
    SwipeDirection selected, {
    VoidCallback? onComplete,
  }) async {
    if (isAnimatingOut) return;

    isAnimatingOut = true;
    direction = selected;

    HapticFeedback.mediumImpact();

    final screenWidth =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final targetX = selected == SwipeDirection.left
        ? -(screenWidth + 300)
        : screenWidth + 300;

    position = Offset(
      targetX,
      selected == SwipeDirection.superLike ? -300 : position.dy,
    );

    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 280));

    onComplete?.call();

    position = Offset.zero;
    direction = null;
    isAnimatingOut = false;

    notifyListeners();
  }

  Future<void> superLike({VoidCallback? onComplete}) {
    HapticFeedback.heavyImpact();

    return swipe(SwipeDirection.superLike, onComplete: onComplete);
  }

  void reset() {
    position = Offset.zero;
    direction = null;
    isAnimatingOut = false;
    notifyListeners();
  }

  double get cardScale {
    final distance = position.distance;
    return math.max(0.96, 1 - distance / 2000);
  }
}
