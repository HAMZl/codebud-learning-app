import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/app_scope.dart';
import 'landing_page.dart';

/// The `/` route. Logged-in families go to "Who's playing?", and everyone else sees the landing page.
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
    // A deep link like /home also builds this route underneath it. Only redirect when this
    // page is the one on screen, or it would replace the page the link opened.
    final onScreen = ModalRoute.of(context)?.isCurrent ?? true;
    if (loggedIn && onScreen) {
      Navigator.pushReplacementNamed(context, Routes.profiles);
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
