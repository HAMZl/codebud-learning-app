import 'package:flutter/material.dart';

import 'command.dart';

/// A puzzle category and the blocks it unlocks.
class PuzzleCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> blocks;

  const PuzzleCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.blocks,
  });

  static const sequence = PuzzleCategory(
    id: 'sequence',
    title: 'Sequencing',
    icon: Icons.timeline,
    color: Colors.blue,
    blocks: BlockType.moves,
  );
  static const loop = PuzzleCategory(
    id: 'loop',
    title: 'Loops',
    icon: Icons.repeat,
    color: Colors.green,
    blocks: [BlockType.loop, ...BlockType.moves],
  );
  static const conditional = PuzzleCategory(
    id: 'conditional',
    title: 'Conditionals',
    icon: Icons.device_unknown,
    color: Colors.orange,
    blocks: [BlockType.ifBlock, BlockType.loop, ...BlockType.moves],
  );

  static const all = [sequence, loop, conditional];

  static PuzzleCategory byId(String id) => all.firstWhere((c) => c.id == id, orElse: () => sequence);
}
