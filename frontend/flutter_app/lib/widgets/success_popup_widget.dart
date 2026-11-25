import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/family.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'robot_avatar.dart';

class SuccessPopup extends StatefulWidget {
  const SuccessPopup({
    super.key,
    required this.title,
    required this.earnedStars,
    required this.onHome,
    required this.onRetry,
    required this.onLevels,
    this.onNext,
    this.sounds,
    this.robot,
  });

  /// The child's robot, which cheers along. Null on the landing page demo.
  final RobotLook? robot;

  final String title;
  final int earnedStars;
  final VoidCallback onHome;
  final VoidCallback onRetry;
  final VoidCallback onLevels;

  /// Null on the last puzzle of a category.
  final VoidCallback? onNext;

  /// If set, a chime plays as each earned star pops in.
  final SoundService? sounds;

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup> {
  static const _cheers = [
    'GREAT JOB!',
    'WELL DONE!',
    'YOU DID IT!',
    'AWESOME!',
    'FANTASTIC!',
    'SUPERB!',
    'NAILED IT!',
    'EXCELLENT!',
  ];

  // Picked once, so the text doesn't change on a rebuild.
  final _cheer = _cheers[Random().nextInt(_cheers.length)];
  final _timers = <Timer>[];

  static Duration _starDelay(int i) => Duration(milliseconds: 500 + i * 250);

  @override
  void initState() {
    super.initState();
    final sounds = widget.sounds;
    if (sounds != null) {
      for (var i = 0; i < widget.earnedStars; i++) {
        // Chime when each star's pop-in animation lands.
        _timers.add(Timer(_starDelay(i) * 0.6, () => sounds.play(Sfx.star)));
      }
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.sunshine, width: 4),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.robot != null) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, v, avatar) => Transform.scale(scale: v, child: avatar),
                  child: RobotAvatar(look: widget.robot!, size: 72),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final earned = i < widget.earnedStars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.elasticOut,
                      duration: _starDelay(i),
                      builder: (context, value, child) => Transform.scale(scale: value, child: child),
                      child: Icon(Icons.star, color: earned ? AppColors.star : Colors.grey.shade300, size: 60),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              FittedBox(
                child: Text(
                  _cheer,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _button(Icons.home, 'Home', widget.onHome),
                  _button(Icons.refresh, 'Try again', widget.onRetry),
                  _button(Icons.grid_view, 'Levels', widget.onLevels),
                  if (widget.onNext != null) _button(Icons.arrow_forward, 'Next', widget.onNext!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 30, semanticLabel: tooltip),
            ),
          ),
        ),
      );
}
