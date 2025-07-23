import 'package:flutter/material.dart';

class CommandBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const CommandBlock({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on label
    Color baseColor;
    switch (label.toLowerCase()) {
      case 'loop':
        baseColor = Colors.green;
        break;
      case 'if':
        baseColor = Colors.orange;
        break;
      default:
        baseColor = Colors.blueAccent;
    }

    final backgroundColor = baseColor.withAlpha((0.2 * 255).round());
    final borderColor = baseColor;

    return Container(
      width: 70,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : borderColor,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: borderColor, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
