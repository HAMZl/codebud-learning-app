import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import 'session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// True while this page is the one on screen (not covered, and not being removed).
  bool get _isVisible => mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  String? _childName;
  Map<String, CategoryProgress> _progress = const {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final name = await scope.auth.childName();
    if (mounted) setState(() => _childName = name);
    try {
      final progress = await scope.puzzles.fetchProgress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      // The progress badges are optional. Only an expired session needs handling.
      if (mounted && e.isUnauthorized) await handleApiError(context, e);
    }
  }

  Future<void> _openCategory(PuzzleCategory category) async {
    await Navigator.pushNamed(context, Routes.category, arguments: category.id);
    if (_isVisible) _load(); // refresh the stars when the player comes back
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, Routes.settings);
    if (_isVisible) _load(); // the child's name or progress may have changed
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _childName == null ? 'Hello, Buddy!' : 'Hello, $_childName!';
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeBud', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipOval(child: Image.asset('lib/assets/images/homepage_logo.png', fit: BoxFit.cover)),
        ),
        actions: [
          const MuteButton(),
          IconButton(
            key: const Key('open-settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  '$greeting What will you\nlearn today?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      for (final c in PuzzleCategory.all)
                        _CategoryCard(category: c, progress: _progress[c.id], onTap: () => _openCategory(c)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.progress, required this.onTap});

  final PuzzleCategory category;
  final CategoryProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.5),
                radius: 28,
                child: Icon(category.icon, size: 28, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(category.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (progress != null && progress!.maxStars > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text('${progress!.stars} / ${progress!.maxStars}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
