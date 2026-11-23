import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../../models/me.dart';
import '../auth/verification/verify_step.dart';
import '../profile/forms/about_form.dart';
import '../profile/forms/basics_form.dart';
import '../profile/forms/prompts_form.dart';
import '../profile/widgets/photo_grid.dart';

/// Basics → Photos → About → Prompts → Verify → Done, as the web wizard.
/// Each step saves with `PATCH /me` and records `onboarding_step`, so a member
/// who leaves comes back where they stopped. Verify ends with
/// `/me/complete-onboarding`, the only thing that may move `status`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _titles = ['The basics', 'Your photos', 'About you', 'Prompts & voice', 'Verify your identity'];
  static const _subtitles = [
    'This is what people see first.',
    'Add at least one clear photo of your face. Up to six.',
    'Help the right people find you.',
    'Give people something to reply to.',
    'Every member is verified by a person. A selfie and an ID photo, and you are in.',
  ];
  late int _step = _resume(ref.read(meProvider).valueOrNull);
  bool _done = false;
  bool _savingPhotos = false;

  int _resume(Me? me) {
    if (me == null || me.status != MemberStatus.onboarding) return 0;
    return me.onboardingStep.clamp(0, 4);
  }

  void _next() => setState(() => _step++);

  Future<void> _photosNext() async {
    if ((ref.read(meProvider).valueOrNull?.photos.length ?? 0) == 0) {
      showToast(context, 'Add at least one photo to continue.', error: true);
      return;
    }
    setState(() => _savingPhotos = true);
    try {
      await ref.read(meProvider.notifier).patch({'onboarding_step': 2});
      _next();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _savingPhotos = false);
    }
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return BasicsForm(submitLabel: 'Continue', onboardingStep: 1, onSaved: (_) => _next());
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PhotoGrid(),
          const SizedBox(height: 10),
          const Text('Tap a photo to make it your main picture or remove it.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Continue', loading: _savingPhotos, onPressed: _photosNext),
        ]);
      case 2:
        return AboutForm(submitLabel: 'Continue', onboardingStep: 3, onSaved: (_) => _next());
      case 3:
        return PromptsForm(submitLabel: 'Continue', onboardingStep: 4, onSaved: (_) => _next());
      default:
        return VerifyStep(completeOnboarding: true, onDone: () => setState(() => _done = true));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.celebration_rounded,
            title: 'You are all set',
            body: 'We are reviewing your verification. Meanwhile, take a look around — liking and messaging open once you are approved.',
            action: 'Start exploring',
            onAction: () => context.go('/discover'),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          leading: _step > 0 ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => setState(() => _step--)) : null,
          title: Text('Step ${_step + 1} of 5', style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          centerTitle: true,
          actions: [TextButton(onPressed: signOut, child: const Text('Sign out', style: TextStyle(color: Colors.white38)))],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 5,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_titles[_step], style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.4)),
              const SizedBox(height: 6),
              Text(_subtitles[_step], style: const TextStyle(color: Colors.white60, height: 1.45)),
              const SizedBox(height: 8),
              _stepBody(),
            ]),
          ),
        ),
      ),
    );
  }
}
