import 'package:flutter/material.dart';

class CommandBlock extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const CommandBlock({super.key, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.black,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Center(child: Icon(icon, size: 32)),
    );
  }
}
