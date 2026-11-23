import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/app_scope.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset('lib/assets/images/codebud_logo.png', height: 240),
                  const SizedBox(height: 12),
                  const Text(
                    'A Visual Coding Adventure for Kids',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Spacer(flex: 3),
                  if (_checking)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.login),
                        child: const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.signup),
                        child: const Text('Sign up'),
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
