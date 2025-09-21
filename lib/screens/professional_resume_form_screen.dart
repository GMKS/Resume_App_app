import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../services/share_export_service.dart';
import '../services/resume_storage_service.dart';
import '../widgets/requirements_banner.dart';

class ProfessionalResumeFormScreen extends StatelessWidget {
  final SavedResume? existing;
  const ProfessionalResumeFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: existing,
      template: 'Professional',
      extraKeys: const [
        'linkedIn',
        'address',
        'executiveSummary',
        'keySkills',
        'jobTitle',
        'company',
        'duration',
        'achievements',
        'certifications',
        'projects',
        'awards',
        'languages',
        'references',
      ],
      child: _ProfessionalFormBody(),
    );
  }
}

class _ProfessionalFormBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = BaseResumeForm.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Resume'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final state = BaseResumeForm.of(context)!;
              await state.saveResume(); // ensure saved
              final resume = _latestProfessional();
              if (resume == null) return;
              await ShareExportService.instance.exportAndOpenPdf(resume);
            },
          ),
          IconButton(
            tooltip: 'Export Word',
            icon: const Icon(Icons.description_outlined),
            onPressed: () async {
              final state = BaseResumeForm.of(context)!;
              await state.saveResume();
              final resume = _latestProfessional();
              if (resume == null) return;
              await ShareExportService.instance.exportAndOpenDoc(resume);
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final state = BaseResumeForm.of(context)!;
              await state.saveResume();
              final resume = _latestProfessional();
              if (resume == null) return;
              await ShareExportService.instance.shareGeneric(resume);
            },
          ),
        ],
      ),
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
            state.buildTextField('linkedIn', 'LinkedIn Profile'),
            state.buildTextField('address', 'Address', maxLines: 2),

            _section('Executive Summary'),
            state.buildTextField(
              'executiveSummary',
              'Executive Summary',
              maxLines: 4,
            ),

            _section('Key Skills'),
            state.buildTextField(
              'keySkills',
              'Key Skills (comma separated)',
              maxLines: 2,
            ),

            _section('Work Experience'),
            state.buildTextField('jobTitle', 'Job Title'),
            state.buildTextField('company', 'Company'),
            state.buildTextField('duration', 'Duration (e.g. 2019 - 2023)'),
            state.buildTextField('achievements', 'Achievements', maxLines: 4),

            _section('Education'),
            state.buildTextField('education', 'Education', maxLines: 3),

            _section('Certifications'),
            state.buildTextField(
              'certifications',
              'Certifications',
              maxLines: 2,
            ),

            _section('Projects'),
            state.buildTextField('projects', 'Projects', maxLines: 3),

            _section('Awards & Recognitions'),
            state.buildTextField(
              'awards',
              'Awards & Recognitions',
              maxLines: 3,
            ),

            _section('Languages'),
            state.buildTextField('languages', 'Languages', maxLines: 2),

            _section('References'),
            state.buildTextField('references', 'References', maxLines: 3),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: () => state.saveResume(),
                label: const Text('Save Professional Resume'),
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

  SavedResume? _latestProfessional() {
    final list = ResumeStorageService.instance.resumes.value;
    if (list.isEmpty) return null;
    // Prefer the most recently updated Professional resume
    final profs = list.where((r) => r.template == 'Professional').toList();
    profs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return (profs.isNotEmpty ? profs.first : list.last);
  }
}
