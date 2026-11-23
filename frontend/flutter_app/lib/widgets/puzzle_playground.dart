import 'package:flutter/material.dart';

import '../game/engine.dart';
import '../models/category.dart';
import '../models/command.dart';
import '../models/point.dart';
import '../models/puzzle.dart';
import '../services/app_scope.dart';
import '../services/settings.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'command_block_widget.dart';
import 'program_block.dart';
import 'puzzle_grid.dart';

/// The playable part of a puzzle: board, block palette, program strip and controls.
///
/// It needs no network, so the real puzzle screen and the landing page demo both use it.
/// What happens on a win is up to the parent, through [onSolved].
class PuzzlePlayground extends StatefulWidget {
  const PuzzlePlayground({
    super.key,
    required this.puzzle,
    required this.onSolved,
    this.stepDuration,
    this.initialProgram,
    this.compact = false,
  });

  final Puzzle puzzle;

  /// Called when a run reaches the star. The robot goes back to the start once this completes.
  final Future<void> Function(RunResult result, List<CommandItem> program) onSolved;

  /// Overrides the robot speed setting (used by tests).
  final Duration? stepDuration;

  /// Start with these blocks already placed, e.g. on the landing page.
  final List<CommandItem>? initialProgram;

  /// A smaller layout for embedding in other pages.
  final bool compact;

  @override
  State<PuzzlePlayground> createState() => PuzzlePlaygroundState();
}

class PuzzlePlaygroundState extends State<PuzzlePlayground> {
  late final List<CommandItem> _program = [...?widget.initialProgram];
  CommandItem? _selected;
  late Point _robot = widget.puzzle.start;
  bool _running = false;
  final _programScroll = ScrollController();

  AppScope get _scope => AppScope.of(context);
  SoundService get _sounds => _scope.sounds;
  AppSettings get _settings => _scope.settings.value;
  Duration get _step => widget.stepDuration ?? _settings.robotSpeed.step;

  @override
  void didUpdateWidget(PuzzlePlayground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzle.id != widget.puzzle.id) {
      _program.clear();
      _selected = null;
      _robot = widget.puzzle.start;
    }
  }

  @override
  void dispose() {
    _programScroll.dispose();
    super.dispose();
  }

  // --- editing ------------------------------------------------------------------------

  void _addBlock(String type) {
    if (_running) return;
    _sounds.play(Sfx.tap);
    setState(() => _program.add(CommandItem(type: type)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_programScroll.hasClients) {
        _programScroll.animateTo(
          _programScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteSelected() {
    final item = _selected;
    if (item == null) return;
    setState(() {
      removeBlock(_program, item);
      _selected = null;
    });
  }

  void _clear() => setState(() {
        _program.clear();
        _selected = null;
        _robot = widget.puzzle.start;
      });

  // --- running ------------------------------------------------------------------------

  Future<void> _play() async {
    if (_running || _program.isEmpty) return;
    final puzzle = widget.puzzle;
    final result = GameEngine.run(puzzle, _program);
    setState(() {
      _running = true;
      _selected = null;
      _robot = puzzle.start;
    });

    for (final cell in result.path.skip(1)) {
      await Future.delayed(_step);
      if (!mounted) return;
      setState(() => _robot = cell);
      _sounds.play(Sfx.step);
    }
    await Future.delayed(_step);
    if (!mounted) return;

    if (result.solved) {
      _sounds.play(Sfx.success);
      await widget.onSolved(result, List.unmodifiable(_program));
    } else {
      _sounds.play(result.status == RunStatus.incomplete ? Sfx.tryAgain : Sfx.bump);
      if (_settings.showHints) {
        await _showHint(result);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
    if (mounted) {
      setState(() {
        _running = false;
        _robot = puzzle.start;
      });
    }
  }

  Future<void> _showHint(RunResult result) {
    final icon = switch (result.status) {
      RunStatus.wall => Icons.border_outer,
      RunStatus.obstacle => Icons.terrain,
      _ => Icons.star_border,
    };
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icon, size: 48, color: AppColors.primary),
        content: Text(result.hint ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // --- UI -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    final blocks = GameEngine.countBlocks(_program);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PuzzleGrid(
          puzzle: puzzle,
          robot: _robot,
          blocksUsed: blocks,
          starPreview: _program.isEmpty ? 0 : GameEngine.starsFor(blocks, puzzle.par),
          stepDuration: _step * 0.7,
          maxBoardSize: widget.compact ? 280 : 420,
        ),
        _palette(PuzzleCategory.byId(puzzle.category)),
        const SizedBox(height: 12),
        _programArea(),
        const SizedBox(height: 12),
        _controls(),
      ],
    );
  }

  Widget _palette(PuzzleCategory category) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [for (final type in category.blocks) DraggableBlock(type: type, onTap: () => _addBlock(type))],
        ),
      );

  Widget _programArea() => Container(
        width: double.infinity,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) => !_running,
          onAcceptWithDetails: (d) => _addBlock(d.data),
          builder: (context, candidates, _) => Container(
            decoration: BoxDecoration(
              color: candidates.isNotEmpty ? AppColors.primaryLight : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _program.isEmpty
                ? const Center(child: Icon(Icons.touch_app, size: 40, color: Colors.black26))
                : Scrollbar(
                    controller: _programScroll,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _programScroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: _program.length,
                      itemBuilder: (context, i) => Center(
                        child: ProgramBlock(
                          item: _program[i],
                          selected: _selected,
                          enabled: !_running,
                          onSelect: (item) => setState(() => _selected = identical(_selected, item) ? null : item),
                          onChanged: () {
                            _sounds.play(Sfx.tap);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );

  Widget _controls() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            key: const Key('play'),
            onPressed: _running || _program.isEmpty ? null : _play,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
          ElevatedButton.icon(
            key: const Key('delete'),
            onPressed: _running || _selected == null ? null : _deleteSelected,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            icon: const Icon(Icons.backspace_outlined),
            label: const Text('Delete'),
          ),
          ElevatedButton.icon(
            key: const Key('clear'),
            onPressed: _running || _program.isEmpty ? null : _clear,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear'),
          ),
        ],
      );
}
