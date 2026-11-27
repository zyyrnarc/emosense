import 'package:flutter/widgets.dart';

import '../../features/auth/login.dart';
import '../../features/auth/register.dart';
import '../../features/pages/home_page.dart';
import '../../features/pages/user/user_home_page.dart';
import '../../data/stores/auth_store.dart';

class AppRoutes {
  AppRoutes._();

  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';

  static final Map<String, WidgetBuilder> routes = {
    welcome: (_) => const HomePage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    dashboard: (_) => AuthStore.currentUser == null
        ? const HomePage()
        : UserHomePage(user: AuthStore.currentUser!),
  };
}
