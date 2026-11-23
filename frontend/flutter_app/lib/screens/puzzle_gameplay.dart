import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../game/engine.dart';
import '../models/category.dart';
import '../models/command.dart';
import '../models/point.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/command_block_widget.dart';
import '../widgets/mute_button.dart';
import '../widgets/program_block.dart';
import '../widgets/puzzle_grid.dart';
import '../widgets/success_popup_widget.dart';
import 'session.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.puzzleId, this.stepDuration = AppConfig.stepDuration});

  final String puzzleId;
  final Duration stepDuration;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  Puzzle? _puzzle;
  bool _loadFailed = false;
  bool _started = false;

  final List<CommandItem> _program = [];
  CommandItem? _selected;
  Point? _robot;
  bool _running = false;

  final _programScroll = ScrollController();

  SoundService get _sounds => AppScope.of(context).sounds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load once. didChangeDependencies also fires on things like window resizes.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _programScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final puzzle = await AppScope.of(context).puzzles.fetchPuzzle(widget.puzzleId);
      if (!mounted) return;
      setState(() {
        _puzzle = puzzle;
        _robot = puzzle.start;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
      await handleApiError(context, e);
    }
  }

  // --- editing the program --------------------------------------------------------

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
        _robot = _puzzle?.start;
      });

  // --- running ----------------------------------------------------------------------

  Future<void> _play() async {
    final puzzle = _puzzle;
    if (puzzle == null || _running || _program.isEmpty) return;

    final result = GameEngine.run(puzzle, _program);
    setState(() {
      _running = true;
      _selected = null;
      _robot = puzzle.start;
    });

    for (final cell in result.path.skip(1)) {
      await Future.delayed(widget.stepDuration);
      if (!mounted) return;
      setState(() => _robot = cell);
      _sounds.play(Sfx.step);
    }
    await Future.delayed(widget.stepDuration);
    if (!mounted) return;

    if (result.solved) {
      _sounds.play(Sfx.success);
      await _celebrate(puzzle, result);
    } else {
      _sounds.play(result.status == RunStatus.incomplete ? Sfx.tryAgain : Sfx.bump);
      await _showHint(result);
      if (mounted) setState(() => _robot = puzzle.start);
    }
    if (mounted) setState(() => _running = false);
  }

  Future<void> _celebrate(Puzzle puzzle, RunResult result) async {
    var stars = result.stars;
    try {
      stars = (await AppScope.of(context).puzzles.saveProgress(puzzle, _program)).stars;
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
        sounds: _sounds,
        onHome: () => Navigator.of(context).popUntil(ModalRoute.withName(Routes.home)),
        onRetry: () {
          Navigator.pop(dialogContext);
          setState(() => _robot = puzzle.start);
        },
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

  // --- UI ----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return Scaffold(
      appBar: AppBar(
        title: Text(puzzle?.title ?? ''),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [MuteButton()],
      ),
      body: puzzle == null
          ? Center(
              child: _loadFailed
                  ? ElevatedButton.icon(
                      onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again'))
                  : const CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      PuzzleGrid(
                        puzzle: puzzle,
                        robot: _robot ?? puzzle.start,
                        blocksUsed: GameEngine.countBlocks(_program),
                        starPreview:
                            _program.isEmpty ? 0 : GameEngine.starsFor(GameEngine.countBlocks(_program), puzzle.par),
                        stepDuration: widget.stepDuration * 0.7,
                      ),
                      _palette(PuzzleCategory.byId(puzzle.category)),
                      const SizedBox(height: 12),
                      _programArea(),
                      const SizedBox(height: 12),
                      _controls(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
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
        height: 124,
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
