import 'package:flutter/material.dart';

import '../models/command.dart';
import '../theme/app_theme.dart';

Color blockColor(String type) => switch (type) {
      BlockType.loop => AppColors.loop,
      BlockType.ifBlock => AppColors.condition,
      _ => AppColors.move,
    };

/// A single square block: a move, or a Loop/If tile in the palette.
class CommandBlock extends StatelessWidget {
  const CommandBlock({super.key, required this.type, this.isSelected = false, this.size = 54});

  final String type;
  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = blockColor(type);
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: isSelected ? AppColors.selected : Colors.white, width: isSelected ? 4 : 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(BlockType.icon(type), color: Colors.white, size: size * 0.55, semanticLabel: type),
    );
  }
}

/// A palette block the child can drag into the program.
class DraggableBlock extends StatelessWidget {
  const DraggableBlock({super.key, required this.type, this.onTap});

  final String type;

  /// Tapping adds the block to the end of the program, which is easier for small hands than dragging.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final block = CommandBlock(type: type);
    return Draggable<String>(
      data: type,
      feedback: Material(color: Colors.transparent, child: CommandBlock(type: type, size: 62)),
      childWhenDragging: Opacity(opacity: 0.4, child: block),
      child: GestureDetector(onTap: onTap, child: block),
    );
  }
}
