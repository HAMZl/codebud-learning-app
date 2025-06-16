import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background to match design
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logo
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CodeBud',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  ClipOval(
                    child: Image.asset(
                      'lib/assets/images/codebud_logo.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Greeting message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Hey, Buddy! What will you learn today?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 52),

            // Grid of learning cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    _buildCard(
                      context,
                      title: 'Sequencing',
                      icon: Icons.timeline,
                      bgColor: Colors.blue[200]!,
                      onTapRoute: '/sequences',
                    ),
                    _buildCard(
                      context,
                      title: 'Loops',
                      icon: Icons.loop,
                      bgColor: Colors.green[200]!,
                      onTapRoute: '/loops',
                    ),
                    _buildCard(
                      context,
                      title: 'Conditionals',
                      icon: Icons.question_answer,
                      bgColor: Colors.yellow[200]!,
                      onTapRoute: '/conditionals',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bgColor,
    required String onTapRoute,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, onTapRoute),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
