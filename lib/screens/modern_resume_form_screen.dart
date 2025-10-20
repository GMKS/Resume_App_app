import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/profile_photo_picker.dart';
import '../services/premium_service.dart';
import '../services/share_export_service.dart';
import '../services/ai_text_enhancement_service.dart';
// skills handled via shared SkillsPickerField; no direct SkillsService import needed here
import '../widgets/skills_picker_field.dart';
import '../widgets/phone_input_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_resume_service.dart';
import 'modern_template_selection_screen.dart';
import 'modern_resume_preview.dart';

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
    'jobTitle': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
    'linkedin': TextEditingController(),
    'github': TextEditingController(),
    'portfolio': TextEditingController(),
    'certifications': TextEditingController(),
    'achievements': TextEditingController(),
    'hobbies': TextEditingController(),
    'customField1': TextEditingController(),
    'customField2': TextEditingController(),
    'customField3': TextEditingController(),
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
  final _workDescription = TextEditingController();
  DateTime? _workStart, _workEnd;
  bool _workCurrentlyWorking = false;
  int? _editingWorkIndex; // Track which work entry is being edited

  final _eduSchool = TextEditingController();
  final _eduCollege = TextEditingController();
  final _eduDegree = TextEditingController();
  DateTime? _eduStart, _eduEnd;
  int? _editingEduIndex; // Track which education entry is being edited
  bool _atsFriendly = false;

  // Custom fields as a list
  final List<String> _customFields = [];
  final _customFieldController = TextEditingController();

  // Collapsible section states - all sections collapsed by default
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
    'customFields': false,
  };

  // Bottom navigation state
  int _bottomIndex = 1; // Default to Preview

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
      // Job title
      _controllers['jobTitle']!.text = (existing.data['jobTitle'] ?? '')
          .toString();
      // Custom fields - load from list
      if (existing.data['customFields'] is List) {
        _customFields.clear();
        for (final field in existing.data['customFields']) {
          if (field.toString().isNotEmpty) {
            _customFields.add(field.toString());
          }
        }
      }
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
      final workData = {
        'company': _workCompany.text.trim(),
        'role': _workRole.text.trim(),
        'description': _workDescription.text.trim(),
        'start': _workStart,
        'end': _workEnd,
        'currentlyWorking': _workCurrentlyWorking,
      };

      if (_editingWorkIndex != null) {
        // Update existing entry
        _workTimeline[_editingWorkIndex!] = workData;
        _editingWorkIndex = null;
      } else {
        // Add new entry
        _workTimeline.add(workData);
      }

      _workCompany.clear();
      _workRole.clear();
      _workDescription.clear();
      _workStart = null;
      _workEnd = null;
      _workCurrentlyWorking = false;

      // Keep work section expanded for easy multiple entries
    });
  }

  void _editWork(int index) {
    setState(() {
      final work = _workTimeline[index];
      _workCompany.text = work['company'] ?? '';
      _workRole.text = work['role'] ?? '';
      _workDescription.text = work['description'] ?? '';
      _workStart = work['start'];
      _workEnd = work['end'];
      _workCurrentlyWorking = work['currentlyWorking'] ?? false;
      _editingWorkIndex = index;

      // Expand the section for editing
      _sectionExpanded['work'] = true;
    });
  }

  void _cancelEditWork() {
    setState(() {
      _workCompany.clear();
      _workRole.clear();
      _workDescription.clear();
      _workStart = null;
      _workEnd = null;
      _workCurrentlyWorking = false;
      _editingWorkIndex = null;
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
    _workDescription.dispose();
    _eduSchool.dispose();
    _eduDegree.dispose();
    _eduCollege.dispose();
    _customFieldController.dispose();
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
      'jobTitle': _controllers['jobTitle']!.text.trim(),
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
              'description': e['description'] ?? '',
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
              'currentlyWorking': e['currentlyWorking'] ?? false,
            },
          )
          .toList(),
      // also include classic JSON-string fields expected by older exporter
      'workExperiences': jsonEncode(
        _workTimeline
            .map(
              (e) => {
                'jobTitle': e['role'] ?? '',
                'company': e['company'] ?? '',
                'description': e['description'] ?? '',
                'startDate': (e['start'] as DateTime?) != null
                    ? "${(e['start'] as DateTime).month.toString().padLeft(2, '0')}/${(e['start'] as DateTime).day.toString().padLeft(2, '0')}/${(e['start'] as DateTime).year}"
                    : '',
                'endDate': (e['end'] as DateTime?) != null
                    ? "${(e['end'] as DateTime).month.toString().padLeft(2, '0')}/${(e['end'] as DateTime).day.toString().padLeft(2, '0')}/${(e['end'] as DateTime).year}"
                    : (e['currentlyWorking'] == true ? 'Present' : ''),
                'achievements': '',
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
                'degree': e['degree'] ?? '',
                'institution': e['school'] ?? '',
                'school': e['school'] ?? '',
                'college': e['college'] ?? '',
                'startDate': (e['start'] as DateTime?) != null
                    ? "${(e['start'] as DateTime).month.toString().padLeft(2, '0')}/${(e['start'] as DateTime).day.toString().padLeft(2, '0')}/${(e['start'] as DateTime).year}"
                    : '',
                'endDate': (e['end'] as DateTime?) != null
                    ? "${(e['end'] as DateTime).month.toString().padLeft(2, '0')}/${(e['end'] as DateTime).day.toString().padLeft(2, '0')}/${(e['end'] as DateTime).year}"
                    : '',
                'description': '',
              },
            )
            .toList(),
      ),
      'certifications': _controllers['certifications']!.text,
      'achievements': _controllers['achievements']!.text,
      'hobbies': _controllers['hobbies']!.text,
      'customFields': _customFields,
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
    // Make dates optional - only require school and degree
    if (_eduSchool.text.isEmpty || _eduDegree.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill University and Degree.')),
        );
      }
      return;
    }
    setState(() {
      final eduData = {
        'school': _eduSchool.text.trim(),
        'college': _eduCollege.text.trim(),
        'degree': _eduDegree.text.trim(),
        'start': _eduStart,
        'end': _eduEnd,
      };

      if (_editingEduIndex != null) {
        // Update existing entry
        _eduTimeline[_editingEduIndex!] = eduData;
        _editingEduIndex = null;
      } else {
        // Add new entry
        _eduTimeline.add(eduData);
      }

      _eduSchool.clear();
      _eduCollege.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;

      // Keep education section expanded for easy multiple entries
    });
  }

  void _editEdu(int index) {
    setState(() {
      final edu = _eduTimeline[index];
      _eduSchool.text = edu['school'] ?? '';
      _eduCollege.text = edu['college'] ?? '';
      _eduDegree.text = edu['degree'] ?? '';
      _eduStart = edu['start'];
      _eduEnd = edu['end'];
      _editingEduIndex = index;

      // Expand the section for editing
      _sectionExpanded['education'] = true;
    });
  }

  void _cancelEditEdu() {
    setState(() {
      _eduSchool.clear();
      _eduCollege.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;
      _editingEduIndex = null;
    });
  }

  // Helper method to auto-collapse sections after data entry (except work/education)
  void _autoCollapseSection(String sectionKey) {
    // Only auto-collapse if not work or education section
    if (sectionKey != 'work' && sectionKey != 'education') {
      setState(() {
        _sectionExpanded[sectionKey] = false;
      });
    }
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
    // TEMPORARILY DISABLED: overlapping dates validation for testing
    /* 
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
    */
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

  void _previewResume() {
    // Commit any pending inputs not yet added to timelines
    _commitPendingInputs();

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernResumePreview(resume: resume),
      ),
    );
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

    // Navigate to template selection and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ModernTemplateSelectionScreen(resume: currentResume),
      ),
    );

    // If user selected a template and returned, refresh the form state
    if (result != null && mounted) {
      setState(() {
        // Refresh to ensure any changes are reflected
      });
    }
  }

  // Advanced AI Suggestions Dialog for Professional Summary
  Future<void> _showAISuggestions(BuildContext context) async {
    // First, ask user what they want to generate
    final userQuery = await showDialog<String>(
      context: context,
      builder: (context) {
        final queryController = TextEditingController();
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.deepPurple),
              SizedBox(width: 8),
              Expanded(child: Text('AI Summary Generator')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you like to generate?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter keywords or describe your professional background:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: queryController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., "Software Engineer with 5 years in AI/ML" or "Marketing professional with digital strategy expertise"',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, queryController.text);
              },
            ),
          ],
        );
      },
    );

    // If user cancelled or didn't enter anything, return
    if (userQuery == null || userQuery.trim().isEmpty) {
      return;
    }

    // Collect context from user's current data
    final jobTitle = _controllers['jobTitle']?.text ?? '';
    final skills = _controllers['skills']?.text ?? '';
    final currentSummary = _controllers['summary']?.text ?? '';

    // Build a seed text for AI from available context + user query
    final seedText = [
      userQuery, // User's specific query is most important
      if (jobTitle.isNotEmpty) jobTitle,
      if (skills.isNotEmpty) 'Skills: $skills',
      if (currentSummary.isNotEmpty) currentSummary,
    ].join(' | ');

    // Generate AI suggestions based on user query
    List<String> suggestions =
        AITextEnhancementService.generateEnhancedSuggestions(seedText);

    // Add generic suggestions tailored to user query if we don't have enough
    if (suggestions.length < 4) {
      suggestions.addAll([
        'Results-driven $userQuery with proven track record of delivering high-impact solutions and exceeding organizational objectives.',
        'Dynamic $userQuery with strong analytical skills and dedication to continuous improvement.',
        'Accomplished $userQuery committed to excellence, collaboration, and achieving measurable business outcomes.',
        'Strategic $userQuery with expertise in problem-solving, process optimization, and driving operational efficiency.',
      ]);
    }

    // Ensure we have at least 4 unique suggestions
    final uniqueSuggestions = suggestions.toSet().take(4).toList();

    // Track selected suggestions
    final selectedSuggestions = <int>{};

    // Show dialog with suggestions
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Expanded(child: Text('AI-Generated Suggestions')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Based on: "$userQuery"',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height:
                MediaQuery.of(context).size.height *
                0.6, // Constrain height to 60% of screen
            child: ListView.separated(
              shrinkWrap: false, // Allow proper scrolling
              itemCount: uniqueSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final suggestion = uniqueSuggestions[index];
                final isSelected = selectedSuggestions.contains(index);
                return InkWell(
                  onTap: () {
                    setDialogState(() {
                      if (isSelected) {
                        selectedSuggestions.remove(index);
                      } else {
                        selectedSuggestions.add(index);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.deepPurple.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.deepPurple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.deepPurple,
                          )
                        else
                          const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(
                selectedSuggestions.isEmpty
                    ? 'Select at least one'
                    : 'Apply ${selectedSuggestions.length} suggestion${selectedSuggestions.length > 1 ? 's' : ''}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedSuggestions.isEmpty
                  ? null
                  : () {
                      // Combine selected suggestions
                      final combinedText = selectedSuggestions
                          .map((i) => uniqueSuggestions[i])
                          .join(' ');
                      _controllers['summary']!.text = combinedText;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${selectedSuggestions.length} AI suggestion${selectedSuggestions.length > 1 ? 's' : ''} applied to Professional Summary',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
            ),
          ],
        ), // closes AlertDialog
      ), // closes StatefulBuilder builder
    ); // closes showDialog
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
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0, // Rotate 90° when expanded
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 28, color: accent),
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
        actions: const [], // Remove share icon (moved to bottom nav)
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email Address is required';
                        }
                        if (!value.contains('@')) {
                          return 'Email must contain @ symbol';
                        }
                        final parts = value.split('@');
                        if (parts.length != 2 || parts[1].isEmpty) {
                          return 'Invalid email format';
                        }
                        final domain = parts[1];
                        if (!domain.contains('.')) {
                          return 'Email must include domain (e.g., gmail.com)';
                        }
                        final domainParts = domain.split('.');
                        if (domainParts.any((p) => p.isEmpty)) {
                          return 'Invalid domain format';
                        }
                        return null;
                      },
                    ),
                    PhoneInputWidget(
                      initialPhoneNumber: _controllers['phone']!.text,
                      labelText: 'Phone Number',
                      onChanged: (fullPhoneNumber, countryCode, phoneNumber) {
                        _controllers['phone']!.text = fullPhoneNumber;
                      },
                    ),
                    const SizedBox(height: 8),
                    _modernContactRow(
                      null,
                      _controllers['jobTitle']!,
                      'Job Title (Optional)',
                      keyboardType: TextInputType.text,
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
              // AI-Enhanced Summary Section with Advanced AI Module
              _modernCollapsibleCard(
                title: 'Professional Summary',
                sectionKey: 'summary',
                icon: Icons.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Advanced AI Module',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.deepPurple,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['summary']!,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Professional Summary',
                        hintText:
                            'Write a compelling professional summary or use AI to generate suggestions...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.psychology),
                        label: const Text('Generate AI Suggestions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showAISuggestions(context),
                      ),
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
                    ..._workTimeline.asMap().entries.map((entry) {
                      final index = entry.key;
                      final w = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Experience ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Delete Experience',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _workTimeline.removeAt(index);
                                        if (_editingWorkIndex == index) {
                                          _cancelEditWork();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _timelineTile(
                                title: (w['role'] ?? '').toString(),
                                subtitle: (w['company'] ?? '').toString(),
                                description: (w['description'] ?? '')
                                    .toString(),
                                start: w['start'] as DateTime?,
                                end: w['end'] as DateTime?,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workDescription,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText:
                            'Describe your responsibilities and achievements...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _workStart == null
                                  ? 'Start Date'
                                  : "${_workStart!.month.toString().padLeft(2, '0')}/${_workStart!.day.toString().padLeft(2, '0')}/${_workStart!.year}",
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
                              _workCurrentlyWorking
                                  ? 'Present'
                                  : _workEnd == null
                                  ? 'End Date'
                                  : "${_workEnd!.month.toString().padLeft(2, '0')}/${_workEnd!.day.toString().padLeft(2, '0')}/${_workEnd!.year}",
                            ),
                            onPressed: _workCurrentlyWorking
                                ? null
                                : () => _pickDate(
                                    context,
                                    (d) => setState(() => _workEnd = d),
                                    initial: _workEnd,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Currently Working Here',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _workCurrentlyWorking,
                      onChanged: (value) {
                        setState(() {
                          final newValue = value ?? false;

                          // Check if any existing entry already has "currently working" set
                          if (newValue) {
                            final hasCurrentJob = _workTimeline.any(
                              (entry) => entry['currentlyWorking'] == true,
                            );

                            if (hasCurrentJob && _editingWorkIndex == null) {
                              // Show warning if trying to add a new "current" job
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You already have a current job. Only one position can be marked as "Currently Working".',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            } else if (hasCurrentJob &&
                                _editingWorkIndex != null) {
                              // If editing, check if another entry (not this one) has it set
                              final otherCurrentIndex = _workTimeline
                                  .indexWhere(
                                    (entry) =>
                                        entry['currentlyWorking'] == true &&
                                        _workTimeline.indexOf(entry) !=
                                            _editingWorkIndex,
                                  );
                              if (otherCurrentIndex != -1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Another position is already marked as current. Please uncheck it first.',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                            }
                          }

                          _workCurrentlyWorking = newValue;
                          if (_workCurrentlyWorking) {
                            _workEnd =
                                null; // Clear end date when currently working
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    // Add/Update and Cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_editingWorkIndex != null)
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, size: 20),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _cancelEditWork,
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            _editingWorkIndex != null ? Icons.check : Icons.add,
                            size: 20,
                          ),
                          label: Text(
                            _editingWorkIndex != null ? 'Update' : 'Add',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _addWork,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Education Timeline (Collapsible)
              _modernCollapsibleCard(
                title: 'Education',
                sectionKey: 'education',
                icon: Icons.school,
                accentColor: Colors.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overlap warning for education items
                    Builder(
                      builder: (context) {
                        final overlaps = _findOverlapsForTimeline(
                          _eduTimeline,
                          label: 'Education',
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
                    ..._eduTimeline.asMap().entries.map((entry) {
                      final index = entry.key;
                      final e = entry.value;
                      return _timelineTile(
                        title: e['degree'],
                        subtitle: [e['school'], e['college']]
                            .whereType<String>()
                            .where((s) => s.trim().isNotEmpty)
                            .join(' • '),
                        start: e['start'],
                        end: e['end'],
                        color: Colors.teal,
                        onEdit: () => _editEdu(index),
                        onDelete: () {
                          setState(() {
                            _eduTimeline.removeAt(index);
                            if (_editingEduIndex == index) {
                              _cancelEditEdu();
                            }
                          });
                        },
                      );
                    }),
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
                                  : "${_eduStart!.month.toString().padLeft(2, '0')}/${_eduStart!.day.toString().padLeft(2, '0')}/${_eduStart!.year}",
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
                                  : "${_eduEnd!.month.toString().padLeft(2, '0')}/${_eduEnd!.day.toString().padLeft(2, '0')}/${_eduEnd!.year}",
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
                    const SizedBox(height: 16),
                    // Add/Update and Cancel buttons for Education
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_editingEduIndex != null)
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, size: 20),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _cancelEditEdu,
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            _editingEduIndex != null ? Icons.check : Icons.add,
                            size: 20,
                          ),
                          label: Text(
                            _editingEduIndex != null ? 'Update' : 'Add',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _addEdu,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Certifications (Collapsible)
              _modernCollapsibleCard(
                title: 'Certifications',
                sectionKey: 'certifications',
                icon: Icons.verified,
                accentColor: Colors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controllers['certifications'],
                      decoration: const InputDecoration(
                        labelText: 'Add certifications (comma separated)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _controllers['certifications']!.text
                          .split(',')
                          .where((c) => c.trim().isNotEmpty)
                          .map(
                            (c) => Chip(
                              label: Text(c.trim()),
                              avatar: const Icon(Icons.verified, size: 16),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Achievements & Hobbies (Collapsible)
              _modernCollapsibleCard(
                title: 'Achievements & Hobbies',
                sectionKey: 'achievements',
                icon: Icons.emoji_events,
                accentColor: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controllers['achievements'],
                      decoration: const InputDecoration(
                        labelText: 'Achievements (comma separated)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['hobbies'],
                      decoration: const InputDecoration(
                        labelText: 'Hobbies (comma separated)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
              const SizedBox(height: 24),
              // Custom Fields Section - Simplified
              _modernCollapsibleCard(
                title: 'Additional Information',
                sectionKey: 'customFields',
                icon: Icons.add_box,
                accentColor: Colors.deepOrange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display existing custom fields
                    ..._customFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final field = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                field,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _customFields.removeAt(index);
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_customFields.isNotEmpty) const SizedBox(height: 12),
                    // Input field for new custom information
                    TextFormField(
                      controller: _customFieldController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional Information',
                        hintText:
                            'Enter any additional information not covered above...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Add button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          if (_customFieldController.text.trim().isNotEmpty) {
                            setState(() {
                              _customFields.add(
                                _customFieldController.text.trim(),
                              );
                              _customFieldController.clear();
                              // Auto-collapse after adding
                              _sectionExpanded['customFields'] = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
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
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                  ),
                  onPressed: _navigateToColorfulTemplates,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _previewResume,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveResume,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 48,
              ), // Extra bottom padding to ensure buttons are visible on all screens
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accent,
        onTap: (idx) async {
          setState(() => _bottomIndex = idx);
          await _handleBottomNavTap(idx);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.preview), label: 'Preview'),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Save'),
        ],
      ),
    );
  }

  Future<void> _handleBottomNavTap(int idx) async {
    switch (idx) {
      case 0:
        final shouldSave =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Go Home?'),
                content: const Text(
                  'Do you want me to save this Modern Resume?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save & Home'),
                  ),
                ],
              ),
            ) ??
            false;
        if (shouldSave) {
          await _saveResume();
        } else {
          if (context.mounted) Navigator.pop(context);
        }
        break;
      case 1:
        _previewResume();
        break;
      case 2:
        await _showShareOptions();
        break;
      case 3:
        await _saveResume();
        break;
    }
  }

  Future<void> _showShareOptions() async {
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
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('Share via Email'),
              onTap: () async {
                Navigator.pop(ctx);
                await ShareExportService(context).shareViaEmail(resume);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined, color: Colors.teal),
              title: const Text('Share via WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                await ShareExportService(context).shareViaWhatsApp(resume);
              },
            ),
          ],
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
    String? Function(String?)? validator,
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
        autocorrect: true,
        enableSuggestions: true,
        cursorColor: Colors.purple,
        textAlignVertical: TextAlignVertical.center,
        validator: validator,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
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
    String? description,
    required DateTime? start,
    required DateTime? end,
    required Color color,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
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
            Container(
              width: 2,
              height: description != null && description.isNotEmpty ? 60 : 40,
              color: color.withOpacity(0.4),
            ),
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
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Text(
                  '${start != null ? "${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}/${start.year}" : ''}'
                  ' - '
                  '${end != null ? "${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}/${end.year}" : 'Present'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
