import 'package:flutter/material.dart';
import 'package:flutter_app/screens/puzzle_gameplay.dart';
import 'screens/launch_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/puzzle_selection_page.dart';
import 'screens/puzzle_gameplay.dart';

void main() {
  runApp(const CodeBudApp());
}

class CodeBudApp extends StatelessWidget {
  const CodeBudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeBud',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',

      // Static routes
      routes: {
        '/': (context) => const LaunchPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/puzzle': (context) => const PuzzleScreen(),
      },

      // Dynamic routes for PuzzleSelectionPage with title + category
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/sequences':
            return MaterialPageRoute(
              builder: (_) => const PuzzleSelectionPage(
                title: 'Sequence Puzzles',
                category: 'sequence',
              ),
            );
          case '/loops':
            return MaterialPageRoute(
              builder: (_) => const PuzzleSelectionPage(
                title: 'Loop Puzzles',
                category: 'loop',
              ),
            );
          case '/conditionals':
            return MaterialPageRoute(
              builder: (_) => const PuzzleSelectionPage(
                title: 'Conditional Puzzles',
                category: 'conditional',
              ),
            );
        }
        return null;
      },
    );
  }
}
