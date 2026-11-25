import 'package:flutter/material.dart';

import '../data/demo_puzzles.dart';
import '../models/command.dart';
import '../theme/app_theme.dart';
import 'command_block_widget.dart';
import 'program_block.dart';
import 'puzzle_grid.dart';

/// A phone-shaped frame around a screenshot or live widget.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.width = 240});

  final Widget child;
  final double width;

  /// Screenshots are rendered at 390 x 844 (a typical phone).
  static const aspectRatio = 390 / 844;

  @override
  Widget build(BuildContext context) {
    final radius = width * 0.12;
    return Container(
      width: width,
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F24),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.8),
        child: AspectRatio(aspectRatio: aspectRatio, child: ColoredBox(color: Colors.white, child: child)),
      ),
    );
  }
}

/// A screenshot from assets/screenshots, with a caption below it.
class ScreenshotCard extends StatelessWidget {
  const ScreenshotCard({super.key, required this.asset, required this.caption, this.width = 220});

  final String asset;
  final String caption;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhoneFrame(
          width: width,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            // Fall back to a plain panel if the screenshots haven't been generated yet.
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.black26)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: width,
          child: Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// A static sample: a board and the program that solves it, drawn with the real game widgets.
class ConceptPreview extends StatelessWidget {
  const ConceptPreview({super.key, required this.demo});

  final DemoPuzzle demo;

  @override
  Widget build(BuildContext context) {
    final program = demo.solution();
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PuzzleGrid(
            puzzle: demo.puzzle,
            robot: demo.puzzle.start,
            blocksUsed: 0,
            starPreview: 0,
            showHeader: false,
            maxBoardSize: 200,
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (final b in program)
                    ProgramBlock(item: b, selected: null, onSelect: (_) {}, onChanged: () {}, enabled: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rounded label, e.g. "Ages 4-7".
class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.label, this.color = AppColors.primary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      );
}

/// A row of block icons, used to illustrate "drag blocks".
///
/// It uses the small palette squares in a single row that scales down to fit, so it
/// never grows taller than the space it is given.
class BlockStrip extends StatelessWidget {
  const BlockStrip({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in [...BlockType.moves, BlockType.loop, BlockType.ifBlock]) CommandBlock(type: t, size: 46),
            ],
          ),
        ),
      );
}
