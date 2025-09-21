import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';

class MinimalResumeFormScreen extends StatelessWidget {
  final SavedResume? existing;
  const MinimalResumeFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: existing,
      template: 'Minimal',
      extraKeys: const ['languages', 'hobbies', 'certifications'],
      child: _MinimalFormBody(),
    );
  }
}

class _MinimalFormBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Resume')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Personal Information'),
            state.buildTextField('name', 'Full Name', required: true),
            state.buildTextField(
              'phone',
              'Mobile Number',
              required: true,
              keyboard: TextInputType.phone,
            ),
            state.buildTextField(
              'email',
              'Email Address',
              required: true,
              keyboard: TextInputType.emailAddress,
            ),

            _section('Summary'),
            state.buildTextField('summary', 'Summary', maxLines: 3),

            _section('Education'),
            state.buildTextField('education', 'Education', maxLines: 3),

            _section('Experience'),
            state.buildTextField('experience', 'Experience', maxLines: 4),

            _section('Skills'),
            state.buildTextField(
              'skills',
              'Skills (comma separated)',
              maxLines: 2,
            ),

            _section('Certifications'),
            state.buildTextField(
              'certifications',
              'Certifications',
              maxLines: 2,
            ),

            _section('Languages'),
            state.buildTextField('languages', 'Languages', maxLines: 2),

            _section('Hobbies'),
            state.buildTextField('hobbies', 'Hobbies', maxLines: 2),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: () => state.saveResume(),
                label: const Text('Save Minimal Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );
}
