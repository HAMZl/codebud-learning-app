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
    return Container(
      width: 90,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withAlpha((0.25 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.purpleAccent,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
