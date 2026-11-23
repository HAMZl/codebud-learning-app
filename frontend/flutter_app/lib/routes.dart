import 'package:flutter/material.dart';

import 'models/category.dart';
import 'screens/home_page.dart';
import 'screens/launch_page.dart';
import 'screens/login_page.dart';
import 'screens/puzzle_gameplay.dart';
import 'screens/puzzle_selection_page.dart';
import 'screens/signup_page.dart';

class Routes {
  static const launch = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const category = '/category';
  static const puzzle = '/puzzle';

  /// Older route names that still work.
  static const _legacyCategories = {
    '/sequences': 'sequence',
    '/loops': 'loop',
    '/conditionals': 'conditional',
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    Widget page;
    switch (settings.name) {
      case launch:
        page = const LaunchPage();
      case login:
        page = LoginPage(message: args is String ? args : null);
      case signup:
        page = const SignUpPage();
      case home:
        page = const HomePage();
      case category:
        page = PuzzleSelectionPage(category: PuzzleCategory.byId(args as String));
      case puzzle:
        // Accept a puzzle id string, or the older {'id': ...} map.
        final id = args is Map ? args['id'] as String : args as String;
        page = PuzzleScreen(puzzleId: id);
      default:
        final legacy = _legacyCategories[settings.name];
        if (legacy == null) return null;
        page = PuzzleSelectionPage(category: PuzzleCategory.byId(legacy));
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
