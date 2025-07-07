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
  final List<int> starMoves;
  final String category;
  final int moveCount;

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
    required this.starMoves,
    required this.category,
    required this.moveCount,
  });

  @override
  State<PuzzleGrid> createState() => PuzzleGridState();
}

class PuzzleGridState extends State<PuzzleGrid> {
  late Point robotPosition;
  final double cellSize = 70;

  final Color primaryOrange = const Color(0xFFFFA726);
  final Color lightOrange = const Color(0xFFFFE0B2);

  @override
  void initState() {
    super.initState();
    robotPosition = widget.start;
  }

  void updateRobot(Point newPosition) {
    setState(() {
      robotPosition = newPosition;
    });
  }

  int calculateStars() {
    for (int i = 0; i < widget.starMoves.length; i++) {
      if (widget.moveCount <= widget.starMoves[i]) return 3 - i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final starsEarned = calculateStars();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryOrange, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.star_border,
                            size: 32,
                            color: Colors.black,
                          ),
                          Icon(
                            Icons.star,
                            size: 28,
                            color: i < starsEarned
                                ? primaryOrange
                                : lightOrange,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                Text(
                  'Moves: ${widget.moveCount}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // <- Changed to black
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: widget.gridSize * cellSize,
              height: widget.gridSize * cellSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.gridSize * widget.gridSize,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.gridSize,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ widget.gridSize;
                  final col = index % widget.gridSize;
                  return _buildGridTile(row, col);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile(int row, int col) {
    final point = Point(row, col);
    bool isRobot = point == robotPosition;
    bool isGoal = point == widget.goal;
    bool isObstacle = widget.obstacles.contains(point);

    Color bgColor = Colors.white;
    IconData? icon;
    Color iconColor = Colors.black;

    if (isObstacle) {
      bgColor = Colors.grey.shade300;
      icon = Icons.terrain;
      iconColor = Colors.black;
    } else if (isGoal) {
      bgColor = Colors.yellow.shade100;
      icon = Icons.star;
      iconColor = Colors.amber;
    } else if (isRobot) {
      bgColor = Colors.green.shade100;
      icon = Icons.smart_toy;
      iconColor = Colors.green.shade800;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4), // <- Less rounded corners
      ),
      child: Center(
        child: isRobot && isGoal
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.star, size: 32, color: Colors.amber), // Goal
                  Icon(
                    Icons.smart_toy,
                    size: 36,
                    color: Colors.green.shade800,
                  ), // Robot on top
                ],
              )
            : icon != null
            ? Icon(icon, size: 36, color: iconColor)
            : const SizedBox.shrink(),
      ),
    );
  }
}
