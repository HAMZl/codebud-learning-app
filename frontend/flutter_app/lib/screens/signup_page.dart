import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _parentName = TextEditingController();
  final _email = TextEditingController();
  final _childName = TextEditingController();
  final _childAge = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  // These rules match the backend's validation, so most mistakes are caught before a request is sent.
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernameRe = RegExp(r'^[A-Za-z0-9_.-]{3,30}$');

  @override
  void dispose() {
    for (final c in [_parentName, _email, _childName, _childAge, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await AppScope.of(context).auth.signUp(SignUpData(
            parentName: _parentName.text.trim(),
            email: _email.text.trim(),
            childName: _childName.text.trim(),
            childAge: _childAge.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
          ));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login, arguments: '$message Please log in.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('👩 Parent Information'),
                    TextFormField(
                      controller: _parentName,
                      decoration: const InputDecoration(labelText: 'Parent Name', prefixIcon: Icon(Icons.person)),
                      validator: (v) => _required(v, 'Parent name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      validator: (v) =>
                          _required(v, 'Email') ?? (_emailRe.hasMatch(v!.trim()) ? null : 'Please enter a valid email'),
                    ),
                    _section('🧒 Child Information'),
                    TextFormField(
                      controller: _childName,
                      decoration: const InputDecoration(labelText: 'Child Name', prefixIcon: Icon(Icons.child_care)),
                      validator: (v) => _required(v, 'Child name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _childAge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Child Age', prefixIcon: Icon(Icons.cake)),
                      validator: (v) {
                        final age = int.tryParse(v?.trim() ?? '');
                        return (age == null || age < 3 || age > 12) ? 'Age must be from 3 to 12' : null;
                      },
                    ),
                    _section('🔑 Account Details'),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle)),
                      validator: (v) =>
                          _required(v, 'Username') ??
                          (_usernameRe.hasMatch(v!.trim()) ? null : '3-30 letters, numbers, . _ or -'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                      validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                    ],
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(onPressed: _submit, child: const Text('Sign Up')),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Log in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
