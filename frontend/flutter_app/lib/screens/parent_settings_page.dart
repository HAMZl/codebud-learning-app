import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/family.dart';
import '../models/puzzle.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_dialog.dart';
import '../widgets/made_by.dart';
import '../widgets/parental_gate.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/settings_widgets.dart';
import 'session.dart';

/// Account settings for grown-ups. Opening it needs the account password ([showParentGate]),
/// and the server checks the parent token on every change made here.
class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  Map<String, Map<String, CategoryProgress>> _progress = const {};
  bool _loading = true;
  bool _started = false;

  AppScope get _scope => AppScope.of(context);
  AuthService get _auth => _scope.auth;

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
      final family = await _auth.loadFamily();
      final entries = await Future.wait(family.children.map(
        (c) async => MapEntry(c.id, await _scope.puzzles.fetchProgress(childId: c.id)),
      ));
      if (mounted) setState(() => _progress = Map.fromEntries(entries));
    } catch (e) {
      if (mounted) await _onError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onError(Object e) async {
    if (e is ApiException && e.needsParent) {
      showToast(context, e.message, error: true);
      setState(() {}); // shows the locked view
      return;
    }
    await handleApiError(context, e);
  }

  Future<bool> _confirm({required String title, required String body, required String action, Key? key}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            key: key,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  // --- actions ----------------------------------------------------------------------

  Future<void> _addChild() async {
    final child = await showChildDialog(context, save: _auth.addChild);
    if (child == null || !mounted) return;
    showToast(context, '${child.name} added');
    await _load();
  }

  Future<void> _editChild(Child child) async {
    final updated = await showChildDialog(
      context,
      child: child,
      save: (name, age) => _auth.updateChild(child, name: name, age: age),
    );
    if (updated != null && mounted) showToast(context, 'Saved');
  }

  Future<void> _removeChild(Child child) async {
    if (!await _confirm(
      key: const Key('confirm-remove'),
      title: 'Remove ${child.name}?',
      body: '${child.name}’s robot and stars will be deleted. This cannot be undone.',
      action: 'Remove',
    )) {
      return;
    }
    try {
      await _auth.removeChild(child);
      if (mounted) showToast(context, '${child.name} removed');
    } catch (e) {
      if (mounted) await _onError(e);
    }
  }

  Future<void> _reset(Child child, {PuzzleCategory? category}) async {
    final what = category == null ? 'all of ${child.name}’s progress' : '${child.name}’s ${category.title} progress';
    if (!await _confirm(
      key: const Key('confirm-reset'),
      title: 'Reset $what?',
      body: 'Earned stars will be erased and levels will lock again. This cannot be undone.',
      action: 'Reset',
    )) {
      return;
    }
    try {
      await _scope.puzzles.resetProgress(childId: child.id, category: category?.id);
      if (!mounted) return;
      showToast(context, 'Progress reset');
      await _load();
    } catch (e) {
      if (mounted) await _onError(e);
    }
  }

  Future<void> _editAccount(Family family) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AccountDialog(family: family, auth: _auth),
    );
    if (saved == true && mounted) showToast(context, 'Account updated');
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => _PasswordDialog(auth: _auth));
    if (changed == true && mounted) showToast(context, 'Password changed');
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.launch, (_) => false);
  }

  void _lock() {
    _auth.lockParent();
    Navigator.pop(context);
  }

  // --- UI ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Parent settings'),
          actions: [
            if (_auth.isParentUnlocked)
              IconButton(key: const Key('lock-now'), tooltip: 'Lock', icon: const Icon(Icons.lock), onPressed: _lock),
          ],
        ),
        body: AppBackground(child: SafeArea(child: _body())),
      ),
    );
  }

  Widget _body() {
    if (!_auth.isParentUnlocked) return _locked();
    final family = _auth.family;
    if (family == null) {
      return Center(child: _loading ? const CircularProgressIndicator() : const Text('Could not load your family.'));
    }
    return SettingsList(
      children: [
        const SettingsSection(title: 'Your kids', icon: Icons.family_restroom),
        for (final child in family.children) _childCard(child, canRemove: family.children.length > 1),
        if (family.children.length < Family.maxChildren)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              key: const Key('parent-add-child'),
              onPressed: _addChild,
              icon: const Icon(Icons.person_add),
              label: const Text('Add a child'),
            ),
          ),
        const SettingsSection(title: 'Your account', icon: Icons.manage_accounts),
        SettingsCard(children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(family.parentName ?? ''),
            subtitle: Text(family.email ?? ''),
            trailing: IconButton(
              key: const Key('edit-account'),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () => _editAccount(family),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Username'),
            subtitle: Text(family.username),
          ),
          ListTile(
            key: const Key('change-password'),
            leading: const Icon(Icons.password),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          ListTile(
            key: const Key('logout'),
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Log out', style: TextStyle(color: AppColors.danger)),
            onTap: _logout,
          ),
        ]),
        const SettingsSection(title: 'About', icon: Icons.info_outline),
        const SettingsCard(children: [
          ListTile(title: Text('CodeBud'), subtitle: Text('Version ${AppConfig.version}')),
          ListTile(
            title: Text('Your data'),
            subtitle: Text(
              'Sound and play settings are stored only on this device. Your kids’ profiles, robots and stars are '
              'saved to your CodeBud account so they follow you between devices. Parent settings lock again '
              'when you leave them, or after 30 minutes.',
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 16), child: MadeByCredit(linkColor: AppColors.primary)),
        ]),
      ],
    );
  }

  Widget _locked() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.lock, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Parent settings are locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('unlock-again'),
                onPressed: () async {
                  if (await showParentGate(context) && mounted) await _load();
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );

  Widget _childCard(Child child, {required bool canRemove}) {
    final progress = _progress[child.id] ?? const {};
    final stars = progress.values.fold(0, (sum, p) => sum + p.stars);
    final maxStars = progress.values.fold(0, (sum, p) => sum + p.maxStars);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SettingsCard(children: [
        Theme(
          // ExpansionTile draws divider lines by default; the card already has a border.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key('child-${child.id}'),
            leading: RobotAvatar(look: child.robot, size: 48),
            title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            subtitle: Text(
              [
                if (child.age != null) 'Age ${child.age}',
                'Robot: ${child.robot.displayName}',
                if (maxStars > 0) '$stars / $maxStars stars',
              ].join(' · '),
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final c in PuzzleCategory.all) _progressTile(child, c, progress[c.id] ?? const CategoryProgress()),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    key: Key('edit-child-${child.id}'),
                    onPressed: () => _editChild(child),
                    icon: const Icon(Icons.edit),
                    label: const Text('Name & age'),
                  ),
                  TextButton.icon(
                    key: Key('reset-all-${child.id}'),
                    onPressed: () => _reset(child),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset stars'),
                  ),
                  if (canRemove)
                    TextButton.icon(
                      key: Key('remove-child-${child.id}'),
                      onPressed: () => _removeChild(child),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _progressTile(Child child, PuzzleCategory c, CategoryProgress p) {
    final fraction = p.maxStars == 0 ? 0.0 : p.stars / p.maxStars;
    return ListTile(
      dense: true,
      leading: CircleAvatar(backgroundColor: c.color, child: Icon(c.icon, color: Colors.white, size: 20)),
      title: Text(c.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: c.color,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 4),
          Text('${p.completed}/${p.total} levels · ${p.stars}/${p.maxStars} stars'),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Reset ${c.title}',
        icon: const Icon(Icons.restart_alt),
        onPressed: p.completed == 0 ? null : () => _reset(child, category: c),
      ),
    );
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.family, required this.auth});
  final Family family;
  final AuthService auth;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _form = GlobalKey<FormState>();
  late final _parentName = TextEditingController(text: widget.family.parentName ?? '');
  late final _email = TextEditingController(text: widget.family.email ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _parentName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.auth.updateParent(parentName: _parentName.text.trim(), email: _email.text.trim());
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
      title: const Text('Your account'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('parent-name'),
              controller: _parentName,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('parent-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Invalid email',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('save-account'),
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
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
              key: const Key('current-password'),
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('new-password'),
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('confirm-password'),
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (v) => v != _next.text ? 'Passwords do not match' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('save-password'),
          onPressed: _saving ? null : _save,
          child: const Text('Change'),
        ),
      ],
    );
  }
}
