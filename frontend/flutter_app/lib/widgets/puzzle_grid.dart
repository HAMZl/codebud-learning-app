import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/family.dart';
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
    this.maxBoardSize = 420,
    this.showHeader = true,
    this.robotLook = const RobotLook(),
  });

  /// The child's character and colour.
  final RobotLook robotLook;

  final Puzzle puzzle;
  final Point robot;
  final int blocksUsed;

  /// Stars the current program would earn if it solves the puzzle.
  final int starPreview;
  final Duration stepDuration;

  /// The largest the board may grow, in logical pixels.
  final double maxBoardSize;

  /// Show the star preview and block count above the board.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Fit small phones while capping the size on tablets and desktop.
      // Leave room for the outer padding (2 x 16), the board padding (2 x 4) and the border (2 x 2).
      final available = math.min(constraints.maxWidth - 44, maxBoardSize);
      final cell = (available / puzzle.gridSize).clamp(16.0, 72.0);
      final boardSize = cell * puzzle.gridSize;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            if (showHeader) ...[
              SizedBox(width: boardSize + 12, child: _header()),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDDF7F1),
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
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
                      child: Center(child: _robot(cell)),
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

  Widget _robot(double cell) {
    final size = cell * 0.78;
    final color = robotLook.colorValue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: math.max(1.5, size * 0.06)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: size * 0.2)],
      ),
      child: Icon(robotLook.icon, size: size * 0.6, color: Colors.white, semanticLabel: 'Robot'),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryLight, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(
                3,
                (i) => Icon(i < starPreview ? Icons.star : Icons.star_border, size: 26, color: AppColors.star),
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
      margin: EdgeInsets.all(cell > 30 ? 2 : 1),
      decoration: BoxDecoration(
        color: isObstacle ? const Color(0xFF94A3B8) : (isGoal ? AppColors.sunshineLight : Colors.white),
        border: Border.all(
          color: isGoal ? AppColors.sunshine : (isObstacle ? const Color(0xFF64748B) : const Color(0xFFB2EBE0)),
          width: isGoal ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(cell * 0.14),
      ),
      child: isObstacle
          ? Icon(Icons.terrain, size: cell * 0.6, color: Colors.white, semanticLabel: 'Rock')
          : isGoal
              ? Icon(Icons.star, size: cell * 0.66, color: AppColors.star, semanticLabel: 'Goal')
              : null,
    );
  }
}
