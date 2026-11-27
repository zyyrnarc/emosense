import 'package:flutter/material.dart';

import 'core/routers/app_routers.dart';
import 'core/theme/app_theme.dart';

class EmoSenseApp extends StatelessWidget {
  const EmoSenseApp({super.key, this.initialRoute = AppRoutes.welcome});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmoSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
