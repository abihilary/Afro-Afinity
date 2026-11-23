import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/colors.dart';
import '../../content/profile_content.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/safe_image.dart';
import '../../models/member.dart';
import '../../models/profile.dart';
import '../../models/profile_options.dart';
import '../gifts/gift_picker.dart';
import '../matches/match_overlay.dart';
import 'member_actions.dart';

final memberProfileProvider = FutureProvider.autoDispose.family<PublicProfile, String>((ref, username) async {
  return PublicProfile(await ref.read(apiClientProvider).getJson('/profiles/$username'));
});

final memberAlbumsProvider = FutureProvider.autoDispose.family<List<Json>, String>((ref, username) async {
  final j = await ref.read(apiClientProvider).getJson('/profiles/$username/albums');
  return asMapList(j['items']);
});

/// `/u/:username`: another member's full profile. Opening it records a view
/// (server-side, inside `GET /profiles/:username`).
class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key, required this.username});
  final String username;
  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  Relation? _rel;
  bool _busy = false;
  final _player = AudioPlayer();
  bool _playing = false;
  int _photo = 0;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      final done = s.processingState == ProcessingState.completed;
      setState(() => _playing = s.playing && !done);
      if (done) _player.stop();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  MemberActions get _actions => MemberActions(context, ref);

  Future<void> _like(PublicProfile p, String kind) async {
    final rel = _rel ?? p.relation;
    if (_busy) return;
    setState(() => _busy = true);
    if (rel.myLike != null && rel.myLike != 'pass' && kind == 'like') {
      if (await _actions.undoLike(p.card.userId)) setState(() => _rel = Relation(likedMe: rel.likedMe, favorite: rel.favorite, matched: false, conversationId: rel.conversationId));
    } else {
      final r = await _actions.like(p.card.userId, kind);
      if (r != null) {
        setState(() => _rel = rel.copyWith(myLike: kind, matched: r.matched, conversationId: r.conversationId));
        if (r.matched && mounted) {
          final myAvatar = ref.read(meProvider).valueOrNull?.avatarUrl;
          showGeneralDialog<void>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'match',
            pageBuilder: (ctx, _, _) => MatchOverlay(
              profile: DiscoverProfile.fromCard(p.card),
              myImageUrl: myAvatar,
              onMessage: () {
                Navigator.pop(ctx);
                _actions.openChat(p.card.userId, conversationId: r.conversationId);
              },
              onMessageLater: () => Navigator.pop(ctx),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _favorite(PublicProfile p) async {
    final rel = _rel ?? p.relation;
    if (await _actions.setFavorite(p.card.userId, !rel.favorite)) setState(() => _rel = rel.copyWith(favorite: !rel.favorite));
  }

  void _more(PublicProfile p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.waving_hand_outlined, color: AppColors.gold),
            title: const Text('Wink', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _actions.wink(p.card.userId, p.card.name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.gold),
            title: const Text('Add as friend', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _actions.friendRequest(p.card.userId, p.card.name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.error),
            title: const Text('Report', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(ctx);
              if (await _actions.report(p.card.userId, p.card.name) && mounted) Navigator.of(context).maybePop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: AppColors.error),
            title: const Text('Block', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(ctx);
              if (await _actions.block(p.card.userId, p.card.name) && mounted) Navigator.of(context).maybePop();
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleAudio(String url) async {
    if (_playing) return _player.pause();
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(memberProfileProvider(widget.username));
    return Scaffold(
      backgroundColor: AppColors.black,
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => SafeArea(
          child: Column(children: [
            const Align(alignment: Alignment.centerLeft, child: BackButton(color: Colors.white)),
            Expanded(
              child: e is ApiException && e.code == 'not_found'
                  ? const EmptyState(icon: Icons.person_off_outlined, title: 'This profile is not available')
                  : ErrorView(error: e, onRetry: () => ref.invalidate(memberProfileProvider(widget.username))),
            ),
          ]),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(PublicProfile p) {
    final rel = _rel ?? p.relation;
    final m = p.card;
    final locale = ref.watch(localeProvider);
    final options = ref.watch(profileOptionsProvider).valueOrNull;
    final me = ref.watch(meProvider).valueOrNull;
    final isMe = me?.userId == m.userId;
    final photos = p.photos.isNotEmpty ? p.photos.map((x) => x.url).toList() : [m.avatarUrl];
    final liked = rel.myLike != null && rel.myLike != 'pass';
    final attrs = <(String, String)>[
      if (p.heightCm != null) ('Height', '${p.heightCm} cm'),
      if (p.goal != null) ('Looking for', goalLabels[p.goal] ?? p.goal!),
      if (p.religion != null) ('Religion', p.religion!),
      if (m.tribe != null) ('Heritage', m.tribe!),
      if (p.zodiac != null) ('Zodiac', '${p.zodiac![0].toUpperCase()}${p.zodiac!.substring(1)}'),
      if (options != null)
        for (final f in ProfileOptions.fieldLabels.entries)
          if (p.attribute(f.key) != null) (f.value, options.labelFor(f.key, p.attribute(f.key), locale)!),
    ];
    final albums = ref.watch(memberAlbumsProvider(widget.username)).valueOrNull ?? const [];

    return Stack(children: [
      CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.sizeOf(context).height * .6,
          pinned: true,
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          actions: [if (!isMe) IconButton(onPressed: () => _more(p), icon: const Icon(Icons.more_horiz_rounded))],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _photo = i),
                itemBuilder: (_, i) => SafeImage(urlOrPath: photos[i]),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .2, .7, 1],
                      colors: [Color(0x99000000), Colors.transparent, Colors.transparent, AppColors.black],
                    ),
                  ),
                ),
              ),
              if (photos.length > 1)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 52,
                  left: 16,
                  right: 16,
                  child: Row(children: [
                    for (var i = 0; i < photos.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(color: i == _photo ? Colors.white : Colors.white30, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(m.age == null ? m.name : '${m.name}, ${m.age}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                ),
                if (m.verified) ...[const SizedBox(width: 8), const Icon(Icons.verified_rounded, color: AppColors.gold, size: 22)],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (m.online) ...[
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Online', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text([m.city, if (m.countryCode != null) countryName(m.countryCode, locale)].whereType<String>().join(', '),
                      style: const TextStyle(color: Colors.white60)),
                ),
              ]),
              if (rel.likedMe && !rel.matched) ...[
                const SizedBox(height: 12),
                const Pill('Likes you', icon: Icons.favorite_rounded, selected: true, color: AppColors.pink),
              ],
              if (rel.matched) ...[
                const SizedBox(height: 12),
                const Pill('It\'s a match', icon: Icons.favorite_rounded, selected: true),
              ],
              if (p.audioUrl != null) ...[
                const SizedBox(height: 18),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                      onPressed: () => _toggleAudio(p.audioUrl!),
                      icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    const SizedBox(width: 12),
                    Text('Hear ${m.name}\'s voice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              if ((m.bio ?? '').isNotEmpty) ...[
                const _H('About'),
                Text(m.bio!, style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15)),
              ],
              for (final pr in p.prompts) ...[
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pr.q, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(pr.a, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, height: 1.35)),
                  ]),
                ),
              ],
              if (m.interests.isNotEmpty) ...[
                const _H('Interests'),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final i in m.interests) Pill(interestLabel(i, locale))]),
              ],
              if (attrs.isNotEmpty) ...[
                const _H('Details'),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(children: [
                    for (final a in attrs)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(children: [
                          Text(a.$1, style: const TextStyle(color: Colors.white54)),
                          const Spacer(),
                          Flexible(child: Text(a.$2, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                  ]),
                ),
              ],
              if (p.languages.isNotEmpty) ...[
                const _H('Speaks'),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final l in p.languages) Pill(languageLabels[l] ?? l)]),
              ],
              if (albums.isNotEmpty) ...[
                const _H('Albums'),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: albums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _AlbumCard(album: albums[i]),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
      if (!isMe)
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                _RoundAction(icon: rel.favorite ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.gold, onTap: () => _favorite(p)),
                const SizedBox(width: 10),
                _RoundAction(icon: Icons.card_giftcard_rounded, color: AppColors.gold, onTap: () => GiftSheet.show(context, ref, toUserId: m.userId, toName: m.name)),
                const SizedBox(width: 10),
                _RoundAction(
                  icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: const Color(0xFFFFA21E),
                  busy: _busy,
                  onTap: () => _like(p, 'like'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: () => canAct(ref)
                        ? _actions.openChat(m.userId, conversationId: rel.conversationId)
                        : ensureVerified(context, ref),
                  ),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _H extends StatelessWidget {
  const _H(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 10),
        child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, required this.onTap, this.busy = false});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.darkSurface2,
        shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: .5))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: busy ? Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: color)) : Icon(icon, color: color),
          ),
        ),
      );
}

class _AlbumCard extends ConsumerWidget {
  const _AlbumCard({required this.album});
  final Json album;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = asInt(album['photo_count']) ?? 0;
    return GestureDetector(
      onTap: () => showAlbumViewer(context, ref, asString(album['id']) ?? '', asString(album['name']) ?? 'Album'),
      child: SizedBox(
        width: 110,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: album['cover_url'] == null
                ? Container(
                    decoration: BoxDecoration(color: AppColors.darkSurface2, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Icon(Icons.lock_outline_rounded, color: Colors.white38)),
                  )
                : SafeImage(urlOrPath: asString(album['cover_url']), borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 6),
          Text(asString(album['name']) ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('$count photo${count == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }
}

/// Album photos, visible only if the album's own visibility allows the viewer
/// (`album_photos` applies `can_view_album`); an empty answer means "not for you".
Future<void> showAlbumViewer(BuildContext context, WidgetRef ref, String albumId, String name) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(name)),
      body: FutureBuilder<Json>(
        future: ref.read(apiClientProvider).getJson('/albums/$albumId/photos'),
        builder: (_, snap) {
          if (snap.hasError) return ErrorView(error: snap.error!);
          if (!snap.hasData) return const LoadingView();
          final items = asMapList(snap.data!['items']);
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.lock_outline_rounded, title: 'This album is private', body: 'Its owner shares it only with some members.');
          }
          return PageView(children: [
            for (final p in items) InteractiveViewer(child: SafeImage(urlOrPath: asString(p['url']), fit: BoxFit.contain)),
          ]);
        },
      ),
    ),
  ));
}
