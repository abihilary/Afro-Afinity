import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login/login_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/discover/discover_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const DiscoverScreen()),
  ],
);
