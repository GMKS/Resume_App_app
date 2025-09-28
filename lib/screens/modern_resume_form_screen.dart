import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/profile_photo_picker.dart';
import '../services/premium_service.dart';
import '../services/share_export_service.dart';
// skills handled via shared SkillsPickerField; no direct SkillsService import needed here
import '../widgets/skills_picker_field.dart';
import 'package:url_launcher/url_launcher.dart';

class ModernResumeFormScreen extends StatefulWidget {
  final SavedResume? existingResume;
  const ModernResumeFormScreen({super.key, this.existingResume});

  @override
  State<ModernResumeFormScreen> createState() => _ModernResumeFormScreenState();
}

class _ModernResumeFormScreenState extends State<ModernResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
    'linkedin': TextEditingController(),
    'github': TextEditingController(),
    'portfolio': TextEditingController(),
    'certifications': TextEditingController(),
    'achievements': TextEditingController(),
    'hobbies': TextEditingController(),
  };

  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'email': FocusNode(),
    'phone': FocusNode(),
    'linkedin': FocusNode(),
    'github': FocusNode(),
    'portfolio': FocusNode(),
  };

  String? _profilePhotoB64;

  final List<Map<String, dynamic>> _workTimeline = [];
  final List<Map<String, dynamic>> _eduTimeline = [];

  final _workCompany = TextEditingController();
  final _workRole = TextEditingController();
  DateTime? _workStart, _workEnd;

  final _eduSchool = TextEditingController();
  final _eduDegree = TextEditingController();
  DateTime? _eduStart, _eduEnd;

  void _onPhotoChanged(String? b64) {
    setState(() => _profilePhotoB64 = b64);
  }

  void _addWork() {
    if (_workCompany.text.isEmpty ||
        _workRole.text.isEmpty ||
        _workStart == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill Company, Role and Start Date.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _workTimeline.add({
        'company': _workCompany.text.trim(),
        'role': _workRole.text.trim(),
        'start': _workStart,
        'end': _workEnd,
      });
      _workCompany.clear();
      _workRole.clear();
      _workStart = null;
      _workEnd = null;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _workCompany.dispose();
    _workRole.dispose();
    _eduSchool.dispose();
    _eduDegree.dispose();
    super.dispose();
  }

  Map<String, dynamic> _collectResumeData() {
    return {
      'personalInfo': {
        'name': _controllers['name']!.text.trim(),
        'email': _controllers['email']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'linkedin': _controllers['linkedin']!.text.trim(),
        if (_profilePhotoB64 != null && _profilePhotoB64!.isNotEmpty)
          'profilePhotoBase64': _profilePhotoB64,
      },
      'summary': _controllers['summary']!.text,
      // store skills both as list (modern) and as csv string to maximize exporter compatibility
      'skills': _controllers['skills']!.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'skillsCsv': _controllers['skills']!.text,
      'workExperience': _workTimeline
          .map(
            (e) => {
              'company': e['company'],
              'role': e['role'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
      // also include classic JSON-string fields expected by older exporter
      'workExperiences': jsonEncode(
        _workTimeline
            .map(
              (e) => {
                'jobTitle': e['role'],
                'company': e['company'],
                'description': '',
              },
            )
            .toList(),
      ),
      'education': _eduTimeline
          .map(
            (e) => {
              'school': e['school'],
              'degree': e['degree'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
      'educations': jsonEncode(
        _eduTimeline
            .map(
              (e) => {
                'degree': e['degree'],
                'institution': e['school'],
                'description': '',
              },
            )
            .toList(),
      ),
      'certifications': _controllers['certifications']!.text,
      'achievements': _controllers['achievements']!.text,
      'hobbies': _controllers['hobbies']!.text,
    };
  }

  String _getResumeContent() {
    final buffer = StringBuffer();

    // Add basic info
    if (_controllers['name']?.text.isNotEmpty == true) {
      buffer.writeln('Name: ${_controllers['name']!.text}');
    }
    if (_controllers['email']?.text.isNotEmpty == true) {
      buffer.writeln('Email: ${_controllers['email']!.text}');
    }
    if (_controllers['phone']?.text.isNotEmpty == true) {
      buffer.writeln('Phone: ${_controllers['phone']!.text}');
    }

    // Add summary
    if (_controllers['summary']?.text.isNotEmpty == true) {
      buffer.writeln('\nSummary: ${_controllers['summary']!.text}');
    }

    // Add skills
    final skillsText = _controllers['skills']?.text ?? '';
    if (skillsText.trim().isNotEmpty) {
      buffer.writeln('\nSkills: $skillsText');
    }

    // Add work experience
    if (_workTimeline.isNotEmpty) {
      buffer.writeln('\nWork Experience:');
      for (final work in _workTimeline) {
        buffer.writeln('${work['role']} at ${work['company']}');
      }
    }

    // Add education
    if (_eduTimeline.isNotEmpty) {
      buffer.writeln('\nEducation:');
      for (final edu in _eduTimeline) {
        buffer.writeln('${edu['degree']} from ${edu['school']}');
      }
    }

    return buffer.toString();
  }

  void _addEdu() {
    if (_eduSchool.text.isEmpty ||
        _eduDegree.text.isEmpty ||
        _eduStart == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill University, Degree and Start Date.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _eduTimeline.add({
        'school': _eduSchool.text.trim(),
        'degree': _eduDegree.text.trim(),
        'start': _eduStart,
        'end': _eduEnd,
      });
      _eduSchool.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    void Function(DateTime) onPicked, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 60, 1, 1);
    final last = DateTime(now.year + 10, 12, 31);
    final res = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (res != null) onPicked(res);
  }

  Future<void> _saveResume() async {
    final data = _collectResumeData();

    final title = _controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${_controllers['name']!.text} Resume';

    final resume = SavedResume(
      id:
          widget.existingResume?.id ??
          ResumeStorageService.instance.generateId(),
      title: widget.existingResume?.title ?? title,
      template: 'Modern',
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    await ResumeStorageService.instance.saveOrUpdate(resume);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Modern Resume saved!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Colors.purple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Resume'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: (choice) async {
              if (!PremiumService.isPremium) {
                PremiumService.showUpgradeDialog(context, 'Sharing');
                return;
              }
              final name = _controllers['name']?.text ?? '';
              final resume = SavedResume(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: name.isNotEmpty ? '$name Resume' : 'Modern Resume',
                template: 'Modern',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                data: _collectResumeData(),
              );
              try {
                if (choice == 'EMAIL') {
                  await ShareExportService.instance.shareViaEmail(resume);
                } else if (choice == 'WHATSAPP') {
                  await ShareExportService.instance.shareViaWhatsApp(resume);
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'EMAIL',
                child: ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Share via Email (Premium)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'WHATSAPP',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share via WhatsApp (Premium)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(18),
            children: [
              // Photo box only
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Center(
                    child: ProfilePhotoPicker(
                      initialBase64: _profilePhotoB64,
                      onChanged: _onPhotoChanged,
                      size: 96,
                      buttonBelow: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Contact box: Full Name, Email, Phone
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modernContactRow(
                        null,
                        _controllers['name']!,
                        'Full Name',
                        focusNode: _focusNodes['name'],
                        bold: true,
                        autofillHints: const [AutofillHints.name],
                      ),
                      _modernContactRow(
                        null,
                        _controllers['email']!,
                        'Email',
                        focusNode: _focusNodes['email'],
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                      _modernContactRow(
                        null,
                        _controllers['phone']!,
                        'Phone Number',
                        focusNode: _focusNodes['phone'],
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // LinkedIn box only
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _modernContactRow(
                    Icons.link,
                    _controllers['linkedin']!,
                    'LinkedIn URL',
                    focusNode: _focusNodes['linkedin'],
                    keyboardType: TextInputType.url,
                    autofillHints: const [AutofillHints.url],
                    suffixIcon: IconButton(
                      tooltip: 'Open LinkedIn',
                      icon: const Icon(Icons.open_in_new),
                      color: Colors.purple,
                      onPressed: () async {
                        final raw = _controllers['linkedin']!.text.trim();
                        if (raw.isEmpty) return;
                        await _openUrl(raw);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // AI-Enhanced Summary Section
              Card(
                color: Colors.white, // Clear, high-contrast background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accent.withOpacity(0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.purple, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Professional Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.auto_awesome,
                            color: Color.fromARGB(255, 157, 152, 202),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AIEnhancedTextField(
                        controller: _controllers['summary']!,
                        label: 'Summary',
                        hintText: 'Write a compelling professional summary...',
                        section: 'summary',
                        maxLines: 4,
                        enableAI: true,
                      ),
                      const SizedBox(height: 12),
                      // AI Summary Generator
                      if (_controllers['name']!.text.isNotEmpty)
                        AISummaryGenerator(
                          name: _controllers['name']!.text,
                          targetRole: 'Professional', // Can be made dynamic
                          skills: (_controllers['skills']?.text ?? '')
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          experience: _workTimeline
                              .map((w) => (w['role'] ?? '').toString())
                              .cast<String>()
                              .toList(),
                          onGenerated: (summary) {
                            setState(() {
                              _controllers['summary']!.text = summary;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Skills (no star ratings; searchable + manual input via shared widget)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build, color: Colors.amber, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Skills',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Shared picker field handles catalog + typed custom skills
                      SkillsPickerField(
                        controller: _controllers['skills']!,
                        label: 'Skills',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Work Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🏢', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Work Experience',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._workTimeline.map(
                        (w) => _timelineTile(
                          title: w['role'],
                          subtitle: w['company'],
                          start: w['start'],
                          end: w['end'],
                          color: accent,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _workCompany,
                              decoration: const InputDecoration(
                                labelText: 'Company',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _workRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workStart == null
                                    ? 'Start Date'
                                    : "${_workStart!.year}-${_workStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workStart = d),
                                initial: _workStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workEnd == null
                                    ? 'End Date'
                                    : "${_workEnd!.year}-${_workEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workEnd = d),
                                initial: _workEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // AI Bullet Point Generator for Work Experience
                      if (_workCompany.text.isNotEmpty &&
                          _workRole.text.isNotEmpty)
                        AIBulletPointGenerator(
                          jobTitle: _workRole.text,
                          company: _workCompany.text,
                          description:
                              'Professional experience in ${_workRole.text} at ${_workCompany.text}',
                          onGenerated: (bulletPoints) {
                            setState(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Generated ${bulletPoints.length} bullet points!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: _addWork,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Education Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🎓', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Education',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._eduTimeline.map(
                        (e) => _timelineTile(
                          title: e['degree'],
                          subtitle: e['school'],
                          start: e['start'],
                          end: e['end'],
                          color: Colors.teal,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _eduSchool,
                              decoration: const InputDecoration(
                                labelText: 'University',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _eduDegree,
                              decoration: const InputDecoration(
                                labelText: 'Degree',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduStart == null
                                    ? 'Start Date'
                                    : "${_eduStart!.year}-${_eduStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduStart = d),
                                initial: _eduStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduEnd == null
                                    ? 'End Date'
                                    : "${_eduEnd!.year}-${_eduEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduEnd = d),
                                initial: _eduEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: _addEdu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Certifications
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Certifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controllers['certifications'],
                        decoration: const InputDecoration(
                          labelText: 'Add certifications (comma separated)',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _controllers['certifications']!.text
                            .split(',')
                            .where((c) => c.trim().isNotEmpty)
                            .map(
                              (c) => Chip(
                                label: Text(c.trim()),
                                avatar: const Icon(Icons.verified),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Achievements & Hobbies
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Achievements & Hobbies',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controllers['achievements'],
                        decoration: const InputDecoration(
                          labelText: 'Achievements (comma separated)',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controllers['hobbies'],
                        decoration: const InputDecoration(
                          labelText: 'Hobbies (comma separated)',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ..._controllers['achievements']!.text
                              .split(',')
                              .where((a) => a.trim().isNotEmpty)
                              .map(
                                (a) => Chip(
                                  label: Text(a.trim()),
                                  avatar: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                ),
                              ),
                          ..._controllers['hobbies']!.text
                              .split(',')
                              .where((h) => h.trim().isNotEmpty)
                              .map(
                                (h) => Chip(
                                  label: Text(h.trim()),
                                  avatar: const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ATS Optimization Panel
              ATSOptimizationPanel(
                content: _getResumeContent(),
                jobDescription:
                    'Paste job description here for better ATS optimization',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Modern Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveResume,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernContactRow(
    IconData? icon,
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextInputAction inputAction = TextInputAction.next,
    Iterable<String>? autofillHints,
    bool bold = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: inputAction,
        autofillHints: autofillHints,
        autocorrect:
            !(keyboardType == TextInputType.emailAddress ||
                keyboardType == TextInputType.url),
        cursorColor: Colors.purple,
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: keyboardType == TextInputType.phone
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
              ]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null
              ? null
              : IgnorePointer(
                  ignoring: true,
                  child: Icon(icon, color: Colors.purple, size: 18),
                ),
          suffixIcon: suffixIcon,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.purple.shade300, width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String raw) async {
    // Normalize URL (prepend https if missing scheme)
    var url = raw.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  // Small footprint icon button for header social links
  Widget _compactIconButton({
    required IconData icon,
    required Color color,
    String? tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _timelineTile({
    required String title,
    required String subtitle,
    required DateTime? start,
    required DateTime? end,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 40, color: color.withOpacity(0.4)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.black87)),
                Text(
                  '${start != null ? "${start.year}-${start.month.toString().padLeft(2, '0')}" : ''}'
                  ' - '
                  '${end != null ? "${end.year}-${end.month.toString().padLeft(2, '0')}" : 'Present'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
