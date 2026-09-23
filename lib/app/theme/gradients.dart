import 'package:flutter/material.dart';

import 'colors.dart';

class AppGradients {
  static const gold = LinearGradient(
    colors: [AppColors.gold, AppColors.goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pinkPurple = LinearGradient(
    colors: [AppColors.pink, AppColors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const luxury = LinearGradient(
    colors: [AppColors.black, AppColors.terracottaDark, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldText = LinearGradient(
    colors: [AppColors.goldLight, AppColors.gold],
  );
}
