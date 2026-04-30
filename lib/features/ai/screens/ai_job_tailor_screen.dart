import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/ai_resume_service.dart';
import '../../../core/services/resume_import_service.dart';
import '../../../core/services/resume_import_mapper.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/resume_json.dart';
import '../../../core/services/resume_version_service.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;
import '../../editor/screens/resume_editor_screen.dart' show currentResumeProvider;
import '../services/resume_job_match_service.dart';

/// Screen to tailor an existing resume for a specific job description
class AiJobTailorScreen extends ConsumerStatefulWidget {
  /// If passed, a specific resume is pre-selected
  final String? resumeId;

  const AiJobTailorScreen({super.key, this.resumeId});

  @override
  ConsumerState<AiJobTailorScreen> createState() => _AiJobTailorScreenState();
}

class _AiJobTailorScreenState extends ConsumerState<AiJobTailorScreen> {
  final _jobDescController = TextEditingController();
  bool _isTailoring = false;
  bool _showResult = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;
  ResumeModel? _selectedResume;
  List<ResumeModel> _allResumes = [];
  String _apiKey = '';

  // Import Resume mode
  bool _importMode = false;
  bool _isParsing = false;
  bool _isImportingFile = false;
  bool _showParsedResult = false;
  Map<String, dynamic>? _parsedData;
  String? _importedFileName;
  String? _importSuccessMessage;
  String? _importSuccessResumeId;
  Timer? _importSuccessTimer;

  @override
  void initState() {
    super.initState();
    _loadResumes();
    _loadApiKey();
  }

  @override
  void dispose() {
    _clearTransientMessages();
    _resetImportSuccessState();
    _jobDescController.dispose();
    super.dispose();
  }

  void _clearTransientMessages() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  }

  void _setTailorMode() {
    _clearTransientMessages();
    setState(() {
      _resetImportSuccessState();
      _importMode = false;
      _showParsedResult = false;
      _parsedData = null;
      _importedFileName = null;
      _errorMessage = null;
    });
  }

  Future<void> _setImportMode({bool openPicker = false}) async {
    _clearTransientMessages();
    setState(() {
      _resetImportSuccessState();
      _importMode = true;
      _showResult = false;
      _result = null;
      _errorMessage = null;
    });

    if (openPicker) {
      await _pickResumeFile();
    }
  }

  Future<void> _pickResumeFile() async {
    if (_isImportingFile || _isParsing) {
      return;
    }

    _clearTransientMessages();
    setState(() {
      _resetImportSuccessState();
      _isImportingFile = true;
      _errorMessage = null;
      _showParsedResult = false;
      _parsedData = null;
    });

    try {
      final importedFile = await ResumeImportService.pickResumeFile();
      if (!mounted || importedFile == null) {
        if (mounted) {
          setState(() => _isImportingFile = false);
        }
        return;
      }

      _jobDescController.text = importedFile.extractedText;

      setState(() {
        _isImportingFile = false;
        _importedFileName = importedFile.fileName;
      });

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Loaded ${importedFile.fileName}. Review the text, then tap Analyze & Import Resume.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } on ResumeImportException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isImportingFile = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isImportingFile = false;
        _errorMessage = 'Could not load the selected file. ${e.toString()}';
      });
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _apiKey = prefs.getString('gemini_api_key') ?? '');
  }

  void _loadResumes() {
    final resumes = StorageService.getAllResumes();
    setState(() {
      _allResumes = resumes;
      if (widget.resumeId != null) {
        _selectedResume = resumes.firstWhere(
          (r) => r.id == widget.resumeId,
          orElse: () => resumes.isNotEmpty ? resumes.first : resumes.first,
        );
      } else if (resumes.isNotEmpty) {
        _selectedResume = resumes.first;
      }
    });
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .cast<String>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => item.map(
              (key, val) => MapEntry(key.toString(), val),
            ))
        .toList(growable: false);
  }

  List<String> _mergeStringLists(List<String> left, List<String> right) {
    return <String>{...left, ...right}.toList(growable: false);
  }

  Future<void> _tailorResume() async {
    if (_selectedResume == null) {
      setState(() => _errorMessage = 'Please select a resume first.');
      return;
    }
    if (_jobDescController.text.trim().length < 50) {
      setState(() => _errorMessage = 'Please paste a more complete job description (at least 50 characters).');
      return;
    }

    setState(() {
      _isTailoring = true;
      _errorMessage = null;
      _showResult = false;
    });

    try {
      final resume = _selectedResume!;
      final jobDescription = _jobDescController.text.trim();
      final localMatch = ResumeJobMatchService.analyze(
        resume: resume,
        jobDescription: jobDescription,
      );
      final result = Map<String, dynamic>.from(localMatch.toMap())
        ..putIfAbsent('tailoredSummary', () => '')
        ..putIfAbsent('tailoredExperience', () => const <dynamic>[]);

      if (_apiKey.isEmpty) {
        result['analysisNotice'] =
            'Match analysis is ready. Add a Groq API key to generate tailored summary and experience rewrites.';
      } else {
        try {
          await ResumeVersionService.saveVersion(
            resume: resume,
            changeType: 'ai_tailor',
            description: 'Before AI tailoring for job',
          );

          final resumeMap = ResumeJson.toMap(resume);
          final aiResult = await AiResumeService.tailorResumeForJob(
            apiKey: _apiKey,
            resumeJson: resumeMap,
            jobDescription: jobDescription,
          );

          result['tailoredSummary'] =
              aiResult['tailoredSummary'] as String? ?? '';
          result['tailoredExperience'] =
              aiResult['tailoredExperience'] as List? ?? const <dynamic>[];
          result['topSkills'] = _mergeStringLists(
            _stringList(result['topSkills']),
            _stringList(aiResult['topSkills']),
          );
        } on AiUsageLimitException catch (e) {
          result['analysisNotice'] =
              'Match analysis completed, but AI tailoring is currently unavailable. ${e.message}';
        } on AiConfigException catch (e) {
          result['analysisNotice'] =
              'Match analysis completed, but AI tailoring is not configured. ${e.message}';
        } catch (e) {
          result['analysisNotice'] =
              'Match analysis completed, but AI tailoring could not be generated. ${e.toString()}';
        }
      }

      setState(() {
        _result = result;
        _showResult = true;
        _isTailoring = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isTailoring = false;
      });
    }
  }

  Future<void> _parseResume() async {
    if (_jobDescController.text.trim().length < 50) {
      setState(() => _errorMessage = 'Please paste more resume content (at least 50 characters).');
      return;
    }
    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _resetImportSuccessState();
      _isParsing = true;
      _errorMessage = null;
      _showParsedResult = false;
    });
    _clearTransientMessages();

    try {
      final result = await AiResumeService.parseResumeFromText(
        apiKey: _apiKey,
        resumeText: _jobDescController.text.trim(),
      );
      setState(() {
        _parsedData = result;
        _showParsedResult = true;
        _isParsing = false;
      });
    } on AiConfigException catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = e.message;
      });
      _showApiKeyDialog();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isParsing = false;
      });
    }
  }

  void _resetImportSuccessState() {
    _importSuccessTimer?.cancel();
    _importSuccessTimer = null;
    _importSuccessMessage = null;
    _importSuccessResumeId = null;
  }

  void _clearImportSuccessBanner() {
    if (_importSuccessMessage == null && _importSuccessResumeId == null) {
      _importSuccessTimer?.cancel();
      _importSuccessTimer = null;
      return;
    }

    if (!mounted) {
      _resetImportSuccessState();
      return;
    }

    setState(_resetImportSuccessState);
  }

  void _showImportSuccessBanner(String resumeId) {
    if (!mounted) {
      return;
    }

    _importSuccessTimer?.cancel();
    setState(() {
      _importSuccessMessage = 'Resume imported. Review the extracted sections or keep editing.';
      _importSuccessResumeId = resumeId;
    });
    _importSuccessTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(_resetImportSuccessState);
    });
  }

  Future<void> _applyParsedResume() async {
    if (_parsedData == null || _selectedResume == null) return;

    final resume = _selectedResume!;

    final updatedResume = ResumeImportMapper.applyParsedData(
      resume: resume,
      parsedData: _parsedData!,
    );

    await StorageService.saveResume(updatedResume);
    ref.invalidate(resumesProvider);
    _clearTransientMessages();
    _showImportSuccessBanner(updatedResume.id);

    setState(() {
      _selectedResume = updatedResume;
      _allResumes = _allResumes
          .map((item) => item.id == updatedResume.id ? updatedResume : item)
          .toList(growable: false);
      _showParsedResult = false;
      _parsedData = null;
      _importedFileName = null;
      _jobDescController.clear();
    });
  }

  void _applyToResume() {
    if (_result == null || _selectedResume == null) return;

    final resume = _selectedResume!;
    final tailoredSummary = _result!['tailoredSummary'] as String? ?? '';
    final tailoredExpList = _result!['tailoredExperience'] as List?;
    final topSkills = _result!['topSkills'] as List?;

    // Update objective/summary
    ResumeModel updated = resume.copyWith(
      objective: tailoredSummary.isNotEmpty ? tailoredSummary : resume.objective,
    );

    // Update experience descriptions with tailored content
    if (tailoredExpList != null && tailoredExpList.isNotEmpty && updated.experience.isNotEmpty) {
      final updatedExps = updated.experience.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        
        try {
          if (i < tailoredExpList.length) {
            final tailoredItem = tailoredExpList[i] as Map<String, dynamic>?;
            final tailored = tailoredItem?['tailored'] as String?;
            if (tailored != null && tailored.isNotEmpty) {
              return exp.copyWith(description: tailored);
            }
          }
        } catch (_) {}
        
        return exp;
      }).toList();
      updated = updated.copyWith(experience: updatedExps);
    }

    // Update skills with top matching skills
    if (topSkills != null && topSkills.isNotEmpty) {
      try {
        final newSkills = topSkills.cast<String>().map((skillName) {
          return {
            'name': skillName,
            'level': 'Expert',
          };
        }).toList();
        
        if (newSkills.isNotEmpty) {
          // Create Skill objects from the map data
          // For now, just keep the existing approach
          updated = updated.copyWith(skills: updated.skills);
        }
      } catch (_) {}
    }

    updated = updated.copyWith(updatedAt: DateTime.now());

    StorageService.saveResume(updated);
    ref.invalidate(resumesProvider);
    ref.invalidate(currentResumeProvider(updated.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Resume tailored and saved!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        action: SnackBarAction(
          label: 'Edit',
          textColor: Colors.white,
          onPressed: () => context.push('/editor/${resume.id}'),
        ),
      ),
    );

    setState(() {
      _showResult = false;
      _result = null;
    });
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.key, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Groq API Key (Free)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI features require a free Groq API key. No credit card needed!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visit: console.groq.com → Sign up → API Keys → Create key')),
                );
              },
              child: const Text(
                'Get FREE key → console.groq.com',
                style: TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Paste API Key',
                prefixIcon: const Icon(Iconsax.key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gemini_api_key', key);
                setState(() => _apiKey = key);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveTooltip(
          message: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
        ),
        title: Text(_importMode ? 'Import Resume' : 'Resume Match & Tailor'),
        actions: [
          AdaptiveTooltip(
            message: _apiKey.isNotEmpty ? 'API Key configured' : 'Add API Key',
            button: true,
            child: IconButton(
              onPressed: _showApiKeyDialog,
              icon: Icon(
                Iconsax.key,
                color:
                    _apiKey.isNotEmpty ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _setTailorMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_importMode ? AppColors.info : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.search_normal_1,
                                size: 16,
                                color: !_importMode ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('Match Job',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: !_importMode ? Colors.white : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setImportMode(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _importMode ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.import,
                                size: 16,
                                color: _importMode ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('Import Resume',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _importMode ? Colors.white : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _importMode
                      ? [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.05)]
                      : [AppColors.info.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _importMode
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _importMode
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _importMode ? Iconsax.import : Iconsax.search_normal_1,
                      color: _importMode ? AppColors.primary : AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _importMode ? 'Import from Resume Text' : 'Resume Match Analysis',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _importMode
                              ? 'Paste your existing resume (from Word, PDF, or LinkedIn) and AI will extract all fields and fill your template automatically.'
                              : 'Paste a job description to get a match score, section-by-section gaps, missing skills, and optional AI-tailored rewrites.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Resume selector
            Text(
              'Select Resume',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_allResumes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.document_text, color: AppColors.textTertiary),
                    SizedBox(width: 12),
                    Text('No resumes yet. Create one first.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedResume?.id,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.document_text_1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                isExpanded: true,
                items: _allResumes.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.title, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (id) {
                  setState(() {
                    _resetImportSuccessState();
                    _selectedResume = _allResumes.firstWhere((r) => r.id == id);
                    _showResult = false;
                    _result = null;
                  });
                },
              ),

            const SizedBox(height: 20),

            // Text input
            Text(
              _importMode ? 'Paste Your Resume Here' : 'Job Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_importMode) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isImportingFile || _isParsing ? null : _pickResumeFile,
                  icon: _isImportingFile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.folder_open),
                  label: Text(
                    _isImportingFile
                        ? 'Opening file explorer...'
                        : (_importedFileName == null ? 'Choose Resume File' : 'Choose Another Resume File'),
                  ),
                ),
              ),
              if (_importedFileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected file: $_importedFileName',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _jobDescController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: _importMode
                    ? 'Paste your full resume text here...\n\nAI will extract your name, contact info, work experience, education, skills, projects, and more — and fill all fields automatically.'
                    : 'Paste the full job description here...\n\nThe match engine will extract keywords, score each resume section, flag missing skills, and optionally generate AI rewrites.',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            if (_importSuccessMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Iconsax.tick_circle, color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _importSuccessMessage!,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: _importSuccessResumeId == null
                                    ? null
                                    : () {
                                        _clearImportSuccessBanner();
                                        context.push('/editor/${_importSuccessResumeId!}');
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Edit Resume'),
                              ),
                              TextButton(
                                onPressed: _clearImportSuccessBanner,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isTailoring || _isParsing || _isImportingFile)
                    ? null
                    : (_importMode ? _parseResume : _tailorResume),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _importMode ? AppColors.primary : AppColors.info,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: (_isTailoring || _isParsing || _isImportingFile)
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_importMode ? Iconsax.import : Iconsax.magic_star, color: Colors.white),
                label: Text(
                  _isImportingFile
                      ? 'Loading resume file...'
                      : _isParsing
                      ? 'Analyzing resume...'
                      : _isTailoring
                          ? 'Analyzing resume match...'
                          : (_importMode
                              ? 'Analyze & Import Resume'
                              : (_apiKey.isEmpty
                                  ? 'Analyze Resume Match'
                                  : 'Analyze Match & Tailor with AI')),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                ),
              ),
            ),

            // Job tailor results
            if (!_importMode && _showResult && _result != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _buildResultsSection(),
            ],

            // Import results
            if (_importMode && _showParsedResult && _parsedData != null) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _buildImportResultsSection(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final matchScore = _result!['matchScore'];
    final matchAssessment = _result!['matchAssessment'] as String? ?? '';
    final tailoredSummary = _result!['tailoredSummary'] as String? ?? '';
    final tailoredExperience = _result!['tailoredExperience'] as List? ?? [];
    final topSkills = _stringList(_result!['topSkills']);
    final keywordsExtracted = _stringList(_result!['keywordsExtracted']);
    final keywordsCovered = _stringList(_result!['keywordsCovered']);
    final missingKeywords = _stringList(_result!['missingKeywords']);
    final missingSkills = _stringList(_result!['missingSkills']);
    final sectionScores = _mapList(_result!['sectionScores']);
    final suggestions = _mapList(_result!['suggestions']);
    final analysisNotice = _result!['analysisNotice'] as String? ?? '';
    final engineId = _result!['engineId'] as String? ?? '';
    final engineVersion = _result!['engineVersion'] as String? ?? '';
    final hasTailoredOutput =
        tailoredSummary.isNotEmpty || tailoredExperience.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.magic_star, color: AppColors.info, size: 20),
            const SizedBox(width: 8),
            Text(
              'Resume Match Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (matchScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _matchColor(matchScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _matchColor(matchScore).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$matchScore% Match',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _matchColor(matchScore),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(),
        const SizedBox(height: 12),

        if (matchAssessment.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Text(
              matchAssessment,
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
          ),

        if (analysisNotice.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.info_circle, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysisNotice,
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        if (sectionScores.isNotEmpty)
          _buildCard(
            icon: Iconsax.chart_21,
            title: 'Section-wise Match Scores',
            color: AppColors.info,
            child: Column(
              children: sectionScores.map((section) {
                final label = section['label'] as String? ?? 'Section';
                final score = section['score'] as int? ?? 0;
                final summary = section['summary'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '$score%',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _matchColor(score)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 8,
                          backgroundColor: _matchColor(score).withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(_matchColor(score)),
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          summary,
                          style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ),

        if (sectionScores.isNotEmpty) const SizedBox(height: 12),

        if (keywordsExtracted.isNotEmpty)
          _buildCard(
            icon: Iconsax.tag,
            title: 'Keywords Extracted From Job Description',
            color: AppColors.primary,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: keywordsExtracted.map((keyword) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
                ),
                child: Text(keyword, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              )).toList(growable: false),
            ),
          ),

        if (keywordsExtracted.isNotEmpty) const SizedBox(height: 12),

        if (missingSkills.isNotEmpty)
          _buildCard(
            icon: Iconsax.search_status,
            title: 'Missing Skills / Gaps',
            color: AppColors.error,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missingSkills.map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
                ),
                child: Text(skill, style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
              )).toList(growable: false),
            ),
          ),

        if (missingSkills.isNotEmpty) const SizedBox(height: 12),

        if (missingKeywords.isNotEmpty)
          _buildCard(
            icon: Iconsax.close_circle,
            title: 'Uncovered Job Keywords',
            color: AppColors.warning,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missingKeywords.take(12).map((keyword) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
                ),
                child: Text(keyword, style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
              )).toList(growable: false),
            ),
          ),

        if (missingKeywords.isNotEmpty) const SizedBox(height: 12),

        if (tailoredSummary.isNotEmpty)
          _buildCard(
            icon: Iconsax.document_text_1,
            title: 'Optimized Professional Summary',
            color: AppColors.primary,
            child: Text(
              tailoredSummary,
              style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
            ),
          ),

        const SizedBox(height: 12),

        if (tailoredExperience.isNotEmpty)
          _buildCard(
            icon: Iconsax.briefcase,
            title: 'Enhanced Experience Descriptions',
            color: AppColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tailoredExperience.map<Widget>((exp) {
                final e = exp as Map<String, dynamic>? ?? {};
                final original = e['original'] as String? ?? '';
                final tailored = e['tailored'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (original.isNotEmpty)
                        Text(
                          original,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                        ),
                      if (original.isNotEmpty) const SizedBox(height: 6),
                      if (tailored.isNotEmpty)
                        Text(
                          tailored,
                          style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        if (topSkills.isNotEmpty)
          _buildCard(
            icon: Iconsax.code,
            title: 'Top Matching Skills (Prioritized)',
            color: AppColors.secondary,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topSkills.cast<String>().map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Text(skill, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),

        const SizedBox(height: 12),

        if (keywordsCovered.isNotEmpty)
          _buildCard(
            icon: Iconsax.tag,
            title: 'Keywords Already Covered',
            color: AppColors.success,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: keywordsCovered.cast<String>().map((kw) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(kw, style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),

        const SizedBox(height: 12),

        if (suggestions.isNotEmpty)
          _buildCard(
            icon: Iconsax.lamp_charge,
            title: 'Actionable Suggestions',
            color: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: suggestions.map((suggestion) {
                final title = suggestion['title'] as String? ?? 'Suggestion';
                final description = suggestion['description'] as String? ?? '';
                final priority = suggestion['priority'] as String? ?? 'medium';
                final sectionKey = suggestion['sectionKey'] as String? ?? '';
                final priorityColor = _priorityColor(priority);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary),
                        ),
                      ],
                      if (_selectedResume != null && sectionKey.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openSuggestionSection(sectionKey),
                            style: TextButton.styleFrom(
                              foregroundColor: priorityColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Iconsax.arrow_right_3, size: 14),
                            label: const Text('Open section'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ),

        const SizedBox(height: 20),

        if (hasTailoredOutput)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _applyToResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Iconsax.tick_circle, color: Colors.white),
              label: const Text(
                'Apply AI Tailoring to Resume',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

        if (!hasTailoredOutput && _selectedResume != null)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/editor/${_selectedResume!.id}'),
              icon: const Icon(Iconsax.edit_2),
              label: const Text('Open Resume to Improve Match'),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),

        Center(
          child: Text(
            engineId.isEmpty
                ? (hasTailoredOutput
                    ? 'Previous version saved automatically'
                    : 'Apply the suggestions above, then preview the resume again to verify the changes.')
                : 'Engine: $engineId • $engineVersion',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ).animate().fadeIn();
  }

  Color _matchColor(dynamic score) {
    final s = score is int ? score : (score as num).toInt();
    if (s >= 75) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  void _openSuggestionSection(String sectionKey) {
    if (_selectedResume == null) {
      return;
    }

    String? route;
    switch (sectionKey) {
      case 'personal':
        route = '/editor/${_selectedResume!.id}/personal';
        break;
      case 'summary':
        route = '/editor/${_selectedResume!.id}/summary';
        break;
      case 'experience':
        route = '/editor/${_selectedResume!.id}/experience';
        break;
      case 'skills':
        route = '/editor/${_selectedResume!.id}/skills';
        break;
      case 'projects':
        route = '/editor/${_selectedResume!.id}/projects';
        break;
      case 'education':
        route = '/editor/${_selectedResume!.id}/education';
        break;
      case 'certifications':
        route = '/editor/${_selectedResume!.id}/certifications';
        break;
    }

    if (route != null) {
      context.push(route);
    }
  }

  Widget _buildImportResultsSection() {
    final data = _parsedData!;
    final fullName = data['fullName'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final address = data['address'] as String? ?? '';
    final jobTitle = data['jobTitle'] as String? ?? '';
    final linkedIn = data['linkedIn'] as String? ?? '';
    final github = data['github'] as String? ?? '';
    final website = data['website'] as String? ?? '';
    final objective = data['objective'] as String? ?? '';
    final experiences = data['experience'] as List? ?? [];
    final educations = data['education'] as List? ?? [];
    final skills = (data['skills'] as List? ?? []).cast<String>();
    final certifications = data['certifications'] as List? ?? [];
    final languages = data['languages'] as List? ?? [];
    final projects = data['projects'] as List? ?? [];
    final hobbies = (data['hobbies'] as List? ?? []).cast<String>();
    final references = data['references'] as List? ?? [];
    final customSections = data['customSections'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extracted Resume Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(),
        const SizedBox(height: 4),
        const Text(
          'Review the extracted information below, then tap Apply to fill all resume fields.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ).animate().fadeIn(),
        const SizedBox(height: 16),

        // Personal Info
        _buildCard(
          icon: Iconsax.profile_circle,
          title: 'Personal Information',
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fullName.isNotEmpty) _importRow(Iconsax.user, 'Name', fullName),
              if (email.isNotEmpty) _importRow(Iconsax.sms, 'Email', email),
              if (phone.isNotEmpty) _importRow(Iconsax.call, 'Phone', phone),
              if (address.isNotEmpty) _importRow(Iconsax.location, 'Address', address),
              if (jobTitle.isNotEmpty) _importRow(Iconsax.briefcase, 'Job Title', jobTitle),
              if (linkedIn.isNotEmpty) _importRow(Iconsax.link, 'LinkedIn', linkedIn),
              if (github.isNotEmpty) _importRow(Iconsax.code_1, 'GitHub', github),
              if (website.isNotEmpty) _importRow(Iconsax.global, 'Website', website),
              if (fullName.isEmpty &&
                  email.isEmpty &&
                  phone.isEmpty &&
                  address.isEmpty &&
                  jobTitle.isEmpty &&
                  linkedIn.isEmpty &&
                  github.isEmpty &&
                  website.isEmpty)
                const Text('No personal info found', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ),

        if (objective.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.document_text_1,
            title: 'Professional Summary',
            color: AppColors.info,
            child: Text(objective, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary)),
          ),
        ],

        if (experiences.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.briefcase,
            title: '${experiences.length} Work Experience${experiences.length > 1 ? 's' : ''} Found',
            color: AppColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: experiences.map<Widget>((e) {
                final exp = e as Map<String, dynamic>;
                final pos = exp['position'] as String? ?? '';
                final company = exp['company'] as String? ?? '';
                final isCurrent = exp['isCurrentlyWorking'] as bool? ?? false;
                final endYear = exp['endYear'] as int?;
                final period = isCurrent ? 'Present' : (endYear?.toString() ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.record_circle, size: 12, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$pos at $company${period.isNotEmpty ? ' · $period' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (educations.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.teacher,
            title: '${educations.length} Education Entr${educations.length > 1 ? 'ies' : 'y'} Found',
            color: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: educations.map<Widget>((e) {
                final edu = e as Map<String, dynamic>;
                final degree = edu['degree'] as String? ?? '';
                final institution = edu['institution'] as String? ?? '';
                final field = edu['fieldOfStudy'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.record_circle, size: 12, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$degree${field.isNotEmpty ? ' in $field' : ''} – $institution',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.code,
            title: '${skills.length} Skills Extracted',
            color: AppColors.secondary,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Text(skill, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
        ],

        if (certifications.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.medal,
            title: '${certifications.length} Certification${certifications.length > 1 ? 's' : ''} Found',
            color: const Color(0xFF8B5CF6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: certifications.map<Widget>((c) {
                final cert = c as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${cert['name'] ?? ''} – ${cert['issuer'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (hobbies.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.heart,
            title: '${hobbies.length} Hobby${hobbies.length > 1 ? 'ies' : ''} / Interest${hobbies.length > 1 ? 's' : ''} Found',
            color: const Color(0xFFEC4899),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hobbies.map((hobby) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.28)),
                ),
                child: Text(
                  hobby,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFBE185D), fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
          ),
        ],

        if (references.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.people,
            title: '${references.length} Reference${references.length > 1 ? 's' : ''} Found',
            color: const Color(0xFF0F766E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: references.map<Widget>((entry) {
                final reference = entry as Map<String, dynamic>;
                final name = reference['name'] as String? ?? '';
                final position = reference['position'] as String? ?? '';
                final company = reference['company'] as String? ?? '';
                final relationship = reference['relationship'] as String? ?? '';
                final details = <String>[
                  if (position.isNotEmpty) position,
                  if (company.isNotEmpty) company,
                  if (relationship.isNotEmpty) relationship,
                ].join(' · ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.record_circle, size: 12, color: Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          details.isEmpty ? name : '$name · $details',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (customSections.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.document_copy,
            title: '${customSections.length} Additional Section${customSections.length > 1 ? 's' : ''} Preserved',
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: customSections.map<Widget>((entry) {
                final section = entry as Map<String, dynamic>;
                final title = section['title'] as String? ?? '';
                final items = section['items'] as List? ?? [];
                final preview = items.isNotEmpty
                    ? (items.first as Map<String, dynamic>)['title'] as String? ??
                        (items.first as Map<String, dynamic>)['description'] as String? ??
                        ''
                    : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.record_circle, size: 12, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preview.isEmpty
                              ? '$title${items.isNotEmpty ? ' · ${items.length} item${items.length == 1 ? '' : 's'}' : ''}'
                              : '$title · $preview',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (projects.isNotEmpty || languages.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCard(
            icon: Iconsax.global,
            title: 'Additional Info',
            color: AppColors.textSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (languages.isNotEmpty)
                  Text(
                    'Languages: ${(languages).map((l) => '${(l as Map)['name']}').join(', ')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                if (projects.isNotEmpty) ...[
                  if (languages.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    'Projects: ${projects.length} found',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Apply button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _applyParsedResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Iconsax.tick_circle, color: Colors.white),
            label: const Text(
              'Apply to Resume — Fill All Fields',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),
        const Center(
          child: Text(
            'All extracted fields will be copied to the selected resume',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _importRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

