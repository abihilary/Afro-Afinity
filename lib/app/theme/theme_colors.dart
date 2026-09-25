import 'package:flutter/material.dart';

import 'colors.dart';

class ThemeColors {
  const ThemeColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) => isDark(context)
      ? AppColors.black
      : AppColors.lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface : AppColors.lightSurface;

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface2 : AppColors.lightSurface2;

  static Color text(BuildContext context) =>
      isDark(context) ? Colors.white : AppColors.lightText;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? Colors.white60 : AppColors.mutedText;

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.darkBorder : AppColors.lightBorder;
}
