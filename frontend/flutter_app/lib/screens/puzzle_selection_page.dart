import 'package:flutter/material.dart';
import '../widgets/puzzle_button.dart';

class PuzzleSelectionPage extends StatelessWidget {
  const PuzzleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Puzzle')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PuzzleButton(
              label: '🧩 Puzzle 1',
              onPressed: () {
                // Navigate to Puzzle 1 (to be implemented)
              },
            ),
            const SizedBox(height: 16),
            PuzzleButton(
              label: '🎨 Puzzle 2',
              onPressed: () {
                // Navigate to Puzzle 2
              },
            ),
            const SizedBox(height: 16),
            PuzzleButton(
              label: '🔢 Puzzle 3',
              onPressed: () {
                // Navigate to Puzzle 3
              },
            ),
          ],
        ),
      ),
    );
  }
}
