import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

/// Shows an error, or sends the player to log in again if the session has expired.
Future<void> handleApiError(BuildContext context, Object error) async {
  if (error is ApiException && error.isUnauthorized) {
    await AppScope.of(context).auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false, arguments: 'Please log in again.');
    return;
  }
  final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
  showToast(context, message, error: true);
}

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.primary),
  );
}

/// Sends the app to "Who's playing?" if no child has been picked yet, e.g. after a page reload.
/// Returns true if it did.
bool redirectIfNoChild(BuildContext context) {
  if (AppScope.of(context).auth.activeChild != null) return false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(Routes.profiles, (_) => false);
  });
  return true;
}
