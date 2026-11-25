import 'package:flutter/material.dart';

import '../models/family.dart';

/// A child's robot: their chosen character on a circle of their chosen colour.
class RobotAvatar extends StatelessWidget {
  const RobotAvatar({super.key, required this.look, this.size = 64, this.selected = false});

  final RobotLook look;
  final double size;

  /// Draws a thick white-and-colour ring, e.g. for the profile being picked.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = look.colorValue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        border: Border.all(color: Colors.white, width: size * 0.06),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: selected ? 0.6 : 0.3), blurRadius: size * 0.2, spreadRadius: 1),
          if (selected) BoxShadow(color: color, spreadRadius: size * 0.08),
        ],
      ),
      child: Icon(look.icon, color: Colors.white, size: size * 0.55, semanticLabel: look.displayName),
    );
  }
}
