import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final String level;
  final int earnedStars;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onCategorySelect;

  const SuccessPopup({
    super.key,
    required this.level,
    required this.earnedStars,
    required this.onRetry,
    required this.onNext,
    required this.onCategorySelect,
  });

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
              level,
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Star Row (dynamic)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star,
                    color: i < earnedStars
                        ? Colors.amber
                        : Colors.grey.shade300,
                    size: 60,
                  ),
                ),
              ),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _popupButton(
                  icon: Icons.home,
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                _popupButton(icon: Icons.refresh, onTap: onRetry),
                _popupButton(icon: Icons.arrow_forward, onTap: onNext),
                _popupButton(icon: Icons.dashboard, onTap: onCategorySelect),
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
