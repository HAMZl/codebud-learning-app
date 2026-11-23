// Puzzles bundled into the app for the landing page, so visitors can play
// without an account. They are copies of levels in database/puzzles.json, and
// test/demo_puzzles_test.dart checks that they still match.

import '../models/command.dart';
import '../models/point.dart';
import '../models/puzzle.dart';

class DemoPuzzle {
  const DemoPuzzle({required this.puzzle, required this.solution, required this.concept, required this.blurb});

  final Puzzle puzzle;

  /// Builds a fresh copy of the reference solution each time (blocks are mutable).
  final List<CommandItem> Function() solution;
  final String concept;
  final String blurb;
}

final demoPuzzles = <DemoPuzzle>[
  DemoPuzzle(
    concept: 'Sequencing',
    blurb: 'Put moves in order to guide the robot around the rock.',
    puzzle: const Puzzle(
      id: 'seq5',
      title: 'Around the Rock',
      category: 'sequence',
      gridSize: 5,
      start: Point(2, 0),
      goal: Point(2, 4),
      obstacles: [Point(2, 2)],
      par: 6,
    ),
    solution: () => [
      CommandItem(type: BlockType.up),
      CommandItem(type: BlockType.right),
      CommandItem(type: BlockType.right),
      CommandItem(type: BlockType.right),
      CommandItem(type: BlockType.down),
      CommandItem(type: BlockType.right)
    ],
  ),
  DemoPuzzle(
    concept: 'Loops',
    blurb: 'Repeat a pattern instead of dragging the same blocks again and again.',
    puzzle: const Puzzle(
      id: 'loop5',
      title: 'Staircase',
      category: 'loop',
      gridSize: 5,
      start: Point(0, 0),
      goal: Point(4, 4),
      obstacles: [Point(0, 1), Point(1, 2), Point(2, 3), Point(3, 4)],
      par: 3,
    ),
    solution: () => [
      CommandItem(
          type: BlockType.loop,
          repeat: 4,
          body: [CommandItem(type: BlockType.down), CommandItem(type: BlockType.right)])
    ],
  ),
  DemoPuzzle(
    concept: 'Conditionals',
    blurb: 'Teach the robot to look ahead and decide what to do.',
    puzzle: const Puzzle(
      id: 'cond1',
      title: 'Look Ahead',
      category: 'conditional',
      gridSize: 5,
      start: Point(0, 0),
      goal: Point(2, 4),
      obstacles: [Point(0, 2), Point(1, 3)],
      par: 4,
    ),
    solution: () => [
      CommandItem(type: BlockType.loop, repeat: 4, body: [
        CommandItem(
            type: BlockType.ifBlock, target: 'obstacle', direction: 'right', body: [CommandItem(type: BlockType.down)]),
        CommandItem(type: BlockType.right)
      ])
    ],
  ),
];
