import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../widgets/base_resume_form.dart';
import '../widgets/requirements_banner.dart';
import '../widgets/profile_photo_picker.dart'; // ADD for photo picker
import '../widgets/ai_widgets.dart';
import '../widgets/dynamic_sections.dart';
import '../widgets/skills_picker_field.dart';

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
        // Content blocks
        'coreSkills',
        'experience', // bullet list / achievements
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
        // Dynamic data as JSON
        'workExperiencesJson',
        'educationsJson',
      ],
      child: const _OnePageBody(),
    );
  }
}

class _OnePageBody extends StatefulWidget {
  const _OnePageBody();

  @override
  State<_OnePageBody> createState() => _OnePageBodyState();
}

class _OnePageBodyState extends State<_OnePageBody> {
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];

  // Color theme for One Page template
  static const Color _accentColor = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    // Initialize with one empty entry
    _workExperiences.add(WorkExperience(id: '1'));
    _educations.add(Education(id: '1'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadExistingData();
  }

  void _loadExistingData() {
    final state = BaseResumeForm.of(context);
    if (state?.widget.existingResume != null) {
      final resume = state!.widget.existingResume!;

      // Load work experiences from JSON
      final workJson = resume.data['workExperiencesJson'] as String?;
      if (workJson != null && workJson.isNotEmpty) {
        try {
          final List<dynamic> workList = json.decode(workJson);
          _workExperiences = workList
              .map((e) => WorkExperience.fromJson(e))
              .toList();
        } catch (e) {
          // If parsing fails, keep default
        }
      }

      // Load educations from JSON
      final eduJson = resume.data['educationsJson'] as String?;
      if (eduJson != null && eduJson.isNotEmpty) {
        try {
          final List<dynamic> eduList = json.decode(eduJson);
          _educations = eduList.map((e) => Education.fromJson(e)).toList();
        } catch (e) {
          // If parsing fails, keep default
        }
      }
    }
  }

  String _getResumeContent(Map<String, TextEditingController> controllers) {
    final buffer = StringBuffer();

    // Add basic info
    if (controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${controllers['name']!.text}');
    }
    if (controllers['title']?.text.isNotEmpty == true) {
      buffer.writeln('Title: ${controllers['title']!.text}');
    }
    if (controllers['email']?.text.isNotEmpty == true) {
      buffer.writeln('Email: ${controllers['email']!.text}');
    }
    if (controllers['phone']?.text.isNotEmpty == true) {
      buffer.writeln('Phone: ${controllers['phone']!.text}');
    }

    // Add summary
    if (controllers['summary']?.text.isNotEmpty == true) {
      buffer.writeln('\nSummary: ${controllers['summary']!.text}');
    }

    // Add skills
    if (controllers['coreSkills']?.text.isNotEmpty == true) {
      buffer.writeln('\nCore Skills: ${controllers['coreSkills']!.text}');
    }

    // Add work experiences
    if (_workExperiences.isNotEmpty) {
      buffer.writeln('\nWork Experience:');
      for (final exp in _workExperiences) {
        if (exp.jobTitle.isNotEmpty || exp.company.isNotEmpty) {
          buffer.writeln('${exp.jobTitle} at ${exp.company}');
          if (exp.description.isNotEmpty) {
            buffer.writeln(exp.description);
          }
        }
      }
    }

    // Add education
    if (_educations.isNotEmpty) {
      buffer.writeln('\nEducation:');
      for (final edu in _educations) {
        if (edu.degree.isNotEmpty || edu.institution.isNotEmpty) {
          buffer.writeln('${edu.degree} at ${edu.institution}');
        }
      }
    }

    return buffer.toString();
  }

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
            const RequirementsBanner(
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
            AISummaryGenerator(
              name: state.controllers['name']?.text ?? '',
              targetRole: _workExperiences.isNotEmpty
                  ? _workExperiences.first.jobTitle
                  : '',
              skills: (state.controllers['coreSkills']?.text ?? '')
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
              experience: _workExperiences
                  .map((exp) => exp.description)
                  .where((desc) => desc.isNotEmpty)
                  .toList(),
              onGenerated: (summary) {
                state.controllers['summary']?.text = summary;
              },
            ),
            state.buildTextField(
              'summary',
              '2–3 line Professional Summary',
              required: true,
              maxLines: 4,
            ),

            _divider(),
            _section('Key Skills'),
            SkillsPickerField(
              controller: state.controllerFor('coreSkills'),
              label: '6–10 Relevant Skills',
            ),

            _divider(),
            DynamicWorkExperienceSection(
              workExperiences: _workExperiences,
              onWorkExperiencesChanged: (experiences) {
                setState(() {
                  _workExperiences = experiences;
                  // Store as JSON in a hidden controller for saving
                  state.controllerFor('workExperiencesJson').text = json.encode(
                    experiences.map((e) => e.toJson()).toList(),
                  );
                });
              },
              accentColor: _accentColor,
            ),

            _divider(),
            DynamicEducationSection(
              educations: _educations,
              onEducationsChanged: (educations) {
                setState(() {
                  _educations = educations;
                  // Store as JSON in a hidden controller for saving
                  state.controllerFor('educationsJson').text = json.encode(
                    educations.map((e) => e.toJson()).toList(),
                  );
                });
              },
              accentColor: _accentColor,
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
            // ATS Optimization Panel
            ATSOptimizationPanel(
              content: _getResumeContent(state.controllers),
              jobDescription:
                  '', // Can be enhanced to accept job description input
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
