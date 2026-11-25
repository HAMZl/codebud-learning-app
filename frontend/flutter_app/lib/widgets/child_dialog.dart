import 'package:flutter/material.dart';

import '../models/family.dart';
import '../services/api_client.dart';

/// Add a child (when [child] is null) or change a child's name and age.
///
/// [save] does the request. The dialog stays open with the error if it fails,
/// and closes with the saved child when it succeeds.
Future<Child?> showChildDialog(
  BuildContext context, {
  Child? child,
  required Future<Child> Function(String name, int age) save,
}) =>
    showDialog<Child>(context: context, builder: (_) => _ChildDialog(child: child, save: save));

class _ChildDialog extends StatefulWidget {
  const _ChildDialog({required this.child, required this.save});
  final Child? child;
  final Future<Child> Function(String name, int age) save;

  @override
  State<_ChildDialog> createState() => _ChildDialogState();
}

class _ChildDialogState extends State<_ChildDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.child?.name ?? '');
  late int? _age = widget.child?.age;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.save(_name.text.trim(), _age!);
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.child == null ? 'Add a child' : 'Edit ${widget.child!.name}'),
      content: Form(
        key: _form,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('child-name'),
                controller: _name,
                autofocus: widget.child == null,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.face), counterText: ''),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              AgeField(
                key: const Key('child-age'),
                value: _age,
                onChanged: (v) => setState(() => _age = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('save-child'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(widget.child == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

/// An age picker from [Child.minAge] to [Child.maxAge].
class AgeField extends StatelessWidget {
  const AgeField({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
        items: [
          for (var a = Child.minAge; a <= Child.maxAge; a++)
            DropdownMenuItem(value: a, child: Text('$a years old', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
        validator: (v) => v == null ? 'Pick an age' : null,
      );
}
