import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final String level;

  const SuccessPopup({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5), // square edges
        side: const BorderSide(color: Colors.black, width: 4),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      backgroundColor: Colors.white,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Star Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 60),
                SizedBox(width: 8),
                Icon(Icons.star, color: Colors.amber, size: 60),
                SizedBox(width: 8),
                Icon(Icons.star, color: Colors.amber, size: 60),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'GREAT JOB!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _popupButton(icon: Icons.home, onTap: () => Navigator.pop(context)),
                _popupButton(icon: Icons.refresh, onTap: () => Navigator.pop(context)),
                _popupButton(icon: Icons.arrow_forward, onTap: () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _popupButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
