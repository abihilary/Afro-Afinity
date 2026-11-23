import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../ui/api_errors.dart';
import 'safe_image.dart';

/// The gold primary button used across the app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon, this.height = 54});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: enabled
              ? const LinearGradient(colors: [AppColors.gold, Color(0xFFF2C14E)])
              : LinearGradient(colors: [Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: .08)]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, size: 20, color: enabled ? Colors.black : Colors.white38), const SizedBox(width: 8)],
                      Text(label,
                          style: TextStyle(
                              color: enabled ? Colors.black : Colors.white38, fontWeight: FontWeight.w800, fontSize: 16)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: .18)),
            shape: const StadiumBorder(),
          ),
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.size = 48, this.online = false, this.blur = false});
  final String? url;
  final double size;
  final bool online;
  final bool blur;
  @override
  Widget build(BuildContext context) {
    Widget img = SafeImage(urlOrPath: url, width: size, height: size, borderRadius: BorderRadius.circular(size / 2));
    if (blur) {
      img = ClipOval(child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: img));
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        img,
        if (online)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * .26,
              height: size * .26,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black, width: 2),
              ),
            ),
          ),
      ]),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.5));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .12), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.gold, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, height: 1.45)),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 220, child: PrimaryButton(label: action!, onPressed: onAction, height: 46)),
            ],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load this',
        body: errorText(error),
        action: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.color, this.selected = false, this.onTap});
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: .18) : Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c : Colors.white.withValues(alpha: .10)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: selected ? c : Colors.white70), const SizedBox(width: 6)],
          Text(label,
              style: TextStyle(
                  color: selected ? c : Colors.white.withValues(alpha: .85), fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  // A Material (not a coloured DecoratedBox), so ListTiles inside keep their
  // ink splashes.
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Material(
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.white.withValues(alpha: .07)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
      );
}

/// A row in a list of settings or actions.
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.icon, required this.label, this.subtitle, this.onTap, this.trailing, this.danger = false});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (danger ? AppColors.error : AppColors.gold).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: danger ? AppColors.error : AppColors.gold),
        ),
        title: Text(label, style: TextStyle(color: danger ? AppColors.error : Colors.white, fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: Colors.white38)),
      );
}

/// Prefixes the coin amount with the coin glyph.
class CoinAmount extends StatelessWidget {
  const CoinAmount(this.coins, {super.key, this.size = 14, this.color = AppColors.gold});
  final int coins;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.toll_rounded, size: size + 2, color: color),
        const SizedBox(width: 4),
        Text('$coins', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size)),
      ]);
}

/// An error shown inside a bottom sheet, where a SnackBar would land behind
/// the sheet and never be seen.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: .4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message!, style: const TextStyle(color: Colors.white, height: 1.35))),
      ]),
    );
  }
}
