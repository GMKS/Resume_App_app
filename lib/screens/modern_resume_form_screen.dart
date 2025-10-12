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
import '../services/ai_resume_service.dart';
import 'modern_template_selection_screen.dart';

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
  List<String> _summaryIdeas = [];

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
  final _eduCollege = TextEditingController();
  final _eduDegree = TextEditingController();
  DateTime? _eduStart, _eduEnd;
  bool _atsFriendly = false;

  // Collapsible section states - all sections start collapsed
  Map<String, bool> _sectionExpanded = {
    'photo': false,
    'contact': false,
    'linkedin': false,
    'summary': false,
    'skills': false,
    'work': false,
    'education': false,
    'certifications': false,
    'achievements': false,
    'hobbies': false,
  };

  // --- Overlap detection helpers (month granularity) ---
  bool _datesOverlap(DateTime? s1, DateTime? e1, DateTime? s2, DateTime? e2) {
    if (s1 == null || s2 == null) return false; // need starts to compare
    final end1 = e1 ?? DateTime(9999, 12, 31);
    final end2 = e2 ?? DateTime(9999, 12, 31);
    int ym(DateTime d) => d.year * 12 + d.month;
    final s1m = ym(DateTime(s1.year, s1.month));
    final e1m = ym(DateTime(end1.year, end1.month));
    final s2m = ym(DateTime(s2.year, s2.month));
    final e2m = ym(DateTime(end2.year, end2.month));
    return s1m <= e2m && s2m <= e1m;
  }

  List<String> _findOverlapsForTimeline(
    List<Map<String, dynamic>> items, {
    String label = 'Item',
  }) {
    final msgs = <String>[];
    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        final s1 = items[i]['start'] as DateTime?;
        final e1 = items[i]['end'] as DateTime?;
        final s2 = items[j]['start'] as DateTime?;
        final e2 = items[j]['end'] as DateTime?;
        if (_datesOverlap(s1, e1, s2, e2)) {
          msgs.add('$label ${i + 1} overlaps with $label ${j + 1}');
        }
      }
    }
    return msgs;
  }

  void _onPhotoChanged(String? b64) {
    setState(() => _profilePhotoB64 = b64);
  }

  @override
  void initState() {
    super.initState();
    // Hydrate form if editing an existing resume
    final existing = widget.existingResume;
    if (existing != null) {
      final info = Map<String, dynamic>.from(
        existing.data['personalInfo'] ?? {},
      );
      _controllers['name']!.text = (info['name'] ?? '').toString();
      _controllers['email']!.text = (info['email'] ?? '').toString();
      _controllers['phone']!.text = (info['phone'] ?? '').toString();
      _controllers['linkedin']!.text = (info['linkedin'] ?? '').toString();
      _profilePhotoB64 =
          (info['profilePhotoBase64'] ?? '').toString().isNotEmpty
          ? (info['profilePhotoBase64'] as String)
          : null;
      _controllers['summary']!.text = (existing.data['summary'] ?? '')
          .toString();
      // Skills can be list or csv
      if (existing.data['skills'] is List) {
        final list = List<String>.from(existing.data['skills']);
        _controllers['skills']!.text = list.join(', ');
      } else if (existing.data['skillsCsv'] is String) {
        _controllers['skills']!.text = existing.data['skillsCsv'];
      }
      // Work timeline
      if (existing.data['workExperience'] is List) {
        for (final w in existing.workExperience) {
          _workTimeline.add({
            'company': (w['company'] ?? '').toString(),
            'role': (w['role'] ?? '').toString(),
            'start': _tryParseDate(w['start']),
            'end': _tryParseDate(w['end']),
          });
        }
      }
      // Education timeline
      if (existing.data['education'] is List) {
        for (final e in existing.education) {
          _eduTimeline.add({
            'school': (e['school'] ?? '').toString(),
            'college': (e['college'] ?? '').toString(),
            'degree': (e['degree'] ?? '').toString(),
            'start': _tryParseDate(e['start']),
            'end': _tryParseDate(e['end']),
          });
        }
      }
      // Certifications / achievements / hobbies
      _controllers['certifications']!.text =
          (existing.data['certifications'] ?? '').toString();
      _controllers['achievements']!.text = (existing.data['achievements'] ?? '')
          .toString();
      _controllers['hobbies']!.text = (existing.data['hobbies'] ?? '')
          .toString();
      // Load ATS flag
      try {
        _atsFriendly =
            (existing.data['ats_friendly'] ?? '').toString() == 'true';
      } catch (_) {}
    }
  }

  DateTime? _tryParseDate(dynamic iso) {
    if (iso == null) return null;
    try {
      return DateTime.tryParse(iso.toString());
    } catch (_) {
      return null;
    }
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
    _eduCollege.dispose();
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
              'college': e['college'],
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
      // Persist ATS-friendly choice for exporter routing
      'ats_friendly': _atsFriendly ? 'true' : 'false',
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

  Future<void> _generateSummaryBullets() async {
    final skills = _controllers['skills']!.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (skills.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one skill to generate ideas'),
          ),
        );
      }
      return;
    }
    try {
      // Use target role as name field for now; can be extended later
      final ideas = await AIResumeService.generateBulletPoints(
        jobTitle: 'Professional Summary',
        company: '',
        description: 'Key skills: ${skills.join(', ')}',
        count: 4,
      );
      if (mounted) setState(() => _summaryIdeas = ideas);
    } catch (_) {
      if (mounted) setState(() => _summaryIdeas = []);
    }
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
        'college': _eduCollege.text.trim(),
        'degree': _eduDegree.text.trim(),
        'start': _eduStart,
        'end': _eduEnd,
      });
      _eduSchool.clear();
      _eduCollege.clear();
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
    // Commit any pending inputs not yet added to timelines
    _commitPendingInputs();
    // Enforce: block save when overlaps exist
    final workOverlaps = _findOverlapsForTimeline(
      _workTimeline,
      label: 'Experience',
    );
    final eduOverlaps = _findOverlapsForTimeline(
      _eduTimeline,
      label: 'Education',
    );
    if (workOverlaps.isNotEmpty || eduOverlaps.isNotEmpty) {
      final parts = <String>[];
      if (workOverlaps.isNotEmpty) parts.add('Work Experience');
      if (eduOverlaps.isNotEmpty) parts.add('Education');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save: overlapping dates found in ${parts.join(' and ')}. Please resolve before saving.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
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

  void _commitPendingInputs() {
    // Add pending work if fields are filled but 'Add' wasn't tapped
    if (_workCompany.text.trim().isNotEmpty &&
        _workRole.text.trim().isNotEmpty &&
        _workStart != null) {
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
    }
    // Add pending education if fields are filled but 'Add' wasn't tapped
    if (_eduSchool.text.trim().isNotEmpty &&
        _eduDegree.text.trim().isNotEmpty &&
        _eduStart != null) {
      _eduTimeline.add({
        'school': _eduSchool.text.trim(),
        'college': _eduCollege.text.trim(),
        'degree': _eduDegree.text.trim(),
        'start': _eduStart,
        'end': _eduEnd,
      });
      _eduSchool.clear();
      _eduCollege.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;
    }
  }

  void _navigateToColorfulTemplates() async {
    // Commit any pending inputs before navigating
    _commitPendingInputs();

    // Save current resume data
    final data = _collectResumeData();
    final currentResume = SavedResume(
      id:
          widget.existingResume?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _controllers['name']!.text.trim().isNotEmpty
          ? '${_controllers['name']!.text.trim()} Resume'
          : 'Modern Resume',
      template: 'Modern',
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      data: data,
    );

    // Navigate to template selection
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ModernTemplateSelectionScreen(resume: currentResume),
      ),
    );
  }

  // Collapsible card wrapper for Modern resume sections
  Widget _modernCollapsibleCard({
    required String title,
    required String sectionKey,
    required Widget child,
    IconData? icon,
    Color? accentColor,
  }) {
    const defaultAccent = Colors.purple;
    final accent = accentColor ?? defaultAccent;
    final isExpanded = _sectionExpanded[sectionKey] ?? false;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withOpacity(0.25)),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _sectionExpanded[sectionKey] = !isExpanded;
                });
              },
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: accent, size: 28),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    size: 24,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[const SizedBox(height: 16), child],
          ],
        ),
      ),
    );
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
                  await ShareExportService(context).shareViaEmail(resume);
                } else if (choice == 'WHATSAPP') {
                  await ShareExportService(context).shareViaWhatsApp(resume);
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
              _modernCollapsibleCard(
                title: 'Profile Photo',
                sectionKey: 'photo',
                icon: Icons.person,
                child: Center(
                  child: ProfilePhotoPicker(
                    initialBase64: _profilePhotoB64,
                    onChanged: _onPhotoChanged,
                    size: 96,
                    buttonBelow: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Contact box: Full Name, Email, Phone
              _modernCollapsibleCard(
                title: 'Contact Information',
                sectionKey: 'contact',
                icon: Icons.contact_page,
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
              const SizedBox(height: 18),
              // LinkedIn box only
              _modernCollapsibleCard(
                title: 'LinkedIn Profile',
                sectionKey: 'linkedin',
                icon: Icons.business,
                child: _modernContactRow(
                  Icons.business,
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
              const SizedBox(height: 18),
              // AI-Enhanced Summary Section
              _modernCollapsibleCard(
                title: 'Professional Summary',
                sectionKey: 'summary',
                icon: Icons.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.format_list_bulleted),
                          label: const Text('Generate bullet ideas'),
                          onPressed: _generateSummaryBullets,
                        ),
                        const SizedBox(width: 12),
                        if (_summaryIdeas.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _summaryIdeas
                                  .map(
                                    (idea) => ActionChip(
                                      label: Text(
                                        idea,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final cur =
                                              _controllers['summary']!.text;
                                          _controllers['summary']!.text =
                                              cur.isEmpty
                                              ? idea
                                              : '$cur\n• $idea';
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
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
              const SizedBox(height: 18),
              // Skills (no star ratings; searchable + manual input via shared widget)
              _modernCollapsibleCard(
                title: 'Skills',
                sectionKey: 'skills',
                icon: Icons.build,
                accentColor: Colors.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shared picker field handles catalog + typed custom skills
                    SkillsPickerField(
                      controller: _controllers['skills']!,
                      label: 'Skills',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Work Timeline
              _modernCollapsibleCard(
                title: 'Work Experience',
                sectionKey: 'work',
                icon: Icons.work,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overlap warning for work items
                    Builder(
                      builder: (context) {
                        final overlaps = _findOverlapsForTimeline(
                          _workTimeline,
                          label: 'Experience',
                        );
                        if (overlaps.isEmpty) return const SizedBox(height: 12);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Overlapping work experience dates detected',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...overlaps
                                    .map(
                                      (m) => Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          m,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ..._workTimeline.map(
                      (w) => _timelineTile(
                        title: w['role'],
                        subtitle: w['company'],
                        start: w['start'],
                        end: w['end'],
                        color: Colors.purple,
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
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: _addWork,
                      ),
                    ),
                  ],
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
                      // Overlap warning for education items
                      Builder(
                        builder: (context) {
                          final overlaps = _findOverlapsForTimeline(
                            _eduTimeline,
                            label: 'Education',
                          );
                          if (overlaps.isEmpty)
                            return const SizedBox(height: 12);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Overlapping education dates detected',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...overlaps
                                      .map(
                                        (m) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            m,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ..._eduTimeline.map(
                        (e) => _timelineTile(
                          title: e['degree'],
                          subtitle: [e['school'], e['college']]
                              .whereType<String>()
                              .where((s) => s.trim().isNotEmpty)
                              .join(' • '),
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
                              controller: _eduCollege,
                              decoration: const InputDecoration(
                                labelText: 'College',
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
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _atsFriendly,
                onChanged: (v) => setState(() => _atsFriendly = v),
                title: const Text('ATS-friendly formatting'),
                subtitle: const Text(
                  'Simplifies layout and headings for better ATS parsing.',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.palette),
                  label: const Text('Choose Colorful Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.withOpacity(0.1),
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: accent),
                  ),
                  onPressed: _navigateToColorfulTemplates,
                ),
              ),
              const SizedBox(height: 16),
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
