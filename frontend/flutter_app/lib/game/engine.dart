import '../models/command.dart';
import '../models/point.dart';
import '../models/puzzle.dart';

/// The game rules. This mirrors `backend/codebud/engine.py`; keep the two in sync.
///
/// * Moves go one cell. Hitting the grid edge or a rock stops the run.
/// * Loop repeats its body. If runs its body when the neighbouring cell in its
///   direction is the target: an obstacle (a rock or the edge), an empty
///   cell, or the goal.
/// * The run ends as soon as the robot reaches the goal.
/// * Stars count every block, nested blocks included. At or under par earns 3,
///   par + 2 earns 2, and any other solution earns 1.
enum RunStatus { success, wall, obstacle, incomplete }

class RunResult {
  final RunStatus status;
  final List<Point> path;
  final int blocks;
  final int stars;

  const RunResult({required this.status, required this.path, required this.blocks, required this.stars});

  bool get solved => status == RunStatus.success;

  String? get hint => switch (status) {
        RunStatus.wall => "Oops! You're bumping into a wall.",
        RunStatus.obstacle => "Watch out! There's an obstacle in the way.",
        RunStatus.incomplete => "Hmm... you didn't reach the goal. Try changing your moves.",
        RunStatus.success => null,
      };
}

class GameEngine {
  static const _deltas = {
    BlockType.up: (-1, 0),
    BlockType.down: (1, 0),
    BlockType.left: (0, -1),
    BlockType.right: (0, 1),
  };

  static int countBlocks(List<CommandItem> program) => program.fold(0, (sum, b) => sum + 1 + countBlocks(b.body));

  static int starsFor(int blocks, int par) {
    if (blocks <= par) return 3;
    if (blocks <= par + 2) return 2;
    return 1;
  }

  static RunResult run(Puzzle puzzle, List<CommandItem> program) {
    var pos = puzzle.start;
    final path = <Point>[pos];

    Point neighbour(String direction) {
      final (dr, dc) = _deltas[direction[0].toUpperCase() + direction.substring(1)]!;
      return Point(pos.row + dr, pos.col + dc);
    }

    bool check(CommandItem block) {
      final cell = neighbour(block.direction);
      return switch (block.target) {
        'obstacle' => puzzle.isBlocked(cell),
        'goal' => cell == puzzle.goal,
        _ => !puzzle.isBlocked(cell),
      };
    }

    RunStatus? execute(List<CommandItem> blocks) {
      for (final block in blocks) {
        if (block.type == BlockType.loop) {
          for (var i = 0; i < block.repeat; i++) {
            final stop = execute(block.body);
            if (stop != null) return stop;
          }
        } else if (block.type == BlockType.ifBlock) {
          if (check(block)) {
            final stop = execute(block.body);
            if (stop != null) return stop;
          }
        } else {
          final (dr, dc) = _deltas[block.type]!;
          final next = Point(pos.row + dr, pos.col + dc);
          final inBounds = next.row >= 0 && next.col >= 0 && next.row < puzzle.gridSize && next.col < puzzle.gridSize;
          if (!inBounds) return RunStatus.wall;
          if (puzzle.obstacles.contains(next)) return RunStatus.obstacle;
          pos = next;
          path.add(pos);
          if (pos == puzzle.goal) return RunStatus.success;
        }
      }
      return null;
    }

    final status = execute(program) ?? RunStatus.incomplete;
    final blocks = countBlocks(program);
    return RunResult(
      status: status,
      path: path,
      blocks: blocks,
      stars: status == RunStatus.success ? starsFor(blocks, puzzle.par) : 0,
    );
  }
}
