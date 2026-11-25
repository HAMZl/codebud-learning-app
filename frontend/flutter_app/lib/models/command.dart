import 'package:flutter/material.dart';

/// Block types. The strings match the backend's program format.
class BlockType {
  static const up = 'Up';
  static const down = 'Down';
  static const left = 'Left';
  static const right = 'Right';
  static const loop = 'Loop';
  static const ifBlock = 'If';

  static const moves = [up, down, left, right];

  static bool isMove(String type) => moves.contains(type);

  static IconData icon(String type) => switch (type) {
        up => Icons.arrow_upward,
        down => Icons.arrow_downward,
        left => Icons.arrow_back,
        right => Icons.arrow_forward,
        loop => Icons.loop,
        ifBlock => Icons.call_split,
        _ => Icons.help,
      };
}

/// What an If block looks for, and in which direction.
class Condition {
  static const targets = ['obstacle', 'empty', 'goal'];
  static const directions = ['up', 'down', 'left', 'right'];

  static IconData targetIcon(String target) => switch (target) {
        'obstacle' => Icons.terrain,
        'goal' => Icons.star,
        _ => Icons.crop_square,
      };

  /// Words for grown-ups and screen readers. Children go by the pictures.
  static String targetLabel(String target) => switch (target) {
        'obstacle' => 'a rock or wall',
        'goal' => 'the star',
        _ => 'an empty space',
      };

  static IconData directionIcon(String direction) => BlockType.icon(
        direction[0].toUpperCase() + direction.substring(1),
      );
}

/// One block in the child's program. Loop and If blocks hold a [body].
class CommandItem {
  final String type;
  int repeat;
  String target;
  String direction;
  final List<CommandItem> body;

  CommandItem({
    required this.type,
    this.repeat = 2,
    this.target = 'obstacle',
    this.direction = 'right',
    List<CommandItem>? body,
  }) : body = body ?? <CommandItem>[]; // never a const list: blocks are dropped into it

  static const minRepeat = 2;
  static const maxRepeat = 10;

  bool get isContainer => type == BlockType.loop || type == BlockType.ifBlock;
  String get condition => '${target}_$direction';

  /// Which block types may be dropped inside this one. This matches the backend rules.
  bool accepts(String childType) => switch (type) {
        BlockType.loop => childType != BlockType.loop,
        BlockType.ifBlock => BlockType.isMove(childType),
        _ => false,
      };

  Map<String, dynamic> toJson() => switch (type) {
        BlockType.loop => {'type': type, 'repeat': repeat, 'body': body.map((b) => b.toJson()).toList()},
        BlockType.ifBlock => {'type': type, 'condition': condition, 'body': body.map((b) => b.toJson()).toList()},
        _ => {'type': type},
      };
}

/// Remove [item] from [program] or from any nested body. Returns true if it was found.
bool removeBlock(List<CommandItem> program, CommandItem item) {
  if (program.remove(item)) return true;
  for (final block in program) {
    if (removeBlock(block.body, item)) return true;
  }
  return false;
}
