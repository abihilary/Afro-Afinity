import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../models/me.dart';
import '../state/providers.dart';

/// Every member-to-member action needs `verified_at` and `status = active`
/// (the API's `requireVerified`). Check before the tap, not after the 403.
bool canAct(WidgetRef ref) => ref.read(meProvider).valueOrNull?.canInteract ?? false;

/// Returns true when the member may act; otherwise explains why and offers
/// the way through. Use as `if (!ensureVerified(context, ref)) return;`.
bool ensureVerified(BuildContext context, WidgetRef ref) {
  final me = ref.read(meProvider).valueOrNull;
  if (me?.canInteract ?? false) return true;
  showVerifySheet(context, me);
  return false;
}

void showVerifySheet(BuildContext context, Me? me) {
  final pending = me?.verification?.status == 'pending';
  final rejected = me?.verification?.status == 'rejected';
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 22),
          Icon(pending ? Icons.hourglass_top_rounded : Icons.verified_user_rounded, color: AppColors.gold, size: 44),
          const SizedBox(height: 14),
          Text(
            pending ? 'Your verification is under review' : rejected ? 'Verification needs another try' : 'Verify to connect',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            pending
                ? 'You can browse while we check your selfie and ID. Liking, messaging and gifts open once you are approved.'
                : rejected
                    ? (me?.verification?.note ?? 'Your last submission could not be approved. Send a new selfie and ID photo.')
                    : 'Every member on Afro Affinity is verified. Send a selfie and a photo of your ID to like, message and send gifts.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 22),
          if (!pending)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/verification');
                },
                child: const Text('Verify now', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ]),
      ),
    ),
  );
}
