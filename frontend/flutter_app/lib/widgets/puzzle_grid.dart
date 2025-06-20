// lib/widgets/puzzle_grid.dart

import 'package:flutter/material.dart';

class Point {
  final int row;
  final int col;

  const Point(this.row, this.col);

  factory Point.fromList(List<dynamic> list) => Point(list[0], list[1]);

  @override
  bool operator ==(Object other) =>
      other is Point && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class PuzzleGrid extends StatelessWidget {
  final int gridSize;
  final Point start;
  final Point goal;
  final List<Point> obstacles;

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridSize * 40,
      height: gridSize * 40,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridSize * gridSize,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ gridSize;
          final col = index % gridSize;
          final icon = _getCellIcon(row, col);
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              color: Colors.white,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  String _getCellIcon(int row, int col) {
    final point = Point(row, col);
    if (point == start) return '🤖';
    if (point == goal) return '⭐';
    if (obstacles.contains(point)) return '🪨';
    return '';
  }
}
