import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/me.dart';

/// The member's six photos. Every change (add, remove, reorder) is saved at
/// once with one `PUT /me/photos` carrying the whole ordered list — the
/// endpoint replaces the set, so sending one path at a time keeps only the
/// last. The first photo is the profile picture.
class PhotoGrid extends ConsumerStatefulWidget {
  const PhotoGrid({super.key});
  @override
  ConsumerState<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends ConsumerState<PhotoGrid> {
  int _uploading = 0;
  bool _saving = false;

  Future<void> _save(List<String> paths) async {
    setState(() => _saving = true);
    try {
      ref.read(meProvider.notifier).replace(await ref.read(apiClientProvider).put('/me/photos', data: {'paths': paths}));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _add(List<Photo> current) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
            title: const Text('Choose from photos', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.gold),
            title: const Text('Take a photo', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;
    // iOS will not present the picker while the sheet is still animating away.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final picker = ImagePicker();
    final room = 6 - current.length;
    final files = source == ImageSource.gallery
        ? (await picker.pickMultiImage(maxWidth: 1600, imageQuality: 85, limit: room > 1 ? room : null)).take(room).toList()
        : [?await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85)];
    if (files.isEmpty) return;
    setState(() => _uploading = files.length);
    final storage = ref.read(storageServiceProvider);
    final added = <String>[];
    try {
      for (final f in files) {
        added.add(await storage.upload(bucket: 'photos', bytes: await f.readAsBytes(), ext: extOf(f.name)));
        if (mounted) setState(() => _uploading--);
      }
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = 0);
    }
    if (added.isNotEmpty) await _save([...current.map((p) => p.path), ...added]);
  }

  void _menu(List<Photo> photos, int i) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (i > 0)
            ListTile(
              leading: const Icon(Icons.star_outline_rounded, color: AppColors.gold),
              title: const Text('Make profile picture', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                final paths = photos.map((p) => p.path).toList();
                final p = paths.removeAt(i);
                _save([p, ...paths]);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: const Text('Remove', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _save([for (var j = 0; j < photos.length; j++) if (j != i) photos[j].path]);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(meProvider).valueOrNull?.photos ?? const <Photo>[];
    final tiles = <Widget>[
      for (var i = 0; i < photos.length; i++)
        GestureDetector(
          key: ValueKey(photos[i].path),
          onTap: () => _menu(photos, i),
          child: Stack(fit: StackFit.expand, children: [
            SafeImage(urlOrPath: photos[i].url, borderRadius: BorderRadius.circular(18)),
            if (i == 0)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Main', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      for (var k = 0; k < _uploading; k++)
        Container(
          decoration: BoxDecoration(color: AppColors.darkSurface2, borderRadius: BorderRadius.circular(18)),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        ),
      if (photos.length + _uploading < 6)
        GestureDetector(
          onTap: _saving || _uploading > 0 ? null : () => _add(photos),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.gold, size: 32),
          ),
        ),
    ];
    return Stack(children: [
      GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3 / 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      ),
      if (_saving) const Positioned.fill(child: IgnorePointer(child: Center(child: CircularProgressIndicator(color: AppColors.gold)))),
    ]);
  }
}
