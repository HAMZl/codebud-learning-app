import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'puzzle_service.dart';
import 'sound_service.dart';
import 'token_storage.dart';

/// Gives every screen the app's services. Tests can wrap widgets in an
/// AppScope that holds fakes.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.puzzles,
    required this.sounds,
    required super.child,
  });

  factory AppScope.production({Key? key, required Widget child}) {
    final api = ApiClient(tokens: SecureTokenStorage());
    return AppScope(
      key: key,
      auth: AuthService(api),
      puzzles: PuzzleService(api),
      sounds: AudioSoundService(),
      child: child,
    );
  }

  final AuthService auth;
  final PuzzleService puzzles;
  final SoundService sounds;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth || puzzles != oldWidget.puzzles || sounds != oldWidget.sounds;
}
