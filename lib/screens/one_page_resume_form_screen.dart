import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/requirements_banner.dart';
import '../widgets/profile_photo_picker.dart'; // ADD for photo picker

class OnePageResumeFormScreen extends StatelessWidget {
  final SavedResume? existing;
  const OnePageResumeFormScreen({super.key, this.existing});

  // Updated required field set (others are optional)
  static const _requiredMap = {
    'name': 'Full Name',
    'phone': 'Phone Number',
    'email': 'Email Address',
    'summary': 'Professional Summary',
    'coreSkills': 'Key Skills',
    'jobTitle': 'Job Title',
    'company': 'Company Name',
    'employmentDates': 'Employment Dates',
    'education': 'Education',
  };

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: existing,
      template: 'One Page',
      extraKeys: const [
        // Contact / Header
        'title', // Professional Title (optional)
        'portfolio',
        'linkedIn',
        // Experience structured fields
        'jobTitle',
        'company',
        'experienceLocation',
        'employmentDates',
        // Content blocks
        'coreSkills',
        'experience', // bullet list / achievements
        'education',
        'certifications',
        'projects',
        // Optional sections
        'awards',
        'languages',
        'volunteer',
        'memberships',
        'hobbies',
        // Photo
        'profilePhotoBase64',
      ],
      child: const _OnePageBody(),
    );
  }
}

class _OnePageBody extends StatelessWidget {
  const _OnePageBody();

  @override
  Widget build(BuildContext context) {
    final state = BaseResumeForm.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('One Page Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => state.saveResume(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RequirementsBanner(
              requiredFieldLabels: OnePageResumeFormScreen._requiredMap,
            ),

            _section('Contact Information'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoPicker(
                  size: 90,
                  initialBase64:
                      state.controllerFor('profilePhotoBase64').text.isEmpty
                      ? null
                      : state.controllerFor('profilePhotoBase64').text,
                  onChanged: (b64) {
                    state.controllerFor('profilePhotoBase64').text = b64 ?? '';
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      state.buildTextField('name', 'Full Name', required: true),
                      state.buildTextField('title', 'Professional Title'),
                    ],
                  ),
                ),
              ],
            ),
            state.buildTextField(
              'phone',
              'Phone Number',
              required: true,
              keyboard: TextInputType.phone,
            ),
            state.buildTextField(
              'email',
              'Email Address',
              required: true,
              keyboard: TextInputType.emailAddress,
            ),
            state.buildTextField('linkedIn', 'LinkedIn Profile (optional)'),
            state.buildTextField('portfolio', 'Personal Website / Portfolio'),

            _divider(),
            _section('Professional Summary / Objective'),
            state.buildTextField(
              'summary',
              '2–3 line Professional Summary',
              required: true,
              maxLines: 4,
            ),

            _divider(),
            _section('Key Skills (comma separated)'),
            state.buildTextField(
              'coreSkills',
              '6–10 Relevant Skills',
              required: true,
              maxLines: 2,
            ),

            _divider(),
            _section('Professional Experience'),
            Row(
              children: [
                Expanded(
                  child: state.buildTextField(
                    'jobTitle',
                    'Job Title',
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: state.buildTextField(
                    'company',
                    'Company Name',
                    required: true,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: state.buildTextField(
                    'experienceLocation',
                    'Location (City, State)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: state.buildTextField(
                    'employmentDates',
                    'Dates (e.g. Jan 2022 – Aug 2024)',
                    required: true,
                  ),
                ),
              ],
            ),
            state.buildTextField(
              'experience',
              '2–5 Bullet Points (achievements, metrics)',
              required: true,
              maxLines: 8,
            ),

            _divider(),
            _section('Education'),
            state.buildTextField(
              'education',
              'Degree / Institution / Graduation Year / Honors',
              required: true,
              maxLines: 4,
            ),

            _divider(),
            _section('Certifications (if relevant)'),
            state.buildTextField(
              'certifications',
              'Certification Name | Issuer | Year',
              maxLines: 3,
            ),

            _divider(),
            _section('Projects (if relevant)'),
            state.buildTextField(
              'projects',
              'Project Title – Brief Description – Tech / Role',
              maxLines: 4,
            ),

            _divider(),
            _section('Additional (Optional)'),
            state.buildTextField('awards', 'Awards & Honors', maxLines: 3),
            state.buildTextField('languages', 'Languages Known', maxLines: 2),
            state.buildTextField(
              'volunteer',
              'Volunteer Experience',
              maxLines: 3,
            ),
            state.buildTextField(
              'memberships',
              'Professional Memberships',
              maxLines: 3,
            ),
            state.buildTextField(
              'hobbies',
              'Hobbies / Interests (only if relevant)',
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save One Page Resume'),
                onPressed: () => state.saveResume(),
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
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15.5,
        letterSpacing: .3,
      ),
    ),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Divider(thickness: 1),
  );
}
