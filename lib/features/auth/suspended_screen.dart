import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/colors.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';

class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = asString(ref.watch(configProvider).valueOrNull?['support.email']) ?? 'support@afroaffinity.com';
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Spacer(),
            const Icon(Icons.gpp_maybe_rounded, color: AppColors.gold, size: 56),
            const SizedBox(height: 18),
            const Text('Your account is suspended',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'A moderator has paused this account. If you think this is a mistake, write to us and we will look at it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Contact support',
              icon: Icons.mail_outline_rounded,
              onPressed: () => launchUrl(Uri.parse('mailto:$support?subject=Account%20suspended')),
            ),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Sign out', onPressed: signOut),
          ]),
        ),
      ),
    );
  }
}
