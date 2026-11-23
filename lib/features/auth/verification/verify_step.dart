import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/common.dart';
import '../../../models/me.dart';

class _Shot {
  const _Shot(this.bytes, this.ext);
  final Uint8List bytes;
  final String ext;
}

/// Selfie + ID → private `verification` bucket → `POST /verification`.
/// During onboarding it also calls `/me/complete-onboarding`, which moves the
/// member to `pending`. Same order as the web's StepVerify.
class VerifyStep extends ConsumerStatefulWidget {
  const VerifyStep({super.key, required this.onDone, this.completeOnboarding = false});
  final VoidCallback onDone;
  final bool completeOnboarding;

  @override
  ConsumerState<VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends ConsumerState<VerifyStep> {
  final _picker = ImagePicker();
  _Shot? _selfie;
  _Shot? _id;
  bool _busy = false;

  Future<void> _take({required bool selfie, ImageSource source = ImageSource.camera}) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null) return;
      final shot = _Shot(await x.readAsBytes(), extOf(x.name));
      setState(() => selfie ? _selfie = shot : _id = shot);
    } catch (_) {
      if (mounted) showToast(context, 'Could not open the camera. Allow camera access in Settings.', error: true);
    }
  }

  Future<void> _submit() async {
    if (_selfie == null || _id == null) return;
    setState(() => _busy = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final paths = await Future.wait([
        storage.upload(bucket: 'verification', bytes: _selfie!.bytes, ext: _selfie!.ext),
        storage.upload(bucket: 'verification', bytes: _id!.bytes, ext: _id!.ext),
      ]);
      final api = ref.read(apiClientProvider);
      await api.post('/verification', data: {'selfie_path': paths[0], 'id_path': paths[1]});
      final me = ref.read(meProvider).valueOrNull;
      if (widget.completeOnboarding || me?.status == MemberStatus.onboarding) {
        ref.read(meProvider.notifier).replace(await api.post('/me/complete-onboarding'));
      } else {
        await ref.read(meProvider.notifier).refresh();
      }
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = ref.watch(meProvider).valueOrNull?.verification;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (rejected?.status == 'rejected')
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: .35)),
          ),
          child: Text(
            rejected?.note ?? 'Your last submission could not be approved. Please try again.',
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ),
      Row(children: [
        Expanded(
          child: _ShotTile(
            label: 'Selfie',
            hint: 'Your face, well lit',
            icon: Icons.face_retouching_natural_rounded,
            shot: _selfie,
            onTap: () => _take(selfie: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShotTile(
            label: 'ID document',
            hint: 'Passport, ID card or licence',
            icon: Icons.badge_outlined,
            shot: _id,
            onTap: () => _take(selfie: false),
            onGallery: () => _take(selfie: false, source: ImageSource.gallery),
          ),
        ),
      ]),
      const SizedBox(height: 18),
      const _Note(),
      const SizedBox(height: 22),
      PrimaryButton(
        label: 'Submit for review',
        loading: _busy,
        onPressed: _selfie != null && _id != null ? _submit : null,
      ),
    ]);
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({required this.label, required this.hint, required this.icon, required this.shot, required this.onTap, this.onGallery});
  final String label;
  final String hint;
  final IconData icon;
  final _Shot? shot;
  final VoidCallback onTap;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: shot == null ? Colors.white12 : AppColors.gold, width: shot == null ? 1 : 1.6),
            ),
            clipBehavior: Clip.antiAlias,
            child: shot == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, color: AppColors.gold, size: 34),
                    const SizedBox(height: 10),
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                    ),
                  ])
                : Stack(fit: StackFit.expand, children: [
                    Image.memory(shot!.bytes, fit: BoxFit.cover),
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(radius: 13, backgroundColor: AppColors.gold, child: Icon(Icons.check, size: 16, color: Colors.black)),
                    ),
                  ]),
          ),
        ),
      ),
      if (onGallery != null)
        TextButton(onPressed: onGallery, child: const Text('Choose from photos', style: TextStyle(color: AppColors.gold, fontSize: 12)))
      else
        const SizedBox(height: 40),
    ]);
  }
}

class _Note extends StatelessWidget {
  const _Note();
  @override
  Widget build(BuildContext context) => const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Both photos go to a private store only our review team can open. They are never shown on your profile.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.45),
          ),
        ),
      ]);
}
