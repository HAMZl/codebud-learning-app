import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/app_scope.dart';
import '../services/settings.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/parental_gate.dart';
import '../widgets/settings_widgets.dart';

/// Settings a child can change: sound and how the game plays. Account settings are behind a parental gate.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openParentArea(BuildContext context) async {
    if (await showParentalGate(context) && context.mounted) {
      await Navigator.pushNamed(context, Routes.parentSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: controller,
        builder: (context, s, _) => SettingsList(
          children: [
            const SettingsSection(title: 'Sound', icon: Icons.music_note),
            SettingsCard(children: [
              SwitchListTile(
                key: const Key('sound-switch'),
                secondary: Icon(s.soundEnabled ? Icons.volume_up : Icons.volume_off),
                title: const Text('Sound effects'),
                subtitle: const Text('Taps, steps, bumps and cheers'),
                value: s.soundEnabled,
                onChanged: (v) => controller.update((x) => x.copyWith(soundEnabled: v)),
              ),
              ListTile(
                enabled: s.soundEnabled,
                leading: const Icon(Icons.graphic_eq),
                title: const Text('Volume'),
                subtitle: Slider(
                  key: const Key('volume-slider'),
                  value: s.volume,
                  divisions: 10,
                  label: '${(s.volume * 100).round()}%',
                  onChanged: s.soundEnabled ? (v) => controller.update((x) => x.copyWith(volume: v)) : null,
                  // Play a chime when the slider is let go, so the new volume can be heard.
                  onChangeEnd: (_) => scope.sounds.play(Sfx.star),
                ),
              ),
            ]),
            const SettingsSection(title: 'Playing', icon: Icons.sports_esports),
            SettingsCard(children: [
              ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text('Robot speed'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<RobotSpeed>(
                    key: const Key('speed'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: RobotSpeed.slow, label: Text('Slow')),
                      ButtonSegment(value: RobotSpeed.normal, label: Text('Normal')),
                      ButtonSegment(value: RobotSpeed.fast, label: Text('Fast')),
                    ],
                    selected: {s.robotSpeed},
                    onSelectionChanged: (v) => controller.update((x) => x.copyWith(robotSpeed: v.first)),
                  ),
                ),
              ),
              SwitchListTile(
                key: const Key('hints-switch'),
                secondary: const Icon(Icons.lightbulb_outline),
                title: const Text('Show hints'),
                subtitle: const Text('Explain what went wrong when the robot misses the star'),
                value: s.showHints,
                onChanged: (v) => controller.update((x) => x.copyWith(showHints: v)),
              ),
            ]),
            const SettingsSection(title: 'Grown-ups', icon: Icons.family_restroom),
            SettingsCard(children: [
              ListTile(
                key: const Key('parent-settings'),
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: const Text('Parent settings'),
                subtitle: const Text('Profile, progress, password and log out'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openParentArea(context),
              ),
            ]),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => controller.update((_) => const AppSettings()),
                child: const Text('Restore default settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
