// lib/screens/puzzle_selection_page.dart
import 'package:flutter/material.dart';
import '../widgets/puzzle_button.dart';

class PuzzleSelectionPage extends StatelessWidget {
  final String title;

  const PuzzleSelectionPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PuzzleButton(
              label: '🧩 Puzzle 1',
              onPressed: () {
                Navigator.pushNamed(context, '/puzzle');
              },
            ),
            const SizedBox(height: 16),
            PuzzleButton(
              label: '🎨 Puzzle 2',
              onPressed: () {
                Navigator.pushNamed(context, '/puzzle');
              },
            ),
            const SizedBox(height: 16),
            PuzzleButton(
              label: '🔢 Puzzle 3',
              onPressed: () {
                Navigator.pushNamed(context, '/puzzle');
              },
            ),
          ],
        ),
      ),
    );
  }
}
