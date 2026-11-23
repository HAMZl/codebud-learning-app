import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/settings.dart';

/// A speaker icon that turns sound effects on and off. It's a shortcut for the setting in Settings.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settings,
      builder: (context, s, _) => IconButton(
        key: const Key('mute'),
        tooltip: s.soundEnabled ? 'Sound off' : 'Sound on',
        icon: Icon(s.soundEnabled ? Icons.volume_up : Icons.volume_off),
        onPressed: () => settings.update((v) => v.copyWith(soundEnabled: !v.soundEnabled)),
      ),
    );
  }
}
