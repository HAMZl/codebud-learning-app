import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/app_scope.dart';
import 'landing_page.dart';

/// The `/` route. Logged-in players go straight to the home screen, and everyone else sees the landing page.
class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  bool _checking = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checking) _skipIfLoggedIn();
  }

  Future<void> _skipIfLoggedIn() async {
    final loggedIn = await AppScope.of(context).auth.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return const LandingPage();
  }
}
