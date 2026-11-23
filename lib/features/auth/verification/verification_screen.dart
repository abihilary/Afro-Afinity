import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/common.dart';
import 'verify_step.dart';

/// Resubmission and late verification, outside onboarding. Reads the current
/// state from `me.verification`.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final v = me?.verification;
    Widget body;
    if (me?.verifiedAt != null) {
      body = const EmptyState(icon: Icons.verified_rounded, title: 'You are verified', body: 'Thank you. Your badge shows on your profile.');
    } else if (v?.status == 'pending') {
      body = EmptyState(
        icon: Icons.hourglass_top_rounded,
        title: 'Under review',
        body: 'We received your selfie and ID and will review them shortly. You can keep browsing meanwhile.',
        action: 'Back',
        onAction: () => context.canPop() ? context.pop() : context.go('/discover'),
      );
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Verify your identity', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Every member is checked by a person. Take a selfie and a photo of an ID document — we compare the two.',
            style: TextStyle(color: Colors.white60, height: 1.45),
          ),
          const SizedBox(height: 24),
          VerifyStep(onDone: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/discover');
            }
          }),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: SafeArea(child: body),
    );
  }
}
