import 'package:flutter/material.dart';

import '../services/app_scope.dart';

/// A speaker icon that turns sound effects on and off.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = AppScope.of(context).sounds;
    return ValueListenableBuilder<bool>(
      valueListenable: sounds.muted,
      builder: (context, muted, _) => IconButton(
        key: const Key('mute'),
        tooltip: muted ? 'Sound on' : 'Sound off',
        icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
        onPressed: () => sounds.setMuted(!muted),
      ),
    );
  }
}
