import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

/// Asks for the account password before opening anything parents-only.
///
/// The password is checked by the server, which hands back a short-lived parent
/// token ([AuthService.unlockParent]). Every parent-only request needs that token,
/// so a child can't get around the check by tapping elsewhere in the app.
///
/// Returns true once parent settings are unlocked. If they are already unlocked, no
/// question is asked.
Future<bool> showParentGate(BuildContext context) async {
  final auth = AppScope.of(context).auth;
  if (auth.isParentUnlocked) return true;
  final result =
      await showDialog<bool>(context: context, builder: (_) => _ParentGateDialog(scope: AppScope.of(context)));
  return result ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.scope});
  final AppScope scope;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _password = TextEditingController();
  bool _checking = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.scope.auth.unlockParent(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.statusCode == 403 ? 'That password isn’t right. Try again.' : e.message);
      _password.clear();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.lock_outline, size: 32, color: AppColors.primary),
      ),
      title: const Text('Grown-ups only'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the password you use to log in to CodeBud.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('gate-password'),
              controller: _password,
              autofocus: true,
              obscureText: _obscure,
              enabled: !_checking,
              onSubmitted: (_) => _check(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.key),
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('gate-submit'),
          onPressed: _checking ? null : _check,
          child: _checking
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
