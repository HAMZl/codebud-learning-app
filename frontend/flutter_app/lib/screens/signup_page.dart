import 'package:flutter/material.dart';

import '../models/family.dart';
import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/child_dialog.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

/// One child on the form.
class _KidEntry {
  final name = TextEditingController();
  int? age;
  final key = UniqueKey();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _parentName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _kids = [_KidEntry()];
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // These rules match the backend's validation, so most mistakes are caught before a request is sent.
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernameRe = RegExp(r'^[A-Za-z0-9_.-]{3,30}$');

  @override
  void dispose() {
    for (final c in [_parentName, _email, _username, _password, _confirm, ..._kids.map((k) => k.name)]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  void _addKid() => setState(() => _kids.add(_KidEntry()));

  void _removeKid(_KidEntry kid) {
    setState(() => _kids.remove(kid));
    kid.name.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AppScope.of(context).auth;
    final username = _username.text.trim();
    try {
      await auth.signUp(SignUpData(
        parentName: _parentName.text.trim(),
        email: _email.text.trim(),
        username: username,
        password: _password.text,
        children: [for (final k in _kids) ChildDraft(name: k.name.text.trim(), age: k.age!)],
      ));
      // Log straight in, so the family lands on "Who's playing?".
      await auth.login(username, _password.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.profiles, (_) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create a family account',
      subtitle: 'One account for the whole family. Each child gets their own robot and stars.',
      maxWidth: 560,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Step(number: 1, title: 'About you', color: AppColors.primary),
            TextFormField(
              key: const Key('signup-parent-name'),
              controller: _parentName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person)),
              validator: (v) => _required(v, 'Your name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('signup-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              validator: (v) =>
                  _required(v, 'Email') ?? (_emailRe.hasMatch(v!.trim()) ? null : 'Please enter a valid email'),
            ),
            const _Step(number: 2, title: 'Your kids', color: AppColors.sky),
            for (var i = 0; i < _kids.length; i++) _kidRow(i),
            if (_kids.length < Family.maxChildren)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('signup-add-kid'),
                  onPressed: _addKid,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add another child'),
                ),
              ),
            const _Step(number: 3, title: 'Log-in details', color: AppColors.violet),
            TextFormField(
              key: const Key('signup-username'),
              controller: _username,
              autofillHints: const [AutofillHints.newUsername],
              decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle)),
              validator: (v) =>
                  _required(v, 'Username') ??
                  (_usernameRe.hasMatch(v!.trim()) ? null : '3-30 letters, numbers, . _ or -'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('signup-password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'You’ll also use this to unlock parent settings.',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('signup-confirm'),
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              key: const Key('signup-submit'),
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.rocket_launch),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kidRow(int i) {
    final kid = _kids[i];
    final color = RobotColor.all[i % RobotColor.all.length].color;
    return Container(
      key: kid.key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final name = TextFormField(
                key: Key('signup-kid-name-$i'),
                controller: kid.name,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Child’s name', counterText: ''),
                validator: (v) => _required(v, 'Name'),
              );
              final age = AgeField(
                key: Key('signup-kid-age-$i'),
                value: kid.age,
                onChanged: (v) => setState(() => kid.age = v),
              );
              // Side by side when there is room, stacked on small phones.
              return constraints.maxWidth > 420
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: name),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: age)
                      ],
                    )
                  : Column(children: [name, const SizedBox(height: 10), age]);
            }),
          ),
          IconButton(
            key: Key('signup-remove-kid-$i'),
            tooltip: 'Remove',
            onPressed: _kids.length == 1 ? null : () => _removeKid(kid),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.color});
  final int number;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: number == 1 ? 0 : 28, bottom: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color,
              child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          ],
        ),
      );
}
