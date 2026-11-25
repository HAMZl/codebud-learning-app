import 'package:flutter/material.dart';

import '../game/engine.dart';
import '../models/category.dart';
import '../models/command.dart';
import '../models/family.dart';
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
    this.robot = const RobotLook(),
  });

  final Puzzle puzzle;

  /// The playing child's robot.
  final RobotLook robot;

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

  /// Which board is on screen, and how the last run went on each one (null: not run yet).
  int _board = 0;
  late List<RunStatus?> _results = List.filled(widget.puzzle.boards.length, null);

  List<Puzzle> get _boards => widget.puzzle.boards;
  bool get _multiBoard => _boards.length > 1;
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
      _board = 0;
      _results = List.filled(widget.puzzle.boards.length, null);
      _robot = widget.puzzle.start;
    }
  }

  @override
  void dispose() {
    _programScroll.dispose();
    super.dispose();
  }

  // --- editing ------------------------------------------------------------------------

  /// The program changed, so earlier results no longer apply.
  void _forgetResults() => _results = List.filled(_boards.length, null);

  void _showBoard(int i) {
    if (_running) return;
    _sounds.play(Sfx.tap);
    setState(() {
      _board = i;
      _robot = _boards[i].start;
    });
  }

  void _addBlock(String type) {
    if (_running) return;
    _sounds.play(Sfx.tap);
    setState(() {
      _program.add(CommandItem(type: type));
      _forgetResults();
    });
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
      _forgetResults();
    });
  }

  void _clear() => setState(() {
        _program.clear();
        _selected = null;
        _forgetResults();
        _robot = _boards[_board].start;
      });

  // --- running ------------------------------------------------------------------------

  Future<void> _play() async {
    if (_running || _program.isEmpty) return;
    final puzzle = widget.puzzle;
    final result = GameEngine.runPuzzle(puzzle, _program);
    setState(() {
      _running = true;
      _selected = null;
      _forgetResults();
    });

    // Play the boards in order, up to the first one the program fails on.
    final last = result.solved ? result.boards.length - 1 : result.board;
    for (var i = 0; i <= last; i++) {
      final run = result.boards[i];
      setState(() {
        _board = i;
        _robot = _boards[i].start;
      });
      if (_multiBoard) await Future.delayed(_step);
      for (final cell in run.path.skip(1)) {
        await Future.delayed(_step);
        if (!mounted) return;
        setState(() => _robot = cell);
        _sounds.play(Sfx.step);
      }
      await Future.delayed(_step);
      if (!mounted) return;
      setState(() => _results[i] = run.status);
      if (i < last) _sounds.play(Sfx.star);
    }

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
        _robot = _boards[_board].start;
      });
    }
  }

  Future<void> _showHint(RunResult result) {
    final icon = switch (result.status) {
      RunStatus.wall => Icons.border_outer,
      RunStatus.obstacle => Icons.terrain,
      _ => Icons.star_border,
    };
    final solvedSome = _multiBoard && result.board > 0;
    final usesIf = _program.any((b) => b.type == BlockType.ifBlock || b.body.any((c) => c.type == BlockType.ifBlock));
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icon, size: 48, color: AppColors.primary),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_multiBoard) ...[
              _BoardBadge(number: result.board + 1, status: result.status),
              const SizedBox(height: 12),
            ],
            Text(result.hint ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            if (solvedSome) ...[
              const SizedBox(height: 8),
              Text(
                usesIf
                    ? 'It worked before, but the rocks are in different places on board ${result.board + 1}.'
                    : 'It worked before, but the rocks moved! Try an If block, so the robot looks first.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
              ),
            ],
          ],
        ),
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
        if (_multiBoard) _boardPicker(),
        PuzzleGrid(
          key: ValueKey('board-$_board'),
          puzzle: _boards[_board],
          robot: _robot,
          robotLook: widget.robot,
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

  /// "The rocks move!": small pictures of every board, with a tick or cross after a run.
  Widget _boardPicker() => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.violetLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_motion, color: AppColors.violet),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'The rocks move! One program must work on every board.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _boards.length; i++)
                  GestureDetector(
                    key: Key('board-thumb-$i'),
                    onTap: () => _showBoard(i),
                    child: Semantics(
                      button: true,
                      selected: i == _board,
                      label: 'Board ${i + 1}',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: i == _board ? AppColors.violet : Colors.transparent, width: 3),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            MiniBoard(puzzle: _boards[i], size: 56),
                            Positioned(
                              right: -12,
                              top: -12,
                              child: _BoardBadge(number: i + 1, status: _results[i], small: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

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
          border: Border.all(color: AppColors.primary, width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x220D9488), blurRadius: 10, offset: Offset(0, 4))],
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
                            setState(_forgetResults);
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky),
            icon: const Icon(Icons.backspace_outlined),
            label: const Text('Delete'),
          ),
          ElevatedButton.icon(
            key: const Key('clear'),
            onPressed: _running || _program.isEmpty ? null : _clear,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear'),
          ),
        ],
      );
}

/// A board number, or a tick (solved) or cross (failed) after a run.
class _BoardBadge extends StatelessWidget {
  const _BoardBadge({required this.number, required this.status, this.small = false});
  final int number;
  final RunStatus? status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final solved = status == RunStatus.success;
    final color = status == null ? AppColors.violet : (solved ? AppColors.loop : AppColors.danger);
    final size = small ? 24.0 : 36.0;
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      alignment: Alignment.center,
      child: status == null
          ? Text('$number',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: small ? 12 : 17))
          : Icon(solved ? Icons.check : Icons.close, color: Colors.white, size: size * 0.6),
    );
  }
}

/// A tiny picture of a board: rocks, the star and where the robot starts.
class MiniBoard extends StatelessWidget {
  const MiniBoard({super.key, required this.puzzle, required this.size});
  final Puzzle puzzle;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MiniBoardPainter(puzzle));
}

class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter(this.puzzle);
  final Puzzle puzzle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.gridSize;
    final cell = size.width / n;
    final gap = cell * 0.08;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final p = Point(r, c);
        final color = puzzle.obstacles.contains(p)
            ? const Color(0xFF64748B)
            : p == puzzle.goal
                ? AppColors.star
                : const Color(0xFFDDF7F1);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + gap, r * cell + gap, cell - 2 * gap, cell - 2 * gap),
          Radius.circular(cell * 0.2),
        );
        canvas.drawRRect(rect, Paint()..color = color);
      }
    }
    final s = puzzle.start;
    canvas.drawCircle(
        Offset((s.col + 0.5) * cell, (s.row + 0.5) * cell), cell * 0.34, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_MiniBoardPainter old) => old.puzzle != puzzle;
}
