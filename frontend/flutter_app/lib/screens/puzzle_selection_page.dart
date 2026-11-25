import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'session.dart';

class PuzzleSelectionPage extends StatefulWidget {
  const PuzzleSelectionPage({super.key, required this.category});

  final PuzzleCategory category;

  @override
  State<PuzzleSelectionPage> createState() => _PuzzleSelectionPageState();
}

class _PuzzleSelectionPageState extends State<PuzzleSelectionPage> {
  /// True while this page is the one on screen (not covered, and not being removed).
  bool get _isVisible => mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  static const _cardColors = [
    Color(0xFF38BDF8),
    Color(0xFF2DD4BF),
    Color(0xFFA78BFA),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFB923C),
  ];

  List<PuzzleSummary>? _puzzles;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final puzzles = await AppScope.of(context).puzzles.fetchCategory(widget.category.id);
      if (mounted) setState(() => _puzzles = puzzles);
    } catch (e) {
      if (!mounted) return;
      setState(() => _failed = true);
      await handleApiError(context, e);
    }
  }

  /// A level unlocks once the one before it is finished, so difficulty ramps up gradually.
  bool _unlocked(int index) => index == 0 || _puzzles![index - 1].completed;

  Future<void> _open(PuzzleSummary puzzle) async {
    await Navigator.pushNamed(context, Routes.puzzle, arguments: puzzle.id);
    if (_isVisible) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.title} Puzzles'),
        backgroundColor: widget.category.color,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
      ),
      body: AppBackground(child: _body()),
    );
  }

  Widget _body() {
    if (_failed && _puzzles == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ],
        ),
      );
    }
    final puzzles = _puzzles;
    if (puzzles == null) return const Center(child: CircularProgressIndicator());
    if (puzzles.isEmpty) return const Center(child: Text('No puzzles yet.'));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: puzzles.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) => _LevelCard(
        level: i + 1,
        puzzle: puzzles[i],
        color: _cardColors[i % _cardColors.length],
        locked: !_unlocked(i),
        onTap: () => _open(puzzles[i]),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.puzzle,
    required this.color,
    required this.locked,
    required this.onTap,
  });

  final int level;
  final PuzzleSummary puzzle;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: color.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: locked ? null : onTap,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(color, Colors.white, 0.2)!, color],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: locked
                      ? const Icon(Icons.lock, size: 40, color: Colors.white)
                      : Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level $level', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        3,
                        (s) => Icon(
                          Icons.star,
                          size: 24,
                          color: s < puzzle.bestStars ? AppColors.star : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
