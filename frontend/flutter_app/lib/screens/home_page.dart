import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/family.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import '../widgets/robot_avatar.dart';
import 'session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// True while this page is the one on screen (not covered, and not being removed).
  bool get _isVisible => mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  Map<String, CategoryProgress> _progress = const {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      if (!redirectIfNoChild(context)) _load();
    }
  }

  Future<void> _load() async {
    try {
      final progress = await AppScope.of(context).puzzles.fetchProgress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      // The progress badges are optional. Only an expired session needs handling.
      if (mounted && e.isUnauthorized) await handleApiError(context, e);
    }
  }

  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (_isVisible) _load(); // refresh the stars when the player comes back
  }

  void _switchPlayer() {
    AppScope.of(context).auth.clearActiveChild();
    Navigator.pushNamedAndRemoveUntil(context, Routes.profiles, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final child = auth.activeChild;
        if (child == null) return const Scaffold(body: SizedBox.shrink());
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('CodeBud', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipOval(child: Image.asset('lib/assets/images/homepage_logo.png', fit: BoxFit.cover)),
            ),
            actions: [
              const MuteButton(),
              IconButton(
                key: const Key('switch-player'),
                tooltip: 'Switch player',
                icon: const Icon(Icons.switch_account),
                onPressed: _switchPlayer,
              ),
              IconButton(
                key: const Key('open-settings'),
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: () => _open(Routes.settings),
              ),
            ],
          ),
          body: AppBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _Greeting(child: child, onCustomise: () => _open(Routes.robot)),
                      const SizedBox(height: 20),
                      const Text(
                        'What will you learn today?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 16),
                      for (final c in PuzzleCategory.all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CategoryCard(
                            category: c,
                            progress: _progress[c.id],
                            onTap: () => _open(Routes.category, arguments: c.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.child, required this.onCustomise});
  final Child child;
  final VoidCallback onCustomise;

  @override
  Widget build(BuildContext context) {
    final color = child.robot.colorValue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          GestureDetector(onTap: onCustomise, child: RobotAvatar(look: child.robot, size: 84)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${child.name}!',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
                Text(
                  '${child.robot.displayName} is ready to explore.',
                  style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  key: const Key('customise-robot'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onCustomise,
                  icon: const Icon(Icons.palette, size: 18),
                  label: const Text('My robot', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
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
    final p = progress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('category-${category.id}'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.lerp(color, Colors.white, 0.15)!, color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                radius: 32,
                child: Icon(category.icon, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      category.tagline,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    if (p != null && p.maxStars > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: p.stars / p.maxStars,
                          minHeight: 8,
                          color: AppColors.sunshine,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (p != null && p.maxStars > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: AppColors.star),
                      const SizedBox(width: 4),
                      Text('${p.stars} / ${p.maxStars}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
