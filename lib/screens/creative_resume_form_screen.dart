import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';

class CreativeResumeFormScreen extends StatefulWidget {
  final SavedResume? existing;
  const CreativeResumeFormScreen({super.key, this.existing});

  @override
  State<CreativeResumeFormScreen> createState() =>
      _CreativeResumeFormScreenState();
}

class _CreativeResumeFormScreenState extends State<CreativeResumeFormScreen> {
  String? profilePhotoPath;

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
                  _section('Profile Photo'),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: profilePhotoPath != null
                            ? AssetImage(profilePhotoPath!)
                            : null,
                        child: profilePhotoPath == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        onPressed: () {
                          // Placeholder - no picker integration
                          setState(() {
                            profilePhotoPath = 'assets/profile_placeholder.png';
                          });
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Mock photo assigned (demo only)'),
                            ),
                          );
                        },
                        label: const Text('Upload'),
                      ),
                    ],
                  ),

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

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        // Optionally attach profile photo path to data
                        if (profilePhotoPath != null) {
                          state.controllerFor('profilePhoto').text =
                              profilePhotoPath!;
                        }
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
