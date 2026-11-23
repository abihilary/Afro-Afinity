import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api/api_client.dart';
import '../core/state/providers.dart';
import '../core/state/session.dart';
import '../core/ui/verified_gate.dart';
import '../features/chat/chat_providers.dart';
import 'theme/colors.dart';

/// The tab bar, plus the two things that run for as long as the app is open:
/// the presence heartbeat and the unread-count subscription.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _beat;
  AppLifecycleListener? _life;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _startBeat();
    // Foreground only: a heartbeat from a backgrounded app would show every
    // member as permanently online.
    _life = AppLifecycleListener(
      onResume: () {
        _startBeat();
        ref.invalidate(conversationsProvider);
      },
      onPause: _stopBeat,
      onHide: _stopBeat,
    );
    _subscribe();
  }

  void _startBeat() {
    _beat?.cancel();
    _sendBeat();
    _beat = Timer.periodic(const Duration(seconds: 60), (_) => _sendBeat());
  }

  void _stopBeat() {
    _beat?.cancel();
    _beat = null;
  }

  void _sendBeat() {
    ref.read(apiClientProvider).post('/me/heartbeat').catchError((_) => null);
  }

  /// Conversations are in the realtime publication; RLS delivers only the
  /// member's own rows, so any change means the unread count moved.
  void _subscribe() {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    _channel = supabase
        .channel('my-conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => ref.invalidate(conversationsProvider),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _stopBeat();
    _life?.dispose();
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(conversationsProvider).valueOrNull?.unreadTotal ?? 0;
    final me = ref.watch(meProvider).valueOrNull;
    final showVerify = me != null && !me.canInteract;
    final pending = me?.verification?.status == 'pending';

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(children: [
        Expanded(child: widget.shell),
        if (showVerify)
          Material(
            color: AppColors.darkSurface2,
            child: InkWell(
              onTap: () => pending ? showVerifySheet(context, me) : context.push('/verification'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Icon(pending ? Icons.hourglass_top_rounded : Icons.verified_user_outlined, color: AppColors.gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pending
                          ? 'Verification under review — you can browse meanwhile'
                          : me.verification?.status == 'rejected'
                              ? 'Verification was not approved — tap to resubmit'
                              : 'Verify your identity to like and message',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!pending) const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                ]),
              ),
            ),
          ),
      ]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.gold.withValues(alpha: .16),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: s.contains(WidgetState.selected) ? AppColors.gold : Colors.white54,
              )),
          iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.gold : Colors.white60)),
        ),
        child: NavigationBar(
          height: 66,
          selectedIndex: widget.shell.currentIndex,
          onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style_rounded), label: 'Discover'),
            const NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Connections'),
            NavigationDestination(
              icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_outline_rounded)),
              selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_rounded)),
              label: 'Messages',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
