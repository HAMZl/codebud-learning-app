import 'package:flutter/material.dart';

import '../data/demo_puzzles.dart';
import '../game/engine.dart';
import '../models/command.dart';
import '../routes.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import '../widgets/puzzle_playground.dart';
import '../widgets/showcase.dart';
import '../widgets/success_popup_widget.dart';

/// The public front page: what CodeBud is, screenshots, and a puzzle to try without signing up.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();

  /// Card width on narrow screens. Set from the layout width in build.
  double _narrowCard = 340;
  final _demoKey = GlobalKey();
  int _demoIndex = 0;

  static const _screenshots = [
    ('assets/screenshots/home.png', 'Pick a big idea to explore'),
    ('assets/screenshots/levels.png', 'Levels unlock one by one'),
    ('assets/screenshots/puzzle.png', 'Drag picture blocks, press play'),
    ('assets/screenshots/success.png', 'Earn up to three stars'),
    ('assets/screenshots/settings.png', 'Sound and speed settings'),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToDemo() {
    final ctx = _demoKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  Future<void> _onDemoSolved(RunResult result, List<CommandItem> program) {
    final next = _demoIndex + 1 < demoPuzzles.length ? _demoIndex + 1 : null;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => SuccessPopup(
        title: demoPuzzles[_demoIndex].puzzle.title,
        earnedStars: result.stars,
        sounds: AppScope.of(context).sounds,
        onHome: () {
          Navigator.pop(dialogContext);
          _scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
        },
        onRetry: () => Navigator.pop(dialogContext),
        onLevels: () {
          Navigator.pop(dialogContext);
          Navigator.pushNamed(context, Routes.signup);
        },
        onNext: next == null
            ? null
            : () {
                Navigator.pop(dialogContext);
                setState(() => _demoIndex = next);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final phone = constraints.maxWidth < 520;
        _narrowCard = (constraints.maxWidth - 40).clamp(200.0, 340.0);
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 1,
              titleSpacing: 16,
              centerTitle: false,
              title: Row(
                children: [
                  ClipOval(child: Image.asset('lib/assets/images/homepage_logo.png', height: 32, width: 32)),
                  const SizedBox(width: 10),
                  const Flexible(
                    child:
                        Text('CodeBud', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              actions: [
                if (!phone) const MuteButton(),
                TextButton(
                  key: const Key('nav-login'),
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                  child: const Text('Log in'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  child: ElevatedButton(
                    key: const Key('nav-signup'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    onPressed: () => Navigator.pushNamed(context, Routes.signup),
                    child: const Text('Sign up'),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(child: _Section(background: const Color(0xFFFFF8EE), child: _hero(wide))),
            SliverToBoxAdapter(child: _Section(child: _howItWorks(wide))),
            SliverToBoxAdapter(child: _Section(background: const Color(0xFFF5F9FF), child: _concepts(wide))),
            SliverToBoxAdapter(child: _Section(key: _demoKey, child: _demo())),
            SliverToBoxAdapter(child: _Section(background: const Color(0xFFFFF8EE), child: _gallery())),
            SliverToBoxAdapter(child: _Section(child: _forParents(wide))),
            SliverToBoxAdapter(child: _footer()),
          ],
        );
      }),
    );
  }

  // --- sections ---------------------------------------------------------------------

  Widget _hero(bool wide) {
    final text = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Pill(icon: Icons.child_care, label: 'Ages 4–7'),
            Pill(icon: Icons.extension, label: '30 puzzles'),
            Pill(icon: Icons.visibility, label: 'No reading needed'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Coding adventures for little learners',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(fontSize: wide ? 48 : 34, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 16),
        Text(
          'Kids guide a friendly robot to the star with colourful picture blocks, '
          'and learn sequencing, loops and if-then logic along the way.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              key: const Key('hero-signup'),
              onPressed: () => Navigator.pushNamed(context, Routes.signup),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start for free'),
            ),
            OutlinedButton.icon(
              key: const Key('hero-try'),
              onPressed: _scrollToDemo,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Try a puzzle'),
            ),
          ],
        ),
      ],
    );
    final phone = PhoneFrame(
      width: wide ? 300 : 250,
      child: Image.asset(
        'assets/screenshots/puzzle.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(child: ConceptPreview(demo: demoPuzzles[1])),
      ),
    );
    return wide
        ? Row(children: [Expanded(child: text), const SizedBox(width: 48), phone])
        : Column(children: [text, const SizedBox(height: 40), phone]);
  }

  Widget _howItWorks(bool wide) {
    final steps = [
      (
        Icons.pan_tool_alt,
        '1. Drag blocks',
        'Arrows, loops and if-blocks snap together into a program.',
        const BlockStrip()
      ),
      (
        Icons.play_circle,
        '2. Press play',
        'Watch the robot follow the program step by step, with sounds for every move.',
        const Icon(Icons.smart_toy, size: 64, color: Color(0xFF2E7D32)),
      ),
      (
        Icons.star,
        '3. Earn stars',
        'Shorter programs earn more stars. Every finished level earns at least one.',
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 48, color: AppColors.star),
            Icon(Icons.star, size: 56, color: AppColors.star),
            Icon(Icons.star, size: 48, color: AppColors.star),
          ],
        ),
      ),
    ];
    return Column(
      children: [
        const _Heading(title: 'How it works', subtitle: 'Three simple steps, no reading required.'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final (icon, title, body, visual) in steps)
              _Card(
                width: wide ? 300 : _narrowCard,
                child: Column(
                  children: [
                    SizedBox(height: 96, child: Center(child: visual)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.4)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _concepts(bool wide) => Column(
        children: [
          const _Heading(
            title: 'Three big ideas',
            subtitle: 'Each one is a set of 10 levels that gets a little harder each time.',
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              for (final demo in demoPuzzles)
                _Card(
                  width: wide ? 320 : _narrowCard,
                  child: Column(
                    children: [
                      Text(demo.concept, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(demo.blurb, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      ConceptPreview(demo: demo),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _demo() {
    final demo = demoPuzzles[_demoIndex];
    return Column(
      children: [
        const _Heading(
            title: 'Try it now', subtitle: 'No account needed. Tap or drag blocks into the strip, then press Play.'),
        const SizedBox(height: 20),
        SegmentedButton<int>(
          key: const Key('demo-picker'),
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < demoPuzzles.length; i++) ButtonSegment(value: i, label: Text(demoPuzzles[i].concept)),
          ],
          selected: {_demoIndex},
          onSelectionChanged: (v) => setState(() => _demoIndex = v.first),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _Card(
            width: double.infinity,
            child: PuzzlePlayground(
              key: ValueKey(demo.puzzle.id),
              puzzle: demo.puzzle,
              onSolved: _onDemoSolved,
              compact: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _gallery() => Column(
        children: [
          const _Heading(title: 'A peek inside', subtitle: 'Big buttons, bright colours and friendly sounds.'),
          const SizedBox(height: 32),
          SizedBox(
            height: 560,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _screenshots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 24),
              itemBuilder: (_, i) => ScreenshotCard(asset: _screenshots[i].$1, caption: _screenshots[i].$2),
            ),
          ),
        ],
      );

  Widget _forParents(bool wide) {
    const points = [
      (Icons.visibility, 'Made for pre-readers', 'Play uses icons, colours and sounds. Words are only for grown-ups.'),
      (
        Icons.trending_up,
        'Gentle difficulty',
        'Each level unlocks after the one before it, so new ideas build on old ones.'
      ),
      (Icons.favorite, 'No failure penalties', 'A missed star brings a friendly hint and another try.'),
      (Icons.lock, 'Parent controls', 'Account and progress settings sit behind a grown-ups-only check.'),
    ];
    return Column(
      children: [
        const _Heading(title: 'For parents and teachers'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final (icon, title, body) in points)
              SizedBox(
                width: wide ? 250 : _narrowCard,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(icon, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.4)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, Routes.signup),
          icon: const Icon(Icons.rocket_launch),
          label: const Text('Create a free account'),
        ),
      ],
    );
  }

  Widget _footer() => Container(
        width: double.infinity,
        color: const Color(0xFF1F1F24),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            const Text('CodeBud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text('A visual coding adventure for kids', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                  child: const Text('Log in', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.signup),
                  child: const Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.child, this.background});
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: child)),
      );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.width});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: child,
      );
}
