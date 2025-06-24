import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final String level;

  const SuccessPopup({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level $level',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          // ⭐️ Star Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.blue, size: 32),
              Icon(Icons.star, color: Colors.blue, size: 32),
              Icon(Icons.star, color: Colors.blue, size: 32),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'GREAT JOB!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _popupButton(icon: Icons.home, onTap: () {
                Navigator.pop(context);
                // Add logic to go to home if needed
              }),
              _popupButton(icon: Icons.refresh, onTap: () {
                Navigator.pop(context);
                // Add logic to restart level
              }),
              _popupButton(icon: Icons.arrow_forward, onTap: () {
                Navigator.pop(context);
                // Add logic to go to next level
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _popupButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}