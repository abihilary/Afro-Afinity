import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/state/providers.dart';
import '../../core/util/time.dart';
import '../../core/widgets/common.dart';
import 'chat_providers.dart';

/// The thread list: `GET /conversations`, refreshed by the shell's realtime
/// subscription on `conversations`.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final list = ref.watch(conversationsProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: me != null && !me.canInteract
          ? EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Messages open once you are verified',
              body: me.verification?.status == 'pending' ? 'Your verification is under review.' : 'Verify your identity to start talking.',
              action: me.verification?.status == 'pending' ? null : 'Verify now',
              onAction: () => context.push('/verification'),
            )
          : list.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(conversationsProvider)),
              data: (l) => RefreshIndicator(
                color: AppColors.gold,
                onRefresh: () => ref.refresh(conversationsProvider.future),
                child: l.items.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No conversations yet',
                          body: 'Match with someone, or open a profile and say hello.',
                          action: 'Find people',
                          onAction: () => context.go('/discover'),
                        ),
                      ])
                    : ListView.separated(
                        itemCount: l.items.length,
                        separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 84),
                        itemBuilder: (_, i) {
                          final c = l.items[i];
                          final unread = c.unread > 0;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            onTap: () => context.push('/messages/${c.id}'),
                            leading: Avatar(url: c.otherGone ? null : c.other.avatarUrl, size: 56, online: c.other.online),
                            title: Row(children: [
                              Flexible(
                                child: Text(c.otherGone ? 'Former member' : c.other.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white, fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
                              ),
                              if (c.other.verified) ...[const SizedBox(width: 4), const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14)],
                            ]),
                            subtitle: Text(
                              c.lastPreview ?? (c.openedVia == 'match' ? 'You matched — say hello' : 'Say hello'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: unread ? Colors.white : Colors.white54, fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
                            ),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(shortAgo(c.lastMessageAt), style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
                              const SizedBox(height: 6),
                              if (unread)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                                  child: Text('${c.unread}', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                            ]),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
