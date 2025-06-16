import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back button
        title: const Center(
          child: Text(
            'CodeBud Home',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hey Buddy! What will you learn today?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CategoryButton(
                label: 'Sequences',
                color: Colors.orange,
                onPressed: () {
                  Navigator.pushNamed(context, '/sequences');
                },
              ),
              const SizedBox(height: 20),
              CategoryButton(
                label: 'Loops',
                color: Colors.green,
                onPressed: () {
                  Navigator.pushNamed(context, '/loops');
                },
              ),
              const SizedBox(height: 20),
              CategoryButton(
                label: 'Conditionals',
                color: Colors.blue,
                onPressed: () {
                  Navigator.pushNamed(context, '/conditionals');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const CategoryButton({
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
=======
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _buildCard(
                      context,
                      title: 'Sequencing',
                      icon: Icons.timeline,
                      bgColor: Colors.blue[50]!,
                      onTapRoute: '/sequences',
                    ),
                    _buildCard(
                      context,
                      title: 'Loops',
                      icon: Icons.loop,
                      bgColor: Colors.green[50]!,
                      onTapRoute: '/loops',
                    ),
                    _buildCard(
                      context,
                      title: 'Conditionals',
                      icon: Icons.question_answer,
                      bgColor: Colors.yellow[50]!,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
>>>>>>> puzzle-selection-ui
        ),
      ),
    );
  }
}
