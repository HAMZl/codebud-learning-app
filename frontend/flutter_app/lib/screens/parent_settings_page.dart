import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_widgets.dart';
import 'session.dart';

/// Account settings for grown-ups. It is reached through the parental gate on [SettingsPage].
class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  Profile? _profile;
  Map<String, CategoryProgress> _progress = const {};
  bool _loading = true;
  bool _started = false;

  AppScope get _scope => AppScope.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_scope.auth.fetchProfile(), _scope.puzzles.fetchProgress()]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile;
        _progress = results[1] as Map<String, CategoryProgress>;
      });
    } catch (e) {
      if (mounted) await handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message, {bool error = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? Colors.red : Colors.green));

  // --- actions ----------------------------------------------------------------------

  Future<void> _editProfile() async {
    final updated = await showDialog<Profile>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: _profile!, auth: _scope.auth),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
      _toast('Profile updated');
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => _PasswordDialog(auth: _scope.auth));
    if (changed == true && mounted) _toast('Password changed');
  }

  Future<void> _reset({PuzzleCategory? category}) async {
    final what = category == null ? 'all progress' : 'progress in ${category.title}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: Text('Reset $what?'),
        content: const Text('Earned stars will be erased and levels will lock again. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            key: const Key('confirm-reset'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _scope.puzzles.resetProgress(category: category?.id);
      if (!mounted) return;
      _toast('Progress reset');
      await _load();
    } catch (e) {
      if (mounted) await handleApiError(context, e);
    }
  }

  Future<void> _logout() async {
    await _scope.auth.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.launch, (_) => false);
  }

  // --- UI ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Parent settings')),
      body: _loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : SettingsList(
              children: [
                const SettingsSection(title: 'Child profile', icon: Icons.child_care),
                SettingsCard(children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (profile?.childName.isNotEmpty ?? false) ? profile!.childName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    title: Text(profile?.childName ?? ''),
                    subtitle: Text(profile?.childAge == null ? 'Age not set' : 'Age ${profile!.childAge}'),
                    trailing: IconButton(
                      key: const Key('edit-profile'),
                      tooltip: 'Edit profile',
                      icon: const Icon(Icons.edit),
                      onPressed: profile == null ? null : _editProfile,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(profile?.parentName ?? ''),
                    subtitle: Text(profile?.email ?? ''),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Username'),
                    subtitle: Text(profile?.username ?? ''),
                  ),
                ]),
                const SettingsSection(title: 'Progress', icon: Icons.star),
                SettingsCard(children: [
                  for (final c in PuzzleCategory.all) _progressTile(c, _progress[c.id] ?? const CategoryProgress()),
                  ListTile(
                    key: const Key('reset-all'),
                    leading: const Icon(Icons.restart_alt, color: Colors.red),
                    title: const Text('Reset all progress', style: TextStyle(color: Colors.red)),
                    onTap: () => _reset(),
                  ),
                ]),
                const SettingsSection(title: 'Account', icon: Icons.manage_accounts),
                SettingsCard(children: [
                  ListTile(
                    key: const Key('change-password'),
                    leading: const Icon(Icons.password),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                  ListTile(
                    key: const Key('logout'),
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: _logout,
                  ),
                ]),
                const SettingsSection(title: 'About', icon: Icons.info_outline),
                const SettingsCard(children: [
                  ListTile(title: Text('CodeBud'), subtitle: Text('Version ${AppConfig.version}')),
                  ListTile(
                    title: Text('Your data'),
                    subtitle: Text(
                      'Sound and play settings are stored only on this device. Progress and the child profile '
                      'are saved to your CodeBud account so they follow you between devices.',
                    ),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _progressTile(PuzzleCategory c, CategoryProgress p) {
    final fraction = p.maxStars == 0 ? 0.0 : p.stars / p.maxStars;
    return ListTile(
      leading:
          CircleAvatar(backgroundColor: c.color.withValues(alpha: 0.25), child: Icon(c.icon, color: Colors.black87)),
      title: Text(c.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: fraction, color: c.color, backgroundColor: Colors.grey.shade200),
          const SizedBox(height: 4),
          Text('${p.completed}/${p.total} levels · ${p.stars}/${p.maxStars} stars'),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Reset ${c.title}',
        icon: const Icon(Icons.restart_alt),
        onPressed: p.completed == 0 ? null : () => _reset(category: c),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.auth});
  final Profile profile;
  final AuthService auth;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _childName = TextEditingController(text: widget.profile.childName);
  late final _childAge = TextEditingController(text: widget.profile.childAge?.toString() ?? '');
  late final _parentName = TextEditingController(text: widget.profile.parentName ?? '');
  late final _email = TextEditingController(text: widget.profile.email ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_childName, _childAge, _parentName, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.auth.updateProfile(
        childName: _childName.text.trim(),
        childAge: int.parse(_childAge.text.trim()),
        parentName: _parentName.text.trim(),
        email: _email.text.trim(),
      );
      if (mounted) Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('child-name'),
                controller: _childName,
                decoration: const InputDecoration(labelText: 'Child name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('child-age'),
                controller: _childAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Child age'),
                validator: (v) {
                  final age = int.tryParse(v?.trim() ?? '');
                  return (age == null || age < 3 || age > 12) ? 'Age must be from 3 to 12' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentName,
                decoration: const InputDecoration(labelText: 'Parent name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Invalid email',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('save-profile'),
          onPressed: _saving ? null : _save,
          child:
              _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator()) : const Text('Save'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.auth});
  final AuthService auth;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.auth.changePassword(_current.text, _next.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (v) => v != _next.text ? 'Passwords do not match' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Change')),
      ],
    );
  }
}
