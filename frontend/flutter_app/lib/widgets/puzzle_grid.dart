import 'package:flutter/material.dart';

class Point {
  final int row;
  final int col;

  const Point(this.row, this.col);

  factory Point.fromList(List<dynamic> list) =>
      Point(list[0] as int, list[1] as int);

  List<int> toList() => [row, col]; // Optional: for serialization

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

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
  });

  @override
  State<PuzzleGrid> createState() => PuzzleGridState();
}

class PuzzleGridState extends State<PuzzleGrid> {
  late Point robotPosition;

  @override
  void initState() {
    super.initState();
    robotPosition = widget.start;
  }

  void updateRobot(Point newPosition) {
    setState(() => robotPosition = newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
