import 'package:flutter/material.dart';

class PuzzleSelectionPage extends StatelessWidget {
  final String title;
  final String category;

  const PuzzleSelectionPage({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CodeBud',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Image.asset(
                    'lib/assets/images/codebud_logo.png',
                    height: 50,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),

              // Puzzle Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                  children: [
                    _buildPuzzleCard(
                      title: 'Puzzle 1',
                      image: 'lib/assets/images/sequencing.png',
                      color: Colors.pink[100]!,
                      onTap: () {
                        Navigator.pushNamed(context, '/puzzle');
                      },
                    ),
                    _buildPuzzleCard(
                      title: 'Puzzle 2',
                      image: 'lib/assets/images/loops.png',
                      color: Colors.orange[100]!,
                      onTap: () {
                        Navigator.pushNamed(context, '/puzzle');
                      },
                    ),
                    _buildPuzzleCard(
                      title: 'Puzzle 3',
                      image: 'lib/assets/images/conditionals.png',
                      color: Colors.purple[100]!,
                      onTap: () {
                        Navigator.pushNamed(context, '/puzzle');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleCard({
    required String title,
    required String image,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 90),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
