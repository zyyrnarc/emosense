import 'package:flutter/material.dart';

import 'app.dart';
import 'core/routers/app_routers.dart';
import 'data/stores/auth_store.dart';
import 'core/app_settings.dart';

Future<void> start() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.initialize();
  await AppSettings.instance.load();
  runApp(EmoSenseApp(
    initialRoute: AuthStore.currentUser == null
        ? AppRoutes.welcome
        : AppRoutes.dashboard,
  ));
}
