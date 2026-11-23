import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How fast the robot moves when a program runs.
enum RobotSpeed {
  slow(Duration(milliseconds: 750)),
  normal(Duration(milliseconds: 450)),
  fast(Duration(milliseconds: 220));

  const RobotSpeed(this.step);
  final Duration step;
}

/// Device settings. They are stored on this device, not on the account, so
/// each tablet or browser keeps its own.
@immutable
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.volume = 0.8,
    this.robotSpeed = RobotSpeed.normal,
    this.showHints = true,
  });

  final bool soundEnabled;

  /// From 0.0 to 1.0.
  final double volume;
  final RobotSpeed robotSpeed;

  /// Show a hint dialog when a program doesn't reach the star.
  final bool showHints;

  AppSettings copyWith({bool? soundEnabled, double? volume, RobotSpeed? robotSpeed, bool? showHints}) => AppSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        volume: volume ?? this.volume,
        robotSpeed: robotSpeed ?? this.robotSpeed,
        showHints: showHints ?? this.showHints,
      );

  Map<String, Object> toMap() => {
        'soundEnabled': soundEnabled,
        'volume': volume,
        'robotSpeed': robotSpeed.name,
        'showHints': showHints,
      };

  factory AppSettings.fromMap(Map<String, Object?> m) {
    const d = AppSettings();
    return AppSettings(
      soundEnabled: m['soundEnabled'] as bool? ?? d.soundEnabled,
      volume: ((m['volume'] as num?)?.toDouble() ?? d.volume).clamp(0.0, 1.0),
      robotSpeed: RobotSpeed.values.firstWhere((s) => s.name == m['robotSpeed'], orElse: () => d.robotSpeed),
      showHints: m['showHints'] as bool? ?? d.showHints,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.soundEnabled == soundEnabled &&
      other.volume == volume &&
      other.robotSpeed == robotSpeed &&
      other.showHints == showHints;

  @override
  int get hashCode => Object.hash(soundEnabled, volume, robotSpeed, showHints);
}

/// Where settings are saved. It is an interface so tests can use [MemorySettingsStore].
abstract class SettingsStore {
  Future<Map<String, Object?>> load();
  Future<void> save(Map<String, Object> values);
}

class PrefsSettingsStore implements SettingsStore {
  static const _prefix = 'settings.';

  @override
  Future<Map<String, Object?>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix)))
        key.substring(_prefix.length): prefs.get(key),
    };
  }

  @override
  Future<void> save(Map<String, Object> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final MapEntry(:key, :value) in values.entries) {
      switch (value) {
        case final bool v:
          await prefs.setBool('$_prefix$key', v);
        case final double v:
          await prefs.setDouble('$_prefix$key', v);
        case final String v:
          await prefs.setString('$_prefix$key', v);
      }
    }
  }
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object?>? initial]) : values = {...?initial};
  final Map<String, Object?> values;

  @override
  Future<Map<String, Object?>> load() async => values;

  @override
  Future<void> save(Map<String, Object> v) async => values.addAll(v);
}

/// Holds the current settings and saves every change. Widgets listen to it.
class SettingsController extends ValueNotifier<AppSettings> {
  SettingsController(this._store) : super(const AppSettings());

  final SettingsStore _store;

  Future<void> load() async {
    try {
      value = AppSettings.fromMap(await _store.load());
    } catch (e) {
      debugPrint('Could not load settings: $e'); // keep the defaults
    }
  }

  Future<void> update(AppSettings Function(AppSettings s) change) async {
    value = change(value);
    try {
      await _store.save(value.toMap());
    } catch (e) {
      debugPrint('Could not save settings: $e');
    }
  }
}
