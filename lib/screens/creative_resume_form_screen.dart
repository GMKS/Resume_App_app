import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/requirements_banner.dart';
import '../services/ai_resume_service.dart';
import '../widgets/ai_widgets.dart';

class CreativeResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const CreativeResumeFormScreen({super.key, this.existing});

  @override
  State<CreativeResumeFormScreen> createState() =>
      _CreativeResumeFormScreenState();
}

class _CreativeResumeFormScreenState extends State<CreativeResumeFormScreen> {
  String _getResumeContent(Map<String, TextEditingController> controllers) {
    final buffer = StringBuffer();

    // Add basic info
    if (controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${controllers['name']!.text}');
    }
    if (controllers['email']?.text.isNotEmpty == true) {
      buffer.writeln('Email: ${controllers['email']!.text}');
    }
    if (controllers['phone']?.text.isNotEmpty == true) {
      buffer.writeln('Phone: ${controllers['phone']!.text}');
    }

    // Add creative summary
    if (controllers['creativeSummary']?.text.isNotEmpty == true) {
      buffer.writeln(
        '\nCreative Summary: ${controllers['creativeSummary']!.text}',
      );
    }

    // Add skills
    if (controllers['skills']?.text.isNotEmpty == true) {
      buffer.writeln('\nSkills: ${controllers['skills']!.text}');
    }

    // Add tools
    if (controllers['tools']?.text.isNotEmpty == true) {
      buffer.writeln('\nTools & Software: ${controllers['tools']!.text}');
    }

    // Add experience
    if (controllers['experience']?.text.isNotEmpty == true) {
      buffer.writeln('\nExperience: ${controllers['experience']!.text}');
    }

    // Add education
    if (controllers['education']?.text.isNotEmpty == true) {
      buffer.writeln('\nEducation: ${controllers['education']!.text}');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BaseResumeForm(
      existingResume: widget.existing,
      template: 'Creative',
      extraKeys: const [
        'portfolio',
        'socialLinks',
        'creativeSummary',
        'skillGraphs',
        'tools',
        'projects',
        'certifications',
        'languages',
        'hobbies',
        'references',
        'profilePhotoBase64', // ADDED
      ],
      child: Builder(
        builder: (ctx) {
          final state = BaseResumeForm.of(ctx)!;
          return Scaffold(
            appBar: AppBar(title: const Text('Creative Resume')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequirementsBanner(
                    requiredFieldLabels: const {
                      'name': 'Full Name',
                      'phone': 'Mobile Number',
                      'email': 'Email',
                      'portfolio': 'Portfolio / Website',
                      'creativeSummary': 'Creative Summary',
                      'skills': 'Skills',
                      'tools': 'Tools & Software',
                      'experience': 'Experience',
                      'education': 'Education',
                    },
                  ),
                  _section('Profile Photo'),
                  ProfilePhotoPicker(
                    initialBase64:
                        state.controllerFor('profilePhotoBase64').text.isEmpty
                        ? null
                        : state.controllerFor('profilePhotoBase64').text,
                    onChanged: (b64) {
                      state.controllerFor('profilePhotoBase64').text =
                          b64 ?? '';
                    },
                  ),
                  const SizedBox(height: 12),

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
                  state.buildTextField('portfolio', 'Portfolio / Website'),
                  state.buildTextField(
                    'socialLinks',
                    'LinkedIn / Behance / Dribbble',
                    maxLines: 2,
                  ),

                  _section('Creative Summary'),
                  AISummaryGenerator(
                    name: state.controllers['name']?.text ?? '',
                    targetRole: 'Creative Professional',
                    skills: (state.controllers['skills']?.text ?? '')
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                    experience: [
                      (state.controllers['experience']?.text ?? '').trim(),
                    ].where((s) => s.isNotEmpty).toList(),
                    onGenerated: (summary) {
                      state.controllers['creativeSummary']?.text = summary;
                    },
                  ),
                  state.buildTextField(
                    'creativeSummary',
                    'Creative Summary',
                    maxLines: 4,
                  ),

                  _section('Skills'),
                  state.buildTextField(
                    'skills',
                    'Skills (comma separated)',
                    maxLines: 2,
                  ),
                  state.buildTextField(
                    'skillGraphs',
                    'Skill Graph Data (description)',
                    maxLines: 3,
                  ),

                  _section('Tools & Software'),
                  state.buildTextField(
                    'tools',
                    'Tools & Software',
                    maxLines: 3,
                  ),

                  _section('Experience'),
                  AIBulletPointGenerator(
                    jobTitle: 'Creative Professional',
                    company: '',
                    description: '',
                    onGenerated: (bulletPoints) {
                      state.controllers['experience']?.text = bulletPoints.join(
                        '\n• ',
                      );
                    },
                  ),
                  state.buildTextField('experience', 'Experience', maxLines: 4),

                  _section('Education'),
                  state.buildTextField('education', 'Education', maxLines: 3),

                  _section('Projects'),
                  state.buildTextField('projects', 'Projects', maxLines: 3),

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

                  _section('References'),
                  state.buildTextField('references', 'References', maxLines: 3),

                  const SizedBox(height: 24),
                  // ATS Optimization Panel
                  ATSOptimizationPanel(
                    content: _getResumeContent(state.controllers),
                    jobDescription:
                        '', // Can be enhanced to accept job description input
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        state.saveResume();
                      },
                      label: const Text('Save Creative Resume'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
