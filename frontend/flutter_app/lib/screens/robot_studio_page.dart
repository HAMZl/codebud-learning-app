import 'package:flutter/material.dart';

import '../models/family.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/robot_avatar.dart';
import 'session.dart';

/// Where a child makes the robot their own: a character, a colour and a nickname.
class RobotStudioPage extends StatefulWidget {
  const RobotStudioPage({super.key});

  @override
  State<RobotStudioPage> createState() => _RobotStudioPageState();
}

class _RobotStudioPageState extends State<RobotStudioPage> {
  Child? _child;
  late RobotLook _look;
  final _nickname = TextEditingController();
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_child == null) {
      if (redirectIfNoChild(context)) return;
      _child = AppScope.of(context).auth.activeChild;
      _look = _child!.robot;
      _nickname.text = _look.nickname;
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _change(RobotLook look) {
    AppScope.of(context).sounds.play(Sfx.tap);
    setState(() => _look = look);
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    final look = _look.copyWith(nickname: _nickname.text.trim());
    setState(() => _saving = true);
    try {
      await scope.auth.updateRobot(_child!, look);
      if (!mounted) return;
      scope.sounds.play(Sfx.success);
      showToast(context, '${look.displayName} is ready to go!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) await handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('My robot')),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _preview(child),
                  const SizedBox(height: 24),
                  _section(Icons.face_retouching_natural, 'Pick a character'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final c in RobotCharacter.all)
                        _Choice(
                          key: Key('character-${c.id}'),
                          selected: _look.character == c.id,
                          color: _look.colorValue,
                          onTap: () => _change(_look.copyWith(character: c.id)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon, size: 40, color: _look.colorValue),
                              const SizedBox(height: 4),
                              Text(c.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _section(Icons.palette, 'Pick a colour'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final c in RobotColor.all)
                        Tooltip(
                          message: c.label,
                          child: InkWell(
                            key: Key('color-${c.id}'),
                            customBorder: const CircleBorder(),
                            onTap: () => _change(_look.copyWith(color: c.id)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: _look.color == c.id ? c.color : Colors.black12,
                                    spreadRadius: _look.color == c.id ? 4 : 1,
                                    blurRadius: _look.color == c.id ? 0 : 4,
                                  ),
                                ],
                              ),
                              child: _look.color == c.id
                                  ? Icon(Icons.check, color: Colors.white, semanticLabel: '${c.label}, picked')
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _section(Icons.badge, 'Give it a nickname'),
                  TextField(
                    key: const Key('nickname'),
                    controller: _nickname,
                    maxLength: RobotLook.maxNickname,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _look.characterInfo.label,
                      prefixIcon: const Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    key: const Key('save-robot'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save my robot'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(Child child) {
    final look = _look.copyWith(nickname: _nickname.text.trim());
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('${look.character}-${look.color}'),
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, scale, avatar) => Transform.scale(scale: scale, child: avatar),
          child: RobotAvatar(look: look, size: 140),
        ),
        const SizedBox(height: 12),
        Text(
          look.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: look.colorValue),
        ),
        Text('${child.name}’s buddy', style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
      ],
    );
  }

  Widget _section(IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.selected, required this.color, required this.onTap, required this.child});

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: selected ? 3 : 1.5),
          ),
          child: Semantics(selected: selected, child: child),
        ),
      );
}
