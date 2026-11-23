import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

void showToast(BuildContext context, String message, {bool error = false, SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFF3A1D1D) : AppColors.darkSurface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      action: action,
      // SnackBarAction defaults to a dark label on this dark surface.
      actionOverflowThreshold: .4,
    ));
}
