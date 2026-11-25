import 'package:flutter/material.dart';

import '../game/engine.dart';
import '../models/category.dart';
import '../models/command.dart';
import '../models/family.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import '../widgets/puzzle_playground.dart';
import '../widgets/success_popup_widget.dart';
import 'session.dart';

/// Loads a puzzle from the API, lets the child play it, and saves the result.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.puzzleId, this.stepDuration, this.initialProgram});

  final String puzzleId;

  /// Overrides the robot speed setting (used by tests).
  final Duration? stepDuration;

  /// Blocks to start with (used to generate screenshots).
  final List<CommandItem>? initialProgram;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  Puzzle? _puzzle;
  bool _loadFailed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load once. didChangeDependencies also fires on things like window resizes.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final puzzle = await AppScope.of(context).puzzles.fetchPuzzle(widget.puzzleId);
      if (mounted) setState(() => _puzzle = puzzle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
      await handleApiError(context, e);
    }
  }

  Future<void> _onSolved(RunResult result, List<CommandItem> program) async {
    final puzzle = _puzzle!;
    final scope = AppScope.of(context);
    var stars = result.stars;
    try {
      stars = (await scope.puzzles.saveProgress(puzzle, program)).stars;
    } on ApiException catch (e) {
      // Celebrate anyway, using the stars computed locally. Only an expired session needs attention.
      if (e.isUnauthorized && mounted) {
        await handleApiError(context, e);
        return;
      }
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessPopup(
        title: puzzle.title,
        earnedStars: stars,
        sounds: scope.sounds,
        robot: scope.auth.activeChild?.robot,
        onHome: () => Navigator.of(context).popUntil(ModalRoute.withName(Routes.home)),
        onRetry: () => Navigator.pop(dialogContext),
        onLevels: () {
          Navigator.pop(dialogContext);
          Navigator.pop(context);
        },
        onNext: puzzle.next == null
            ? null
            : () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, Routes.puzzle, arguments: puzzle.next!.id);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return Scaffold(
      appBar: AppBar(
        title: Text(puzzle?.title ?? ''),
        backgroundColor: PuzzleCategory.byId(puzzle?.category ?? '').color,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        actions: const [MuteButton()],
      ),
      body: puzzle == null
          ? Center(
              child: _loadFailed
                  ? ElevatedButton.icon(
                      onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again'))
                  : const CircularProgressIndicator(),
            )
          : AppBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: PuzzlePlayground(
                      puzzle: puzzle,
                      robot: AppScope.of(context).auth.activeChild?.robot ?? const RobotLook(),
                      onSolved: _onSolved,
                      stepDuration: widget.stepDuration,
                      initialProgram: widget.initialProgram,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
