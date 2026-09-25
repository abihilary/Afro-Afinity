import 'package:go_router/go_router.dart';

import '../features/auth/login/login_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/verification/verification_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/feed/feed_detail_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/likes/likes_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../models/feed.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    GoRoute(
      path: '/discover',
      name: 'discover',
      builder: (context, state) {
        return const DiscoverScreen();
      },
    ),

    GoRoute(
      path: '/feed',
      name: 'feed',
      builder: (context, state) {
        return const FeedScreen();
      },
    ),

    GoRoute(
      path: '/feed/detail',
      name: 'feed_detail',
      builder: (context, state) {
        final post = state.extra as FeedPost;
        return FeedDetailScreen(post: post);
      },
    ),

    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) {
        return const SignupScreen();
      },
    ),
    GoRoute(
      path: '/verification',
      name: 'verification',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/likes',
      name: 'likes',
      builder: (context, state) {
        return const LikesScreen();
      },
    ),

    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) {
        return const ChatScreen();
      },
    ),

    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),
  ],
);
