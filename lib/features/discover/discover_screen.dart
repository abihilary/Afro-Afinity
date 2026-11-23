import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pressable.dart';
import '../../models/member.dart';
import '../../models/profile.dart';
import '../gifts/gift_picker.dart';
import '../matches/match_overlay.dart';
import 'filters.dart';
import 'member_actions.dart';
import 'member_tile.dart';
import 'swipe_card.dart';
import 'swipe_controller.dart';

/// The deck (Meet Me) and the grid, both on `GET /discover`. Filters are sent
/// to the server; nothing is filtered or invented on the device.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _Swiped {
  const _Swiped(this.index, this.kind);
  final int index;
  final String kind;
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _swipe = SwipeController();
  final _grid = ScrollController();
  SearchFilters _filters = const SearchFilters();
  bool _deck = true;
  final List<MemberCard> _items = [];
  int? _nextOffset = 0;
  bool _loading = false;
  Object? _error;
  int _index = 0;
  _Swiped? _last;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _swipe.addListener(() => setState(() {}));
    _grid.addListener(() {
      if (_grid.position.pixels > _grid.position.maxScrollExtent - 600) _load();
    });
    _reload();
  }

  @override
  void dispose() {
    _swipe.dispose();
    _grid.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _nextOffset = 0;
      _index = 0;
      _last = null;
      _error = null;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading || _nextOffset == null) return;
    setState(() => _loading = true);
    try {
      final j = await ref.read(apiClientProvider).getJson('/discover', query: {
        ..._filters.toDiscoverQuery(),
        'deck': _deck ? 'true' : null,
        'limit': 24,
        'offset': _nextOffset,
      });
      final fresh = asMapList(j['items']).map(MemberCard.new).toList();
      final seen = _items.map((m) => m.userId).toSet();
      setState(() {
        _items.addAll(fresh.where((m) => !seen.contains(m.userId)));
        _nextOffset = asInt(j['next_offset']);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeLoadMore() {
    if (_items.length - _index < 6) _load();
  }

  MemberCard? get _current => _index < _items.length ? _items[_index] : null;

  Future<void> _act(String kind, {bool fromDrag = false}) async {
    final m = _current;
    if (m == null || _busy) return;
    if (!canAct(ref)) {
      _swipe.reset();
      ensureVerified(context, ref);
      return;
    }
    final actions = MemberActions(context, ref);
    if (kind == 'superlike') {
      // Super likes spend coins: wait for the server before the card leaves,
      // so an empty wallet never plays a success animation.
      setState(() => _busy = true);
      final r = await actions.like(m.userId, 'superlike');
      if (mounted) setState(() => _busy = false);
      if (r == null) return _swipe.reset();
      await _swipe.superLike();
      _advance(m, kind, r);
      return;
    }
    if (!fromDrag) await _swipe.swipe(kind == 'pass' ? SwipeDirection.left : SwipeDirection.right);
    final index = _index;
    setState(() {
      _index++;
      _last = _Swiped(index, kind);
    });
    _maybeLoadMore();
    final r = await actions.like(m.userId, kind);
    if (!mounted) return;
    if (r == null) {
      // The like did not land (limit, rate, network): put the card back.
      setState(() {
        _index = index;
        _last = null;
      });
      return;
    }
    if (r.matched) _showMatch(m, r);
  }

  void _advance(MemberCard m, String kind, LikeResult r) {
    setState(() {
      _last = _Swiped(_index, kind);
      _index++;
    });
    _maybeLoadMore();
    if (r.matched) _showMatch(m, r);
  }

  Future<void> _undo() async {
    final last = _last;
    if (last == null) return;
    final m = _items[last.index];
    final ok = await MemberActions(context, ref).undoLike(m.userId);
    if (ok && mounted) {
      setState(() {
        _index = last.index;
        _last = null;
      });
    }
  }

  void _showMatch(MemberCard m, LikeResult r) {
    final myAvatar = ref.read(meProvider).valueOrNull?.avatarUrl;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'match',
      pageBuilder: (ctx, _, _) => MatchOverlay(
        profile: DiscoverProfile.fromCard(m),
        myImageUrl: myAvatar,
        onMessage: () {
          Navigator.pop(ctx);
          MemberActions(context, ref).openChat(m.userId, conversationId: r.conversationId, name: m.name);
        },
        onMessageLater: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _openFilters() async {
    final f = await showFiltersSheet(context, _filters);
    if (f != null) {
      setState(() => _filters = f);
      _reload();
    }
  }

  Future<void> _gift() async {
    final m = _current;
    if (m == null) return;
    await GiftSheet.show(context, ref, toUserId: m.userId, toName: m.name);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
            child: Row(children: [
              Image.asset('assets/images/mark.png', width: 30, height: 30),
              const SizedBox(width: 10),
              const Text('Discover', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/wallet'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
                  child: CoinAmount(me?.balance ?? 0, size: 13),
                ),
              ),
              IconButton(tooltip: 'Search', onPressed: () => context.push('/search'), icon: const Icon(Icons.search_rounded, color: Colors.white)),
              IconButton(
                tooltip: 'Filters',
                onPressed: _openFilters,
                icon: Badge(
                  isLabelVisible: _filters.activeCount > 0,
                  label: Text('${_filters.activeCount}'),
                  backgroundColor: AppColors.gold,
                  textColor: Colors.black,
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.white70,
                selectedForegroundColor: Colors.black,
                selectedBackgroundColor: AppColors.gold,
                side: BorderSide(color: Colors.white.withValues(alpha: .12)),
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Meet'), icon: Icon(Icons.style_rounded, size: 18)),
                ButtonSegment(value: false, label: Text('Browse'), icon: Icon(Icons.grid_view_rounded, size: 18)),
              ],
              selected: {_deck},
              onSelectionChanged: (s) {
                setState(() => _deck = s.first);
                _reload();
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _deck ? _deckView() : _gridView()),
        ]),
      ),
    );
  }

  Widget _emptyOrError() {
    if (_error != null && _items.isEmpty) return ErrorView(error: _error!, onRetry: _reload);
    if (_loading && _items.length <= _index) return const LoadingView();
    return EmptyState(
      icon: Icons.auto_awesome_rounded,
      title: _filters.activeCount > 0 ? 'No one matches these filters' : 'You have seen everyone for now',
      body: _filters.activeCount > 0 ? 'Try widening the age range or distance.' : 'New members join every day. Check back soon, or browse the grid.',
      action: _filters.activeCount > 0 ? 'Change filters' : 'Refresh',
      onAction: _filters.activeCount > 0 ? _openFilters : _reload,
    );
  }

  Widget _deckView() {
    final m = _current;
    if (m == null) return _emptyOrError();
    final locale = ref.watch(localeProvider);
    final profile = DiscoverProfile.fromCard(m, locale: locale);
    final next = _index + 1 < _items.length ? DiscoverProfile.fromCard(_items[_index + 1], locale: locale) : null;
    void open(DiscoverProfile p) => p.card.username == null ? null : context.push('/u/${p.card.username}');
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth - 32;
      final height = c.maxHeight - 96;
      return Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _busy ? null : (d) => _swipe.update(d.delta),
              onPanEnd: _busy
                  ? null
                  : (_) async {
                      if (!canAct(ref) && _swipe.progress >= 1) {
                        _swipe.reset();
                        ensureVerified(context, ref);
                        return;
                      }
                      final dir = await _swipe.endDrag();
                      if (dir == SwipeDirection.right) _act('like', fromDrag: true);
                      if (dir == SwipeDirection.left) _act('pass', fromDrag: true);
                    },
              child: Stack(clipBehavior: Clip.none, children: [
                if (next != null)
                  Positioned(
                    top: 18,
                    left: 12,
                    child: SizedBox(
                      width: width - 24,
                      height: height,
                      child: Opacity(
                        opacity: .8,
                        child: SwipeCard(profile: next, rotation: 0, position: Offset.zero, likeProgress: 0, nopeProgress: 0, compact: true),
                      ),
                    ),
                  ),
                SizedBox(
                  width: width,
                  height: height,
                  child: SwipeCard(
                    key: ValueKey(profile.id),
                    profile: profile,
                    rotation: _swipe.rotation,
                    position: _swipe.position,
                    likeProgress: _swipe.showingLike ? _swipe.progress : 0,
                    nopeProgress: _swipe.showingNope ? _swipe.progress : 0,
                    onOpenProfile: () => open(profile),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _ActionButton(icon: Icons.replay_rounded, size: 40, color: const Color(0xFF8B8E98), onTap: _last == null ? null : _undo),
            _ActionButton(icon: Icons.close_rounded, size: 50, color: const Color(0xFFFF6A78), onTap: () => _act('pass')),
            _ActionButton(icon: Icons.star_rounded, size: 46, color: const Color(0xFF5AD9FF), onTap: () => _act('superlike'), busy: _busy),
            _ActionButton(icon: Icons.card_giftcard_rounded, size: 40, color: AppColors.gold, onTap: _gift),
            _ActionButton(icon: Icons.favorite_rounded, size: 54, color: const Color(0xFFFFA21E), onTap: () => _act('like')),
          ]),
        ),
      ]);
    });
  }

  Widget _gridView() {
    if (_items.isEmpty) return _emptyOrError();
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _reload,
      child: GridView.builder(
        controller: _grid,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .72,
        ),
        itemCount: _items.length + (_nextOffset != null ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) return const LoadingView();
          final m = _items[i];
          return MemberGridTile(member: m, badge: m.boosted ? 'Boosted' : (m.likedMe ? 'Likes you' : null));
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.size, required this.color, required this.onTap, this.busy = false});
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? Colors.white24 : color;
    return PressableScale(
      onTap: onTap ?? () {},
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: .16),
          border: Border.all(color: c.withValues(alpha: .8)),
          boxShadow: [BoxShadow(color: c.withValues(alpha: .16), blurRadius: 16)],
        ),
        child: busy
            ? Padding(padding: EdgeInsets.all(size * .3), child: CircularProgressIndicator(strokeWidth: 2, color: c))
            : Icon(icon, color: c, size: size * .45),
      ),
    );
  }
}
