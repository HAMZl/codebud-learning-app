import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'made_by.dart';

/// The shared frame of the log-in and sign-up pages: a bright background, the logo,
/// a title, and the form on a white card.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.subtitle, required this.child, this.maxWidth = 460});

  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: Color(0x220D9488), blurRadius: 20, offset: Offset(0, 6)),
                      ]),
                      child: ClipOval(child: Image.asset('lib/assets/images/homepage_logo.png', height: 84, width: 84)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x1A1B2A3A), blurRadius: 30, offset: Offset(0, 12))],
                      ),
                      child: child,
                    ),
                    const SizedBox(height: 24),
                    const MadeByCredit(color: AppColors.inkSoft, linkColor: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A red message box for form errors.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDA4AF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Color(0xFF9F1239), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
