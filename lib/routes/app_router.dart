import 'package:flutter/material.dart';

import '../ui/screens/home_screen.dart';

class AppRouter {
  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
