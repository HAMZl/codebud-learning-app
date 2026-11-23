/// Build-time configuration.
///
/// Override the API URL when running against a local backend:
///
///     flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://codebud-learning-app.onrender.com',
  );

  /// Render's free tier can take a while to wake up from sleep.
  static const Duration requestTimeout = Duration(seconds: 45);

  /// Shown on the About section of parent settings. Keep in step with pubspec.yaml.
  static const String version = '1.1.0';
}
