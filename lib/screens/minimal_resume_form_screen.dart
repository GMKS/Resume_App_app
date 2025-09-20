import 'package:flutter/material.dart';
import '../models/saved_resume.dart';

class MinimalResumeFormScreen extends StatelessWidget {
  final SavedResume? existingResume;
  const MinimalResumeFormScreen({super.key, this.existingResume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Resume')),
      body: Center(
        child: Text(
          'Minimal Resume Form Coming Soon!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
