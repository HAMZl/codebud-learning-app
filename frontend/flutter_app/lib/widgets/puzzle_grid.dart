import 'package:flutter/material.dart';

class Point {
  final int row;
  final int col;

  const Point(this.row, this.col);

  factory Point.fromList(List<dynamic> list) =>
      Point(list[0] as int, list[1] as int);

  List<int> toList() => [row, col];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class PuzzleGrid extends StatefulWidget {
  final int gridSize;
  final Point start;
  final Point goal;
  final List<Point> obstacles;
  final List<int> starMoves; // e.g., [6, 8, 10]
  final String category; // e.g., 'sequence', 'loop', 'conditional'
  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
    required this.starMoves,
    required this.category,
  });

  @override
  State<PuzzleGrid> createState() => PuzzleGridState();
}

class PuzzleGridState extends State<PuzzleGrid> {
  late Point robotPosition;
  int moveCount = 0;

  @override
  void initState() {
    super.initState();
    robotPosition = widget.start;
  }

  void updateRobot(Point newPosition) {
    setState(() {
      robotPosition = newPosition;
      moveCount++;
    });
  }

  int calculateStars() {
    for (int i = 0; i < widget.starMoves.length; i++) {
      if (moveCount <= widget.starMoves[i]) return 3 - i;
    }
    return 0;
  }

  List<Widget> buildStarRow() {
    int stars = calculateStars();
    return List.generate(
      3,
      (i) => Icon(
        Icons.star,
        color: i < stars ? Colors.amber : Colors.grey.shade300,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildStarRow(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: widget.gridSize * 40,
          height: widget.gridSize * 40,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.gridSize * widget.gridSize,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridSize,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ widget.gridSize;
              final col = index % widget.gridSize;
              final icon = _getIcon(row, col);
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
        ),
        const SizedBox(height: 8),
        Text('Moves: $moveCount'),
      ],
    );
  }

  String _getIcon(int row, int col) {
    final point = Point(row, col);
    if (point == robotPosition) return '🤖';
    if (point == widget.goal) return '⭐';
    if (widget.obstacles.contains(point)) return '🪨';
    return '';
  }
}
