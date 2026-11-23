import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';

/// Shows an error, or sends the player to log in again if the session has expired.
Future<void> handleApiError(BuildContext context, Object error) async {
  if (error is ApiException && error.isUnauthorized) {
    await AppScope.of(context).auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false, arguments: 'Please log in again.');
    return;
  }
  final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
}
