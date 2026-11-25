import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/game/engine.dart';
import 'package:flutter_app/models/command.dart';
import 'package:flutter_app/models/point.dart';
import 'package:flutter_app/models/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

// 3x3 board: start top-left, goal bottom-right, rock in the middle.
const board = Puzzle(
  id: 't',
  title: 'Test',
  category: 'sequence',
  gridSize: 3,
  start: Point(0, 0),
  goal: Point(2, 2),
  obstacles: [Point(1, 1)],
  par: 4,
);

CommandItem m(String type) => CommandItem(type: type);
List<CommandItem> moves(List<String> types) => types.map(m).toList();

/// Turns the backend's JSON program format into CommandItems.
CommandItem fromJson(Map<String, dynamic> j) {
  final body = (j['body'] as List? ?? const []).map((b) => fromJson(b as Map<String, dynamic>)).toList();
  final item = CommandItem(type: j['type'] as String, repeat: j['repeat'] as int? ?? 2, body: body);
  final cond = j['condition'] as String?;
  if (cond != null) {
    final parts = cond.split('_');
    item
      ..target = parts[0]
      ..direction = parts[1];
  }
  return item;
}

void main() {
  test('simple path reaches the goal with 3 stars', () {
    final r = GameEngine.run(board, moves(['Right', 'Right', 'Down', 'Down']));
    expect(r.status, RunStatus.success);
    expect(r.path.last, const Point(2, 2));
    expect(r.stars, 3);
  });

  test('wall, obstacle and incomplete', () {
    expect(GameEngine.run(board, moves(['Up'])).status, RunStatus.wall);
    expect(GameEngine.run(board, moves(['Right', 'Down'])).status, RunStatus.obstacle);
    expect(GameEngine.run(board, moves(['Right'])).status, RunStatus.incomplete);
  });

  test('run stops at the goal', () {
    expect(GameEngine.run(board, moves(['Down', 'Down', 'Right', 'Right', 'Right'])).solved, isTrue);
  });

  test('loops repeat and count nested blocks', () {
    final program = [
      CommandItem(type: 'Loop', repeat: 2, body: [m('Right')]),
      CommandItem(type: 'Loop', repeat: 2, body: [m('Down')]),
    ];
    final r = GameEngine.run(board, program);
    expect(r.solved, isTrue);
    expect(r.blocks, 4);
  });

  test('if checks the neighbouring cell; the edge counts as an obstacle', () {
    bool movedAgain(String target, String direction) {
      final program = [
        m('Right'),
        CommandItem(type: 'If', target: target, direction: direction, body: [m('Right')]),
      ];
      return GameEngine.run(board, program).path.last == const Point(0, 2);
    }

    expect(movedAgain('obstacle', 'down'), isTrue);
    expect(movedAgain('empty', 'right'), isTrue);
    expect(movedAgain('obstacle', 'up'), isTrue);
    expect(movedAgain('goal', 'down'), isFalse);
  });

  test('stars scale with block count and never drop to 0 on success', () {
    expect(GameEngine.starsFor(4, 4), 3);
    expect(GameEngine.starsFor(6, 4), 2);
    expect(GameEngine.starsFor(30, 4), 1);
  });

  test('toJson matches the backend program format', () {
    final loop = CommandItem(type: 'Loop', repeat: 3, body: [
      CommandItem(type: 'If', target: 'goal', direction: 'down', body: [m('Down')]),
    ]);
    expect(loop.toJson(), {
      'type': 'Loop',
      'repeat': 3,
      'body': [
        {
          'type': 'If',
          'condition': 'goal_down',
          'body': [
            {'type': 'Down'}
          ]
        },
      ],
    });
  });

  test('nesting rules match the backend', () {
    expect(CommandItem(type: 'Loop').accepts('If'), isTrue);
    expect(CommandItem(type: 'Loop').accepts('Loop'), isFalse);
    expect(CommandItem(type: 'If').accepts('Right'), isTrue);
    expect(CommandItem(type: 'If').accepts('Loop'), isFalse);
  });

  test('blocks dropped into a new Loop body can be added (body is not const)', () {
    final loop = CommandItem(type: 'Loop');
    loop.body.add(m('Up'));
    expect(loop.body, hasLength(1));
  });

  test('removeBlock finds nested blocks', () {
    final inner = m('Up');
    final program = [
      CommandItem(type: 'Loop', body: [inner])
    ];
    expect(removeBlock(program, inner), isTrue);
    expect(program.single.body, isEmpty);
  });

  // Parity with the Python engine: every shipped reference solution must earn 3 stars here too.
  group('shipped puzzles', () {
    final file = File('../../database/puzzles.json');
    final puzzles = (jsonDecode(file.readAsStringSync()) as List).cast<Map<String, dynamic>>();

    for (final json in puzzles) {
      test('${json['id']} reference solution earns 3 stars', () {
        final puzzle = Puzzle.fromJson(json);
        final program = (json['solution'] as List).map((b) => fromJson(b as Map<String, dynamic>)).toList();
        final r = GameEngine.run(puzzle, program);
        expect(r.status, RunStatus.success);
        expect(r.stars, 3);
      });
    }
  });

  group('puzzles with several boards', () {
    // Two 3x3 boards: the rock is to the right of the start on the first, below it on the second.
    const twoBoards = Puzzle(
      id: 'm',
      title: 'Moving rock',
      category: 'conditional',
      gridSize: 3,
      start: Point(0, 0),
      goal: Point(2, 2),
      obstacles: [Point(0, 1)],
      par: 4,
      variants: [
        BoardVariant(obstacles: [Point(1, 0)])
      ],
    );

    test('boards share the size, start and goal unless the variant changes them', () {
      final boards = twoBoards.boards;
      expect(boards, hasLength(2));
      expect(boards[1].start, const Point(0, 0));
      expect(boards[1].obstacles, [const Point(1, 0)]);
    });

    test('a program must solve every board', () {
      final result = GameEngine.runPuzzle(twoBoards, moves(['Down', 'Down', 'Right', 'Right']));
      expect(result.solved, isFalse);
      expect(result.board, 1);
      expect(result.boards.map((r) => r.status), [RunStatus.success, RunStatus.obstacle]);
      expect(result.stars, 0);
    });

    test('an If block can solve both boards', () {
      // If the way right is blocked, go down first. If the way down is blocked, go right first.
      final program = [
        CommandItem(type: BlockType.ifBlock, direction: 'right', body: moves(['Down', 'Down', 'Right', 'Right'])),
        CommandItem(type: BlockType.ifBlock, direction: 'down', body: moves(['Right', 'Right', 'Down', 'Down'])),
      ];
      final result = GameEngine.runPuzzle(twoBoards, program);
      expect(result.boards.map((r) => r.status), everyElement(RunStatus.success));
      expect(result.solved, isTrue);
    });

    test('the shipped multi-board levels are solved by their reference solutions', () {
      final shipped = (jsonDecode(File('../../database/puzzles.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .where((p) => p['variants'] != null);
      expect(shipped, isNotEmpty);
      for (final json in shipped) {
        final puzzle = Puzzle.fromJson(json);
        final program = (json['solution'] as List).map((b) => fromJson(b as Map<String, dynamic>)).toList();
        final result = GameEngine.runPuzzle(puzzle, program);
        expect(result.solved, isTrue, reason: '${puzzle.id} fails on board ${result.board + 1}');
        expect(result.stars, 3, reason: puzzle.id);
      }
    });
  });
}
