import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/util/time.dart';
import '../../core/widgets/common.dart';
import '../../models/member.dart';
import '../discover/member_actions.dart';
import '../discover/member_tile.dart';

/// One page of a connections list.
class _Page {
  const _Page(this.rows, {this.plus = true, this.total});
  final List<ConnectionRow> rows;
  final bool plus;
  final int? total;
}

/// Every list is `requireVerified`; an unverified member sees the gate, not
/// a 403.
final _listProvider = FutureProvider.autoDispose.family<_Page, String>((ref, key) async {
  ref.watch(userIdProvider);
  final me = await ref.watch(meProvider.future);
  if (me == null || !me.canInteract) return const _Page([]);
  final api = ref.read(apiClientProvider);
  final (path, query) = switch (key) {
    'likes' => ('/likes/received', <String, dynamic>{}),
    'matches' => ('/matches', <String, dynamic>{}),
    'friends' => ('/friends', <String, dynamic>{}),
    'requests_in' => ('/friends/requests', {'direction': 'in'}),
    'requests_out' => ('/friends/requests', {'direction': 'out'}),
    'winks' => ('/winks/received', <String, dynamic>{}),
    'favorites' => ('/favorites', <String, dynamic>{}),
    'views_in' => ('/views/received', <String, dynamic>{}),
    'views_out' => ('/views/sent', <String, dynamic>{}),
    'gifts_in' => ('/gifts', {'direction': 'in'}),
    'gifts_out' => ('/gifts', {'direction': 'out'}),
    _ => ('/matches', <String, dynamic>{}),
  };
  final j = await api.getJson(path, query: query);
  return _Page(
    asMapList(j['items']).map(ConnectionRow.new).toList(),
    plus: j['plus'] is bool ? j['plus'] as bool : true,
    total: asInt(j['total']),
  );
});

const _tabs = [
  ('likes', 'Likes'),
  ('matches', 'Matches'),
  ('friends', 'Friends'),
  ('winks', 'Winks'),
  ('favorites', 'Favourites'),
  ('views', 'Views'),
  ('gifts', 'Gifts'),
];

/// Likes, matches, friends, winks, favourites, views and gifts — the web's
/// /app/connections hub, one tab each.
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key, this.initialTab});
  final String? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final start = _tabs.indexWhere((t) => t.$1 == initialTab);
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: start < 0 ? 0 : start,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          title: const Text('Connections', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
            tabs: [for (final t in _tabs) Tab(text: t.$2)],
          ),
        ),
        body: me != null && !me.canInteract
            ? EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Connections open once you are verified',
                body: me.verification?.status == 'pending'
                    ? 'Your verification is under review. Likes, matches and messages appear here after approval.'
                    : 'Verify your identity to see who likes you and start matching.',
                action: me.verification?.status == 'pending' ? null : 'Verify now',
                onAction: () => context.push('/verification'),
              )
            : const TabBarView(children: [
                _LikesTab(),
                _MatchesTab(),
                _FriendsTab(),
                _WinksTab(),
                _FavoritesTab(),
                _TwoWayTab(inKey: 'views_in', outKey: 'views_out', inLabel: 'Viewed me', outLabel: 'I viewed'),
                _TwoWayTab(inKey: 'gifts_in', outKey: 'gifts_out', inLabel: 'Received', outLabel: 'Sent'),
              ]),
      ),
    );
  }
}

/// Loading / error / empty / data for one list key.
class _ListShell extends ConsumerWidget {
  const _ListShell({super.key, required this.listKey, required this.empty, required this.builder});
  final String listKey;
  final EmptyState empty;
  final Widget Function(BuildContext, WidgetRef, _Page) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_listProvider(listKey)).when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_listProvider(listKey))),
          data: (page) => RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () => ref.refresh(_listProvider(listKey).future),
            child: page.rows.isEmpty ? ListView(children: [const SizedBox(height: 60), empty]) : builder(context, ref, page),
          ),
        );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.gold.withValues(alpha: .22), AppColors.terracotta.withValues(alpha: .18)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
        ),
        child: Row(children: [
          const Icon(Icons.visibility_rounded, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35))),
          TextButton(onPressed: () => context.push('/premium'), child: const Text('Upgrade', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800))),
        ]),
      );
}

Widget _grid(List<ConnectionRow> rows, {String? Function(ConnectionRow)? badge, Widget? Function(ConnectionRow)? footer, Widget? header}) {
  return CustomScrollView(slivers: [
    if (header != null) SliverToBoxAdapter(child: header),
    SliverPadding(
      padding: const EdgeInsets.all(14),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .74),
        itemCount: rows.length,
        itemBuilder: (_, i) => MemberGridTile(member: rows[i].member, badge: badge?.call(rows[i]), footer: footer?.call(rows[i])),
      ),
    ),
  ]);
}

class _LikesTab extends StatelessWidget {
  const _LikesTab();
  @override
  Widget build(BuildContext context) => _ListShell(
        listKey: 'likes',
        empty: const EmptyState(icon: Icons.favorite_border_rounded, title: 'No likes yet', body: 'Complete your profile and add more photos to stand out.'),
        builder: (context, ref, page) => _grid(
          page.rows,
          badge: (r) => r.kind == 'superlike' ? 'Super like' : (r.member.matched ? 'Match' : null),
          header: page.plus ? null : _UpgradeBanner(text: '${page.rows.length} ${page.rows.length == 1 ? 'person likes' : 'people like'} you. See who with Gold.'),
        ),
      );
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();
  @override
  Widget build(BuildContext context) => _ListShell(
        listKey: 'matches',
        empty: const EmptyState(icon: Icons.favorite_rounded, title: 'No matches yet', body: 'When you and someone like each other, they appear here.'),
        builder: (context, ref, page) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: page.rows.length,
          separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 84),
          itemBuilder: (_, i) {
            final r = page.rows[i];
            return _PersonRow(
              row: r,
              subtitle: 'Matched ${shortAgo(r.at)}',
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold),
                onPressed: () => MemberActions(context, ref).openChat(r.member.userId, conversationId: r.conversationId, name: r.member.name),
              ),
            );
          },
        ),
      );
}

class _FriendsTab extends ConsumerStatefulWidget {
  const _FriendsTab();
  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  String _view = 'friends';

  Future<void> _respond(ConnectionRow r, bool accept) async {
    try {
      await ref.read(apiClientProvider).post('/friends/requests/${r.member.userId}/respond', data: {'accept': accept});
      ref.invalidate(_listProvider('requests_in'));
      ref.invalidate(_listProvider('friends'));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _remove(ConnectionRow r) async {
    try {
      await ref.read(apiClientProvider).delete('/friends/${r.member.userId}');
      ref.invalidate(_listProvider(_view));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Wrap(spacing: 8, children: [
          Pill('Friends', selected: _view == 'friends', onTap: () => setState(() => _view = 'friends')),
          Pill('Requests', selected: _view == 'requests_in', onTap: () => setState(() => _view = 'requests_in')),
          Pill('Sent', selected: _view == 'requests_out', onTap: () => setState(() => _view = 'requests_out')),
        ]),
      ),
      Expanded(
        child: _ListShell(
          key: ValueKey(_view),
          listKey: _view,
          empty: EmptyState(
            icon: Icons.people_outline_rounded,
            title: switch (_view) { 'requests_in' => 'No friend requests', 'requests_out' => 'No pending requests', _ => 'No friends yet' },
            body: _view == 'friends' ? 'Add friends from their profile — friendship is for people you want to stay close to.' : null,
          ),
          builder: (context, ref, page) => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: page.rows.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 84),
            itemBuilder: (_, i) {
              final r = page.rows[i];
              return _PersonRow(
                row: r,
                subtitle: r.message ?? (_view == 'friends' ? 'Friends since ${longDate(r.at)}' : shortAgo(r.at)),
                trailing: switch (_view) {
                  'requests_in' => Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(onPressed: () => _respond(r, false), icon: const Icon(Icons.close_rounded, color: Colors.white54)),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                        onPressed: () => _respond(r, true),
                        icon: const Icon(Icons.check_rounded),
                      ),
                    ]),
                  'requests_out' => TextButton(onPressed: () => _remove(r), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                  _ => PopupMenuButton<String>(
                      iconColor: Colors.white54,
                      color: AppColors.darkSurface2,
                      onSelected: (v) => v == 'message' ? MemberActions(context, ref).openChat(r.member.userId, name: r.member.name) : _remove(r),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'message', child: Text('Message', style: TextStyle(color: Colors.white))),
                        PopupMenuItem(value: 'remove', child: Text('Unfriend', style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                },
              );
            },
          ),
        ),
      ),
    ]);
  }
}

class _WinksTab extends StatelessWidget {
  const _WinksTab();
  @override
  Widget build(BuildContext context) => _ListShell(
        listKey: 'winks',
        empty: const EmptyState(icon: Icons.waving_hand_outlined, title: 'No winks yet', body: 'A wink is a light way of saying hello.'),
        builder: (context, ref, page) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: page.rows.length,
          separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 84),
          itemBuilder: (_, i) {
            final r = page.rows[i];
            final n = r.winkCount ?? 1;
            return _PersonRow(
              row: r,
              subtitle: '${n > 1 ? 'Winked $n times' : 'Winked'} · ${shortAgo(r.at)}',
              trailing: r.winkedBack
                  ? const Text('Winked back', style: TextStyle(color: Colors.white38, fontSize: 12))
                  : TextButton(
                      onPressed: () async {
                        if (await MemberActions(context, ref).wink(r.member.userId, r.member.name)) ref.invalidate(_listProvider('winks'));
                      },
                      child: const Text('Wink back 😉', style: TextStyle(color: AppColors.gold)),
                    ),
            );
          },
        ),
      );
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();
  @override
  Widget build(BuildContext context) => _ListShell(
        listKey: 'favorites',
        empty: const EmptyState(icon: Icons.star_border_rounded, title: 'No favourites', body: 'Tap the star on a profile to keep it here.'),
        builder: (context, ref, page) => _grid(page.rows),
      );
}

class _TwoWayTab extends StatefulWidget {
  const _TwoWayTab({required this.inKey, required this.outKey, required this.inLabel, required this.outLabel});
  final String inKey;
  final String outKey;
  final String inLabel;
  final String outLabel;
  @override
  State<_TwoWayTab> createState() => _TwoWayTabState();
}

class _TwoWayTabState extends State<_TwoWayTab> {
  bool _in = true;
  @override
  Widget build(BuildContext context) {
    final key = _in ? widget.inKey : widget.outKey;
    final gifts = key.startsWith('gifts');
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Row(children: [
          Pill(widget.inLabel, selected: _in, onTap: () => setState(() => _in = true)),
          const SizedBox(width: 8),
          Pill(widget.outLabel, selected: !_in, onTap: () => setState(() => _in = false)),
        ]),
      ),
      Expanded(
        child: _ListShell(
          key: ValueKey(key),
          listKey: key,
          empty: EmptyState(
            icon: gifts ? Icons.card_giftcard_rounded : Icons.visibility_outlined,
            title: gifts ? (_in ? 'No gifts received yet' : 'You have not sent a gift yet') : (_in ? 'No one has viewed you yet' : 'You have not viewed anyone yet'),
          ),
          builder: (context, ref, page) {
            if (gifts) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: page.rows.length,
                separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 84),
                itemBuilder: (_, i) {
                  final r = page.rows[i];
                  return _PersonRow(
                    row: r,
                    subtitle: '${r.giftEmoji ?? '🎁'} ${r.giftLabel ?? 'Gift'} · ${shortAgo(r.at)}',
                    trailing: r.coins == null ? null : CoinAmount(r.coins!, size: 12),
                  );
                },
              );
            }
            return _grid(
              page.rows,
              header: page.plus ? null : _UpgradeBanner(text: '${page.total ?? page.rows.length} profile views. See who with Gold.'),
              footer: (r) => r.viewCount != null && r.viewCount! > 1
                  ? Text('${r.viewCount} visits', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700))
                  : null,
            );
          },
        ),
      ),
    ]);
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.row, required this.subtitle, this.trailing});
  final ConnectionRow row;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final m = row.member;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: m.username == null ? null : () => context.push('/u/${m.username}'),
      leading: Avatar(url: m.avatarUrl, size: 54, online: m.online),
      title: Row(children: [
        Flexible(
          child: Text(m.age == null ? m.name : '${m.name}, ${m.age}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        if (m.verified) ...[const SizedBox(width: 4), const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14)],
      ]),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
      trailing: trailing,
    );
  }
}

