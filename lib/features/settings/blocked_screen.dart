import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/widgets/common.dart';
import '../../models/member.dart';

final _blockedProvider = FutureProvider.autoDispose<List<MemberCard>>((ref) async {
  final me = await ref.watch(meProvider.future);
  if (me == null || !me.canInteract) return const [];
  return asMapList((await ref.read(apiClientProvider).getJson('/blocks'))['items']).map(MemberCard.new).toList();
});

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Blocked members')),
      body: ref.watch(_blockedProvider).when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_blockedProvider)),
            data: (list) => list.isEmpty
                ? const EmptyState(icon: Icons.block_rounded, title: 'No one is blocked')
                : ListView(children: [
                    for (final m in list)
                      ListTile(
                        leading: Avatar(url: m.avatarUrl, size: 46),
                        title: Text(m.name, style: const TextStyle(color: Colors.white)),
                        trailing: TextButton(
                          onPressed: () async {
                            try {
                              await ref.read(apiClientProvider).delete('/blocks/${m.userId}');
                              ref.invalidate(_blockedProvider);
                            } catch (e) {
                              if (context.mounted) handleApiError(context, e);
                            }
                          },
                          child: const Text('Unblock', style: TextStyle(color: AppColors.gold)),
                        ),
                      ),
                  ]),
          ),
    );
  }
}
