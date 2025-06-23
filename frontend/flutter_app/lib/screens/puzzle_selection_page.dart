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
    final List<Map<String, dynamic>> puzzles = [
      {"id": 1, "title": "Level 1"},
      {"id": 2, "title": "Level 2"},
      {"id": 3, "title": "Level 3"},
    ];

    final List<Color> cardColors = [
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.orange.shade300,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: puzzles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final puzzle = puzzles[index];
            final level = index + 1;

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/puzzle',
                  arguments: puzzle['id'],
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top half - colored section
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColors[index % cardColors.length],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // Bottom half - level and stars
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level $level',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(
                                3,
                                (starIndex) => Icon(
                                  Icons.star,
                                  size: 24,
                                  color: starIndex < 1 + (level % 3)
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
