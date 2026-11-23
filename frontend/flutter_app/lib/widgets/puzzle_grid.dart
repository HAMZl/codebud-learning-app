import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/point.dart';
import '../models/puzzle.dart';
import '../theme/app_theme.dart';

/// Draws the board and the robot. It holds no game state. The parent passes [robot] in.
class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    super.key,
    required this.puzzle,
    required this.robot,
    required this.blocksUsed,
    required this.starPreview,
    this.stepDuration = const Duration(milliseconds: 300),
  });

  final Puzzle puzzle;
  final Point robot;
  final int blocksUsed;

  /// Stars the current program would earn if it solves the puzzle.
  final int starPreview;
  final Duration stepDuration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Fit small phones while capping the size on tablets and desktop.
      final available = math.min(constraints.maxWidth - 40, 420.0);
      final cell = (available / puzzle.gridSize).clamp(36.0, 72.0);
      final boardSize = cell * puzzle.gridSize;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            SizedBox(width: boardSize + 12, child: _header()),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: Stack(
                  children: [
                    for (var r = 0; r < puzzle.gridSize; r++)
                      for (var c = 0; c < puzzle.gridSize; c++)
                        Positioned(
                            left: c * cell, top: r * cell, width: cell, height: cell, child: _tile(Point(r, c), cell)),
                    AnimatedPositioned(
                      duration: stepDuration,
                      curve: Curves.easeInOut,
                      top: robot.row * cell,
                      left: robot.col * cell,
                      width: cell,
                      height: cell,
                      child:
                          Icon(Icons.smart_toy, size: cell * 0.6, color: Colors.green.shade800, semanticLabel: 'Robot'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(
                3,
                (i) => Icon(i < starPreview ? Icons.star : Icons.star_border, size: 24, color: AppColors.primary),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.widgets_outlined, size: 18),
                const SizedBox(width: 4),
                Text('$blocksUsed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );

  Widget _tile(Point p, double cell) {
    final isObstacle = puzzle.obstacles.contains(p);
    final isGoal = p == puzzle.goal;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isObstacle ? Colors.grey.shade300 : (isGoal ? Colors.yellow.shade100 : Colors.white),
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isObstacle
          ? Icon(Icons.terrain, size: cell * 0.55, semanticLabel: 'Rock')
          : isGoal
              ? Icon(Icons.star, size: cell * 0.6, color: AppColors.star, semanticLabel: 'Goal')
              : null,
    );
  }
}
