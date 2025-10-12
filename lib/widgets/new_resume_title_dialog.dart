import 'package:flutter/material.dart';

class NewResumeTitleDialog extends StatefulWidget {
  final String? initialTitle;
  const NewResumeTitleDialog({super.key, this.initialTitle});

  @override
  State<NewResumeTitleDialog> createState() => _NewResumeTitleDialogState();
}

class _NewResumeTitleDialogState extends State<NewResumeTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Resume'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Resume Title',
          hintText: 'e.g., Product Manager Resume',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('New Resume')),
      ],
    );
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    Navigator.of(context).pop(title);
  }
}
