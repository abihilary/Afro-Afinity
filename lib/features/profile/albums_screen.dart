import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/ui/api_errors.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/safe_image.dart';

const _levels = {
  'everyone': 'Everyone',
  'members': 'Members',
  'connections': 'Matches & friends',
  'only_me': 'Only me',
};

final _myAlbumsProvider = FutureProvider.autoDispose<List<Json>>((ref) async {
  return asMapList((await ref.read(apiClientProvider).getJson('/me/albums'))['items']);
});

/// Private albums: each has its own visibility, decided server-side by
/// `can_view_album`. Photos live in the private `albums` bucket.
class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Json? album]) async {
    if (album == null && !ensureVerified(context, ref)) return;
    final name = TextEditingController(text: asString(album?['name']) ?? '');
    var vis = asString(album?['visibility']) ?? 'connections';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: AppColors.darkSurface2,
          title: Text(album == null ? 'New album' : 'Album settings', style: const TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, maxLength: 60, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Name')),
            RadioGroup<String>(
              groupValue: vis,
              onChanged: (v) => set(() => vis = v ?? vis),
              child: Column(children: [
                for (final l in _levels.entries)
                  RadioListTile<String>(value: l.key, dense: true, activeColor: AppColors.gold, title: Text(l.value, style: const TextStyle(color: Colors.white))),
              ]),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      final body = {'name': name.text.trim(), 'visibility': vis};
      album == null ? await api.post('/me/albums', data: body) : await api.patch('/me/albums/${album['id']}', data: body);
      ref.invalidate(_myAlbumsProvider);
    } catch (e) {
      if (context.mounted) handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(_myAlbumsProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Private albums')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New album', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: albums.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_myAlbumsProvider)),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No albums yet',
                body: 'Keep extra photos for the people you choose — matches and friends, members, or only you.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final a = items[i];
                  return SectionCard(
                    padding: const EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _AlbumEditor(album: a))).then((_) => ref.invalidate(_myAlbumsProvider)),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: a['cover_url'] == null
                            ? Container(decoration: BoxDecoration(color: AppColors.darkSurface2, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_outlined, color: Colors.white38))
                            : SafeImage(urlOrPath: asString(a['cover_url']), borderRadius: BorderRadius.circular(12)),
                      ),
                      title: Text(asString(a['name']) ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      subtitle: Text('${asInt(a['photo_count']) ?? 0} photos · ${_levels[asString(a['visibility'])] ?? ''}', style: const TextStyle(color: Colors.white54)),
                      trailing: PopupMenuButton<String>(
                        iconColor: Colors.white54,
                        color: AppColors.darkSurface2,
                        onSelected: (v) async {
                          if (v == 'edit') return _edit(context, ref, a);
                          try {
                            await ref.read(apiClientProvider).delete('/me/albums/${a['id']}');
                            ref.invalidate(_myAlbumsProvider);
                          } catch (e) {
                            if (context.mounted) handleApiError(context, e);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Rename / visibility', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'delete', child: Text('Delete album', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AlbumEditor extends ConsumerStatefulWidget {
  const _AlbumEditor({required this.album});
  final Json album;
  @override
  ConsumerState<_AlbumEditor> createState() => _AlbumEditorState();
}

class _AlbumEditorState extends ConsumerState<_AlbumEditor> {
  List<Json> _photos = [];
  bool _loading = true;
  bool _saving = false;

  String get _id => asString(widget.album['id']) ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await ref.read(apiClientProvider).getJson('/albums/$_id/photos');
      if (mounted) setState(() => _photos = asMapList(j['items']));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The album's set is replaced whole, like the main photo grid.
  Future<void> _save(List<String> paths) async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).put('/me/albums/$_id/photos', data: {'paths': paths});
      await _load();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _add() async {
    final files = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _saving = true);
    final storage = ref.read(storageServiceProvider);
    final added = <String>[];
    try {
      for (final f in files) {
        added.add(await storage.upload(bucket: 'albums', bytes: await f.readAsBytes(), ext: extOf(f.name)));
      }
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
    await _save([..._photos.map((p) => asString(p['path'])!).whereType<String>(), ...added]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: Text(asString(widget.album['name']) ?? 'Album')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: _saving ? null : _add,
        child: _saving ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2) : const Icon(Icons.add_photo_alternate_rounded),
      ),
      body: _loading
          ? const LoadingView()
          : _photos.isEmpty
              ? const EmptyState(icon: Icons.add_photo_alternate_outlined, title: 'This album is empty', body: 'Tap + to add photos.')
              : GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(12),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final p in _photos)
                      GestureDetector(
                        onLongPress: () => _save(_photos.where((x) => x != p).map((x) => asString(x['path'])).whereType<String>().toList()),
                        child: SafeImage(urlOrPath: asString(p['url']), borderRadius: BorderRadius.circular(12)),
                      ),
                  ],
                ),
      bottomNavigationBar: _photos.isEmpty
          ? null
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Long-press a photo to remove it.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
    );
  }
}
