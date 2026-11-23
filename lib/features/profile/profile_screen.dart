import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../../models/me.dart';

/// The member's own home: picture, completeness, numbers, boost, and the way
/// into everything they own (profile, albums, wallet, plan, settings).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _boosting = false;

  Future<void> _boost(Me me) async {
    if (!ensureVerified(context, ref)) return;
    final store = ref.read(storeProvider).valueOrNull;
    final cost = store?.boostCoins ?? 50;
    final hours = store?.boostHours ?? 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: const Text('Boost your profile', style: TextStyle(color: Colors.white)),
        content: Text('Appear at the top of Discover for $hours hour${hours == 1 ? '' : 's'} for $cost coins.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Boost · $cost coins')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _boosting = true);
    try {
      ref.read(meProvider.notifier).replace(await ref.read(apiClientProvider).post('/me/boost'));
      if (mounted) showToast(context, 'You are boosted 🚀');
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _boosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(meProvider);
    final me = async.valueOrNull;
    if (me == null) return Scaffold(backgroundColor: AppColors.black, body: async.hasError ? ErrorView(error: async.error!, onRetry: () => ref.invalidate(meProvider)) : const LoadingView());
    final store = ref.watch(storeProvider).valueOrNull;
    final tier = store?.tiers.where((t) => t.code == me.subscription?.planCode).firstOrNull;
    final planLabel = me.plus && me.subscription != null ? (tier?.label(me.locale) ?? me.subscription!.planCode) : 'Free';
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined))],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.read(meProvider.notifier).refresh(),
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 6, 18, 30), children: [
          Row(children: [
            Stack(children: [
              Avatar(url: me.avatarUrl, size: 92),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: const CircleAvatar(radius: 15, backgroundColor: AppColors.gold, child: Icon(Icons.edit_rounded, size: 16, color: Colors.black)),
                ),
              ),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(me.age == null ? (me.displayName ?? '') : '${me.displayName ?? ''}, ${me.age}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  if (me.verifiedAt != null) ...[const SizedBox(width: 6), const Icon(Icons.verified_rounded, color: AppColors.gold, size: 20)],
                ]),
                if (me.username != null) Text('@${me.username}', style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Pill(planLabel, icon: Icons.workspace_premium_rounded, selected: me.plus, onTap: () => context.push('/premium')),
                  if (me.boosted) const Pill('Boosted', icon: Icons.rocket_launch_rounded, selected: true, color: AppColors.pink),
                  if (me.incognito) const Pill('Incognito', icon: Icons.visibility_off_rounded, selected: true, color: AppColors.purple),
                ]),
              ]),
            ),
          ]),
          if (me.verifiedAt == null) ...[
            const SizedBox(height: 16),
            SectionCard(
              child: Row(children: [
                Icon(me.verification?.status == 'pending' ? Icons.hourglass_top_rounded : Icons.verified_user_outlined, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    switch (me.verification?.status) {
                      'pending' => 'Your verification is under review.',
                      'rejected' => 'Verification was not approved. ${me.verification?.note ?? ''}',
                      _ => 'Verify your identity to like, message and send gifts.',
                    },
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
                if (me.verification?.status != 'pending')
                  TextButton(onPressed: () => context.push('/verification'), child: const Text('Verify', style: TextStyle(color: AppColors.gold))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Profile strength', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${me.completion}%', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: me.completion / 100, minHeight: 7, backgroundColor: Colors.white10, color: AppColors.gold),
              ),
              if (me.completion < 100) ...[
                const SizedBox(height: 10),
                Text(_nextTip(me), style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat(label: 'Matches', value: '${me.matchCount}', onTap: () => context.go('/connections?tab=matches'))),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: 'Likes', value: '${me.likesReceived}', onTap: () => context.go('/connections?tab=likes'))),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: 'Coins', value: '${me.balance}', onTap: () => context.push('/wallet'))),
          ]),
          const SizedBox(height: 12),
          PrimaryButton(
            label: me.boosted ? 'Boosted until ${TimeOfDay.fromDateTime(me.boostedUntil!).format(context)}' : 'Boost · ${store?.boostCoins ?? 50} coins',
            icon: Icons.rocket_launch_rounded,
            loading: _boosting,
            onPressed: me.boosted ? null : () => _boost(me),
          ),
          const SizedBox(height: 16),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: [
              ActionRow(icon: Icons.edit_outlined, label: 'Edit profile', onTap: () => context.push('/profile/edit')),
              if (me.username != null && me.canInteract)
                ActionRow(icon: Icons.visibility_outlined, label: 'See my profile as others do', onTap: () => context.push('/u/${me.username}')),
              ActionRow(icon: Icons.photo_library_outlined, label: 'Private albums', onTap: () => context.push('/profile/albums')),
              ActionRow(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', subtitle: '${me.balance} coins · ${me.earned} earned', onTap: () => context.push('/wallet')),
              ActionRow(icon: Icons.workspace_premium_outlined, label: 'Plans', subtitle: planLabel, onTap: () => context.push('/premium')),
              ActionRow(icon: Icons.search_rounded, label: 'Search & directory', onTap: () => context.push('/search')),
              ActionRow(icon: Icons.lock_outline_rounded, label: 'Privacy', onTap: () => context.push('/settings/privacy')),
              ActionRow(icon: Icons.help_outline_rounded, label: 'Help & safety', onTap: () => context.push('/settings/help')),
            ]),
          ),
        ]),
      ),
    );
  }

  String _nextTip(Me me) {
    if (me.photos.length < 3) return 'Add ${3 - me.photos.length} more photo${me.photos.length == 2 ? '' : 's'}.';
    if ((me.bio ?? '').length < 20) return 'Write a few lines about yourself.';
    if (me.interests.length < 3) return 'Pick at least three interests.';
    if (me.prompts.isEmpty) return 'Answer a prompt.';
    if (me.audioPath == null) return 'Record a voice prompt.';
    if (me.verifiedAt == null) return 'Get verified.';
    return 'Fill in the remaining details.';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
}
