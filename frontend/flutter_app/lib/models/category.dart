import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'command.dart';

/// A puzzle category and the blocks it unlocks.
class PuzzleCategory {
  final String id;
  final String title;
  final String tagline;
  final IconData icon;
  final Color color;
  final List<String> blocks;

  const PuzzleCategory({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.blocks,
  });

  static const sequence = PuzzleCategory(
    id: 'sequence',
    title: 'Sequencing',
    tagline: 'Put moves in the right order',
    icon: Icons.timeline,
    color: AppColors.sky,
    blocks: BlockType.moves,
  );
  static const loop = PuzzleCategory(
    id: 'loop',
    title: 'Loops',
    tagline: 'Repeat a pattern',
    icon: Icons.repeat,
    color: AppColors.loop,
    blocks: [BlockType.loop, ...BlockType.moves],
  );
  static const conditional = PuzzleCategory(
    id: 'conditional',
    title: 'Conditionals',
    tagline: 'Look first, then decide',
    icon: Icons.call_split,
    color: AppColors.violet,
    blocks: [BlockType.ifBlock, BlockType.loop, ...BlockType.moves],
  );

  static const all = [sequence, loop, conditional];

  static PuzzleCategory byId(String id) => all.firstWhere((c) => c.id == id, orElse: () => sequence);
}
