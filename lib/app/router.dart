import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state/providers.dart';
import '../core/state/session.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/suspended_screen.dart';
import '../features/auth/verification/verification_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/conversations_screen.dart';
import '../features/chat/new_chat_screen.dart';
import '../features/connections/connections_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/discover/member_profile_screen.dart';
import '../features/discover/search_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/profile/albums_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/blocked_screen.dart';
import '../features/settings/help_support.dart';
import '../features/settings/privacy_settings.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../models/me.dart';
import 'shell.dart';

const _public = {'/login', '/signup', '/forgot'};

/// Re-runs the redirect whenever the session or `/me` changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
    ref.listen(meProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    if (supabase.auth.currentSession == null) {
      return _public.contains(loc) ? null : '/login';
    }
    final me = ref.read(meProvider);
    // Until /me answers there is no way to know where a member belongs, and
    // routing on a half-restored session sends a signed-in member to login.
    if (!me.hasValue || me.value == null) return loc == '/splash' ? null : '/splash';
    final status = me.value!.status;
    switch (status) {
      case MemberStatus.deleted:
        signOut();
        return '/login';
      case MemberStatus.suspended:
        return loc == '/suspended' ? null : '/suspended';
      case MemberStatus.onboarding:
        return (loc == '/onboarding' || loc == '/verification') ? null : '/onboarding';
      case MemberStatus.pending:
      case MemberStatus.active:
      case MemberStatus.unknown:
        if (_public.contains(loc) || loc == '/splash' || loc == '/suspended') return '/discover';
        return null;
    }
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/suspended', builder: (_, _) => const SuspendedScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/verification', builder: (_, _) => const VerificationScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/connections',
              builder: (_, s) => ConnectionsScreen(initialTab: s.uri.queryParameters['tab']),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (_, _) => const ConversationsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      // Opening a chat with someone: unlocks (free on a match) then replaces
      // itself with the thread.
      GoRoute(path: '/messages/new/:userId', builder: (_, s) => NewChatScreen(userId: s.pathParameters['userId']!, name: s.uri.queryParameters['name'])),
      GoRoute(path: '/messages/:id', builder: (_, s) => ChatScreen(conversationId: s.pathParameters['id']!)),
      GoRoute(path: '/u/:username', builder: (_, s) => MemberProfileScreen(username: s.pathParameters['username']!)),
      GoRoute(path: '/search', builder: (_, s) => SearchScreen(directory: s.uri.queryParameters['mode'] == 'directory')),
      GoRoute(path: '/wallet', builder: (_, s) => WalletScreen(initialTab: s.uri.queryParameters['tab'])),
      GoRoute(path: '/premium', builder: (_, _) => const PremiumScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile/albums', builder: (_, _) => const AlbumsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/privacy', builder: (_, _) => const PrivacySettingsScreen()),
      GoRoute(path: '/settings/blocked', builder: (_, _) => const BlockedScreen()),
      GoRoute(path: '/settings/help', builder: (_, _) => const HelpSupportScreen()),
    ],
  );
});
