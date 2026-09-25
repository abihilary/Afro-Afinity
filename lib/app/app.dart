import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'router.dart';

class AfricanAffinityApp extends StatefulWidget {
  const AfricanAffinityApp({super.key});

  @override
  State<AfricanAffinityApp> createState() => _AfricanAffinityAppState();
}

class _AfricanAffinityAppState extends State<AfricanAffinityApp> {
  final _themeController = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_refresh);
  }

  @override
  void dispose() {
    _themeController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'African Affinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeController.themeMode,
      routerConfig: appRouter,
    );
  }
}
