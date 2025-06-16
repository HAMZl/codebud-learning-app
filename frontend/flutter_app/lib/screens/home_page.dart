import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ),
      ),
    );
  }
}
