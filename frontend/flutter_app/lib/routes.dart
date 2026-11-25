import 'package:flutter/material.dart';

import 'models/category.dart';
import 'screens/home_page.dart';
import 'screens/launch_page.dart';
import 'screens/login_page.dart';
import 'screens/parent_settings_page.dart';
import 'screens/profiles_page.dart';
import 'screens/puzzle_gameplay.dart';
import 'screens/puzzle_selection_page.dart';
import 'screens/robot_studio_page.dart';
import 'screens/settings_page.dart';
import 'screens/signup_page.dart';

class Routes {
  static const launch = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const profiles = '/profiles';
  static const home = '/home';
  static const robot = '/robot';
  static const category = '/category';
  static const puzzle = '/puzzle';
  static const settings = '/settings';
  static const parentSettings = '/settings/parent';

  /// Older route names that still work.
  static const _legacyCategories = {
    '/sequences': 'sequence',
    '/loops': 'loop',
    '/conditionals': 'conditional',
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings route) {
    final args = route.arguments;
    Widget page;
    switch (route.name) {
      case launch:
        page = const LaunchPage();
      case login:
        page = LoginPage(message: args is String ? args : null);
      case signup:
        page = const SignUpPage();
      case profiles:
        page = const ProfilesPage();
      case home:
        page = const HomePage();
      case robot:
        page = const RobotStudioPage();
      case category:
        page = PuzzleSelectionPage(category: PuzzleCategory.byId(args as String));
      case settings:
        page = const SettingsPage();
      case parentSettings:
        page = const ParentSettingsPage();
      case puzzle:
        // Accept a puzzle id string, or the older {'id': ...} map.
        final id = args is Map ? args['id'] as String : args as String;
        page = PuzzleScreen(puzzleId: id);
      default:
        final legacy = _legacyCategories[route.name];
        if (legacy == null) return null;
        page = PuzzleSelectionPage(category: PuzzleCategory.byId(legacy));
    }
    return MaterialPageRoute(builder: (_) => page, settings: route);
  }
}
