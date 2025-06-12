import 'package:flutter/material.dart';
import 'screens/launch_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      // Set up the named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const LaunchPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
      },
    );
  }
}
