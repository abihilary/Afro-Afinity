import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'router.dart';

class AfricanAffinityApp extends StatelessWidget {
  const AfricanAffinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'African Affinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
