import 'package:flutter/material.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.lightBlue[100], // Soft blue for kid-friendly feel
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🧸 Buddy mascot logo
              Image.asset('assets/images/codebud_logo.png', height: 180),
              const SizedBox(height: 32),
              const Text(
                'Welcome to CodeBud!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 40),
=======
      backgroundColor: Colors.white, // white background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
>>>>>>> puzzle-selection-ui

                // 🔰 Logo
                Image.asset(
                  'assets/images/codebud_logo.png',
                  height: 140,
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'CodeBud',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'A Visual Coding Adventure for Kids',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

<<<<<<< HEAD
              const SizedBox(height: 16),
            ],
=======
                const Spacer(flex: 1),

                // 🔐 Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF), // purple-blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),

                // 📝 Sign up Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Sign up'),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
>>>>>>> puzzle-selection-ui
          ),
        ),
      ),
    );
  }
}
