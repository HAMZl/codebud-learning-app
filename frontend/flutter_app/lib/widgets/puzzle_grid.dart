import 'package:flutter/material.dart';
import '../models/point.dart';

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
  final double cellSize = 60;

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryOrange, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.star_border,
                            size: 24,
                            color: Colors.black,
                          ),
                          Icon(
                            Icons.star,
                            size: 20,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: widget.gridSize * cellSize,
              height: widget.gridSize * cellSize,
              child: Stack(children: [_buildGrid(), _buildAnimatedRobot()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
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
    );
  }

  Widget _buildGridTile(int row, int col) {
    final point = Point(row, col);
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
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 36, color: iconColor)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAnimatedRobot() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: robotPosition.row * cellSize,
      left: robotPosition.col * cellSize,
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Center(
          child: Icon(Icons.smart_toy, size: 36, color: Colors.green.shade800),
        ),
      ),
    );
  }
}
