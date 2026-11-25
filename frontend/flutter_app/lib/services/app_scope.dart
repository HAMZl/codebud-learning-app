import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'puzzle_service.dart';
import 'settings.dart';
import 'sound_service.dart';
import 'token_storage.dart';

/// Gives every screen the app's services. Tests can wrap widgets in an
/// AppScope that holds fakes.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.puzzles,
    required this.settings,
    required this.sounds,
    required super.child,
  });

  /// Builds the real services. Settings are loaded before the first frame, so
  /// sound and speed are right from the start.
  static Future<AppScope> production({Key? key, required Widget child}) async {
    final api = ApiClient(tokens: SecureTokenStorage());
    final settings = SettingsController(PrefsSettingsStore());
    await settings.load();
    final auth = AuthService(api);
    return AppScope(
      key: key,
      auth: auth,
      puzzles: PuzzleService(api, auth),
      settings: settings,
      sounds: AudioSoundService(settings),
      child: child,
    );
  }

  final AuthService auth;
  final PuzzleService puzzles;
  final SettingsController settings;
  final SoundService sounds;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth ||
      puzzles != oldWidget.puzzles ||
      settings != oldWidget.settings ||
      sounds != oldWidget.sounds;
}
