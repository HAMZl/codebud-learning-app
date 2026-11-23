import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Asks a multiplication question that young children can't easily answer, to
/// keep account settings for grown-ups. Kids' apps usually put a check like
/// this in front of anything that changes the account.
///
/// Returns true if the answer was right.
Future<bool> showParentalGate(BuildContext context, {Random? random}) async {
  final rng = random ?? Random();
  final a = 3 + rng.nextInt(7); // 3..9
  final b = 3 + rng.nextInt(7);
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ParentalGateDialog(a: a, b: b),
  );
  return result ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog({required this.a, required this.b});
  final int a;
  final int b;

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _answer = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_answer.text.trim()) == widget.a * widget.b) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      _answer.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
      title: const Text('Grown-ups only'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('To continue, please answer:', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('${widget.a} × ${widget.b} = ?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('gate-answer'),
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(errorText: _wrong ? 'Not quite, try again' : null),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(key: const Key('gate-submit'), onPressed: _check, child: const Text('Continue')),
      ],
    );
  }
}
