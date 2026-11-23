import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/links.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  /// `PATCH /me/settings`. Turning incognito ON is a paid perk (402
  /// plus_required → the upgrade path); turning it off always works.
  Future<void> _settings(Map<String, dynamic> body) async {
    setState(() => _busy = true);
    try {
      ref.read(meProvider.notifier).replace(await ref.read(apiClientProvider).patch('/me/settings', data: body));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: AppColors.darkSurface2,
          title: const Text('Delete your account?', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Your profile disappears at once and you are signed out everywhere. Your coins, matches and messages are lost. This cannot be undone.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text('Type DELETE to confirm', style: TextStyle(color: Colors.white54, fontSize: 12)),
            TextField(controller: confirm, onChanged: (_) => set(() {}), style: const TextStyle(color: Colors.white)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: confirm.text.trim() == 'DELETE' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete account', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).delete('/me');
      await signOut();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Settings')),
      body: me == null
          ? const LoadingView()
          : AbsorbPointer(
              absorbing: _busy,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                const _Group('Account'),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    ActionRow(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      subtitle: 'Emails and option labels',
                      trailing: DropdownButton<String>(
                        value: me.locale,
                        dropdownColor: AppColors.darkSurface2,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'fr', child: Text('Français')),
                        ],
                        onChanged: (v) => v == null || v == me.locale ? null : _settings({'locale': v}),
                      ),
                    ),
                    ActionRow(
                      icon: Icons.visibility_off_outlined,
                      label: 'Incognito',
                      subtitle: me.perks.incognito ? 'Browse without appearing in Discover' : 'Gold and Platinum feature',
                      trailing: Switch(
                        value: me.incognito,
                        activeThumbColor: AppColors.gold,
                        onChanged: (v) => _settings({'incognito': v}),
                      ),
                    ),
                    ActionRow(icon: Icons.lock_outline_rounded, label: 'Privacy', subtitle: 'Who sees your photos, voice and status', onTap: () => context.push('/settings/privacy')),
                    ActionRow(icon: Icons.block_rounded, label: 'Blocked members', onTap: () => context.push('/settings/blocked')),
                    ActionRow(icon: Icons.verified_user_outlined, label: 'Verification', subtitle: me.verifiedAt != null ? 'Verified' : (me.verification?.status ?? 'Not verified'), onTap: () => context.push('/verification')),
                  ]),
                ),
                const _Group('Money'),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    ActionRow(icon: Icons.account_balance_wallet_outlined, label: 'Wallet & history', onTap: () => context.push('/wallet')),
                    ActionRow(icon: Icons.workspace_premium_outlined, label: 'Plan & subscription', onTap: () => context.push('/premium')),
                  ]),
                ),
                const _Group('Help'),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    ActionRow(icon: Icons.help_outline_rounded, label: 'Help & contact', onTap: () => context.push('/settings/help')),
                    ActionRow(icon: Icons.shield_outlined, label: 'Safety tips', onTap: () => openWeb('/safety')),
                    ActionRow(icon: Icons.description_outlined, label: 'Terms of service', onTap: () => openWeb('/terms')),
                    ActionRow(icon: Icons.privacy_tip_outlined, label: 'Privacy policy', onTap: () => openWeb('/privacy')),
                    ActionRow(icon: Icons.gavel_outlined, label: 'Community guidelines', onTap: () => openWeb('/guidelines')),
                  ]),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    ActionRow(icon: Icons.logout_rounded, label: 'Sign out', onTap: signOut),
                    ActionRow(icon: Icons.delete_forever_outlined, label: 'Delete account', danger: true, onTap: _delete),
                  ]),
                ),
                const SizedBox(height: 20),
                Center(child: Text('Signed in as ${supabase.auth.currentUser?.email ?? ''}', style: const TextStyle(color: Colors.white30, fontSize: 12))),
              ]),
            ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
        child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      );
}
