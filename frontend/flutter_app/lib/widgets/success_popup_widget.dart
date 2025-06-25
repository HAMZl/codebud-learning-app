import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final String level;

  const SuccessPopup({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // Square corners
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: SizedBox(
        width: 260,
        height: 260, // Make it a square
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              // ⭐️ Star Row
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 36),
                  SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 36),
                  SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 36),
                ],
              ),

              const Text(
                'GREAT JOB!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _popupButton(icon: Icons.home, onTap: () {
                    Navigator.pop(context);
                  }),
                  _popupButton(icon: Icons.refresh, onTap: () {
                    Navigator.pop(context);
                  }),
                  _popupButton(icon: Icons.arrow_forward, onTap: () {
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}