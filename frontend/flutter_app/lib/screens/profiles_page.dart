import 'package:flutter/material.dart';

import '../models/family.dart';
import '../routes.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/child_dialog.dart';
import '../widgets/made_by.dart';
import '../widgets/parental_gate.dart';
import '../widgets/robot_avatar.dart';
import 'session.dart';

/// "Who's playing?": each child taps their own robot before going into the app,
/// so stars and robots are kept separately for brothers and sisters.
class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // Coming back here locks parent settings, so the next child can't wander in.
      AppScope.of(context).auth.lockParent();
      _load();
    }
  }

  Future<void> _load() async {
    final auth = AppScope.of(context).auth;
    setState(() => _failed = false);
    try {
      await auth.loadFamily();
    } catch (e) {
      if (!mounted) return;
      // After login the family is already known, so a failed refresh isn't a problem.
      if (auth.family == null) setState(() => _failed = true);
      await handleApiError(context, e);
    }
  }

  void _play(Child child) {
    AppScope.of(context).auth.selectChild(child);
    Navigator.pushReplacementNamed(context, Routes.home);
  }

  Future<void> _addChild() async {
    final auth = AppScope.of(context).auth;
    if (!await showParentGate(context) || !mounted) return;
    final child = await showChildDialog(context, save: auth.addChild);
    if (child != null && mounted) showToast(context, '${child.name} has joined the family!');
  }

  Future<void> _openParentSettings() async {
    if (await showParentGate(context) && mounted) {
      await Navigator.pushNamed(context, Routes.parentSettings);
      if (mounted) AppScope.of(context).auth.lockParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: auth,
            builder: (context, _) {
              final family = auth.family;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(family)),
                  SliverToBoxAdapter(child: _body(family)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('open-parent-settings'),
                              onPressed: family == null ? null : _openParentSettings,
                              icon: const Icon(Icons.lock_outline),
                              label: const Text('Parents'),
                            ),
                            const SizedBox(height: 16),
                            const MadeByCredit(color: AppColors.inkSoft, linkColor: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(Family? family) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
        child: Column(
          children: [
            ClipOval(child: Image.asset('lib/assets/images/homepage_logo.png', height: 64, width: 64)),
            const SizedBox(height: 16),
            const Text(
              'Who’s playing?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap your robot to start',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.inkSoft),
            ),
          ],
        ),
      );

  Widget _body(Family? family) {
    if (family == null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: _failed
              ? ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again'))
              : const CircularProgressIndicator(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final child in family.children) _ProfileTile(child: child, onTap: () => _play(child)),
              if (family.children.length < Family.maxChildren) _AddTile(onTap: _addChild),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatefulWidget {
  const _ProfileTile({required this.child, required this.onTap});
  final Child child;
  final VoidCallback onTap;

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('profile-${child.id}'),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.06 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 168,
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: child.robot.colorValue.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                    color: child.robot.colorValue.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                RobotAvatar(look: child.robot, size: 104, selected: _hover),
                const SizedBox(height: 14),
                Text(
                  child.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'with ${child.robot.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: const Key('add-child'),
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 168,
          height: 196,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.add, size: 44, color: AppColors.primary),
              ),
              SizedBox(height: 14),
              Text('Add a child',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              SizedBox(height: 2),
              Text('Grown-ups only', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ],
          ),
        ),
      );
}
