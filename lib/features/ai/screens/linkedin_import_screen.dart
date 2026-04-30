import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/resume_import_service.dart';
import '../../../core/services/storage_service.dart';

const String _linkedInImportPasteHintText =
    'Paste your LinkedIn profile text here…';

const List<String> _linkedInImportExampleLines = <String>[
  'John Doe',
  'Senior Software Engineer at Acme Corp',
  'Sydney, NSW',
  '',
  'About',
  'Passionate engineer with 7 years experience…',
  '',
  'Experience',
  'Acme Corp · Senior Software Engineer',
  'Jan 2021 – Present · Sydney, NSW',
  '…',
  '',
  'Skills',
  'Python, AWS, Docker, Node.js…',
];

const List<List<String>> _linkedInImportBoilerplateLineSequences =
    <List<String>>[
      <String>[
        _linkedInImportPasteHintText,
        'Example:',
        'John Doe',
        'Senior Software Engineer at Acme Corp',
        'Sydney, NSW',
        'About',
        'Passionate engineer with 7 years experience…',
        'Experience',
        'Acme Corp · Senior Software Engineer',
        'Jan 2021 – Present · Sydney, NSW',
        '…',
        'Skills',
        'Python, AWS, Docker, Node.js…',
      ],
    ];

/// LinkedIn Import screen.
///
/// The user pastes the plain-text content exported from their LinkedIn profile
/// (Account → Settings → Data Privacy → Get a copy of your data, or simply
/// copy/paste the profile page text).  The parser extracts as many fields as
/// possible and pre-fills a new [ResumeModel] which the user can then refine
/// inside the editor.
class LinkedInImportScreen extends ConsumerStatefulWidget {
  const LinkedInImportScreen({super.key});

  @override
  ConsumerState<LinkedInImportScreen> createState() =>
      _LinkedInImportScreenState();
}

class _LinkedInImportScreenState extends ConsumerState<LinkedInImportScreen> {
  final _pasteController = TextEditingController();
  _ParsedProfile? _parsed;
  bool _isParsing = false;
  bool _isImportingFile = false;
  bool _showPasteHint = false;
  String? _importedFileName;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  // ── Parser ─────────────────────────────────────────────────────────────────

  Future<void> _parseAndPreview() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your LinkedIn profile text first.')),
      );
      return;
    }

    setState(() => _isParsing = true);
    await Future.delayed(const Duration(milliseconds: 500)); // simulate parse

    final parsed = _LinkedInParser.parse(text);
    setState(() {
      _parsed = parsed;
      _isParsing = false;
    });
  }

  Future<void> _pickLinkedInFile() async {
    if (_isImportingFile || _isParsing) {
      return;
    }

    setState(() => _isImportingFile = true);

    try {
      final importedFile = await ResumeImportService.pickResumeFile();
      if (!mounted || importedFile == null) {
        if (mounted) {
          setState(() => _isImportingFile = false);
        }
        return;
      }

      _pasteController.text = importedFile.extractedText;
      setState(() {
        _isImportingFile = false;
        _parsed = null;
        _importedFileName = importedFile.fileName;
      });

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Loaded ${importedFile.fileName}. Review the extracted text, then tap Parse & Preview.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } on ResumeImportException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isImportingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isImportingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load the selected LinkedIn file. ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importResume() async {
    if (_parsed == null) return;
    final id = const Uuid().v4();
    final resume = _buildImportedResumeFromParsedProfile(
      _parsed!,
      id: id,
      now: DateTime.now(),
    );

    await StorageService.saveResume(resume);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Profile imported! Review and finalize your resume.'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.go('/editor/$id');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('LinkedIn Import'),
      ),
      body: _parsed == null ? _buildPasteView() : _buildPreviewView(),
    );
  }

  Widget _buildPasteView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A66C2).withValues(alpha: 0.12),
                const Color(0xFF0A66C2).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF0A66C2).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Iconsax.user_tick, color: Color(0xFF0A66C2), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paste Your Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Paste your LinkedIn profile text or import a LinkedIn PDF/text export.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // How to guide
        GestureDetector(
          onTap: () => setState(() => _showPasteHint = !_showPasteHint),
          child: AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.information, size: 18, color: AppColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('How to export your LinkedIn profile',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              )),
                    ),
                    Icon(_showPasteHint ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        size: 16, color: AppColors.info),
                  ],
                ),
                if (_showPasteHint) ...[
                  const SizedBox(height: 12),
                  _hintStep('1', 'Open your LinkedIn profile in a browser.'),
                  _hintStep('2', 'Use  Ctrl+A  (or  Cmd+A) to select all text.'),
                  _hintStep('3', 'Copy it with  Ctrl+C  (or  Cmd+C).'),
                  _hintStep('4', 'Paste into the box below.'),
                  _hintStep('5', 'Or choose a LinkedIn PDF / text export directly using the file button below.'),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: The more complete your LinkedIn profile, the better the import.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isImportingFile || _isParsing ? null : _pickLinkedInFile,
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
                  : (_importedFileName == null
                        ? 'Choose LinkedIn PDF / Text File'
                        : 'Choose Another LinkedIn File'),
            ),
          ),
        ).animate().fadeIn(delay: 220.ms),

        if (_importedFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Selected file: $_importedFileName',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 240.ms),
        ],

        const SizedBox(height: 12),

        // Keep the sample outside the editable field so Ctrl+A targets pasted content.
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _pasteController,
            maxLines: 18,
            decoration: const InputDecoration(
              hintText: _linkedInImportPasteHintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
          ),
        ).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 12),

        _buildPasteExampleCard().animate().fadeIn(delay: 270.ms),

        const SizedBox(height: 20),

        // Parse button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isParsing ? null : _parseAndPreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isParsing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Iconsax.magic_star),
            label: Text(_isParsing ? 'Parsing…' : 'Parse & Preview'),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPreviewView() {
    final p = _parsed!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Back to edit
              OutlinedButton.icon(
                onPressed: () => setState(() => _parsed = null),
                icon: const Icon(Iconsax.edit_2, size: 18),
                label: const Text('Edit Source Text'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 20),

              _previewSection('Personal Info', Iconsax.user, AppColors.primary, [
                _previewField('Name', p.name),
                _previewField('Headline', p.headline),
                _previewField('Email', p.email),
                _previewField('Phone', p.phone),
                _previewField('Location', p.location),
                _previewField('LinkedIn', p.linkedIn),
                _previewField('GitHub', p.github),
                _previewField('Website', p.website),
              ]),
              if (p.summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Summary', Iconsax.clipboard_text, AppColors.secondary, [
                  _previewText(p.summary),
                ]),
              ],
              if (p.experience.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Experience', Iconsax.briefcase, AppColors.info, p.experience
                    .map((e) => _previewField('${e.position} @ ${e.company}', e.description))
                    .toList()),
              ],
              if (p.education.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Education', Iconsax.book, AppColors.warning, p.education
                    .map((e) => _previewField(e.institution, '${e.degree} – ${e.fieldOfStudy}'))
                    .toList()),
              ],
              if (p.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Skills', Iconsax.code, const Color(0xFF8B5CF6), [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.skills
                        .take(20)
                        .map((s) => Chip(
                              label: Text(s.name, style: const TextStyle(fontSize: 12)),
                              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ]),
              ],
              if (p.projects.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection(
                  'Projects',
                  Iconsax.folder_open,
                  AppColors.secondary,
                  p.projects
                      .map(
                        (project) => _previewField(
                          project.title,
                          project.description.isNotEmpty
                              ? project.description
                              : (project.url ?? ''),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (p.certifications.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Certifications', Iconsax.award, AppColors.success, p.certifications
                    .map((certification) => _previewField(
                          'Certification',
                          certification.issuer.isNotEmpty
                              ? '${certification.name} - ${certification.issuer}'
                              : certification.name,
                        ))
                    .toList()),
              ],
              if (p.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _previewSection('Languages', Iconsax.global, AppColors.warning, [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.languages
                        .map((language) => Chip(
                              label: Text(language.name, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ]),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _importResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Iconsax.import),
                label: const Text('Import to Resume Editor'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _hintStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildPasteExampleCard() {
    return SelectionContainer.disabled(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A66C2).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF0A66C2).withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Example profile text',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0A66C2),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _linkedInImportExampleLines.join('\n'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _previewField(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _previewText(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

// ── Parser ─────────────────────────────────────────────────────────────────────

ResumeModel _buildImportedResumeFromParsedProfile(
  _ParsedProfile profile, {
  required String id,
  required DateTime now,
  String templateId = 'modern',
}) {
  return ResumeModel(
    id: id,
    title:
        '${profile.name.isNotEmpty ? profile.name : "LinkedIn"} – Imported Resume',
    personalInfo: PersonalInfo(
      fullName: profile.name,
      email: profile.email,
      phone: profile.phone,
      jobTitle: profile.headline,
      address: profile.location,
      linkedIn: profile.linkedIn,
      github: profile.github,
      website: profile.website,
      profileImage: null,
      dateOfBirth: null,
    ),
    objective: profile.summary,
    education: profile.education,
    experience: profile.experience,
    skills: profile.skills,
    projects: profile.projects,
    certifications: profile.certifications,
    languages: profile.languages.isNotEmpty
        ? profile.languages
        : [
            Language(
              id: const Uuid().v4(),
              name: 'English',
              proficiency: 'Fluent',
            ),
          ],
    hobbies: [],
    references: [],
    templateId: templateId,
    createdAt: now,
    updatedAt: now,
  );
}

class _ParsedProfile {
  String name = '';
  String headline = '';
  String email = '';
  String phone = '';
  String location = '';
  String linkedIn = '';
  String github = '';
  String website = '';
  String summary = '';
  List<Experience> experience;
  List<Education> education;
  List<Skill> skills;
  List<Project> projects;
  List<Certification> certifications;
  List<Language> languages;

  _ParsedProfile({
    List<Experience>? experience,
    List<Education>? education,
    List<Skill>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
    List<Language>? languages,
  })  : experience = experience ?? [],
        education = education ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [],
        languages = languages ?? [];
}

@visibleForTesting
Map<String, Object> debugParseLinkedInProfile(String raw) {
  final parsed = _LinkedInParser.parse(raw);
  return {
    'name': parsed.name,
    'headline': parsed.headline,
    'email': parsed.email,
    'phone': parsed.phone,
    'location': parsed.location,
    'linkedIn': parsed.linkedIn,
    'github': parsed.github,
    'website': parsed.website,
    'summary': parsed.summary,
    'educationInstitutions': parsed.education.map((item) => item.institution).toList(),
    'educationDegrees': parsed.education.map((item) => item.degree).toList(),
    'skills': parsed.skills.map((skill) => skill.name).toList(),
    'certifications': parsed.certifications.map((item) => item.name).toList(),
    'certificationIssuers': parsed.certifications.map((item) => item.issuer).toList(),
    'languages': parsed.languages.map((item) => item.name).toList(),
    'projectTitles': parsed.projects.map((item) => item.title).toList(),
    'projectUrls': parsed.projects.map((item) => item.url ?? '').toList(),
    'experienceCompanies': parsed.experience.map((item) => item.company).toList(),
    'experiencePositions': parsed.experience.map((item) => item.position).toList(),
  };
}

@visibleForTesting
ResumeModel debugBuildLinkedInImportedResume(
  String raw, {
  String id = 'debug-linkedin-import',
  DateTime? now,
  String templateId = 'modern',
}) {
  final parsed = _LinkedInParser.parse(raw);
  return _buildImportedResumeFromParsedProfile(
    parsed,
    id: id,
    now: now ?? DateTime(2026, 1, 1),
    templateId: templateId,
  );
}

class _LinkedInParser {
  static _ParsedProfile parse(String raw) {
    final lines = _normalizeLines(raw);
    final p = _ParsedProfile();
    final sectionIndices = _findSectionIndices(lines);
    final headerLines = _headerLines(lines, sectionIndices);
    final contactBlock = _contactBlock(lines);

    // ── Name / headline: prefer clean header lines above the first section ─
    final headerIdentityLines =
        headerLines.where(_looksLikeIdentityLine).toList(growable: false);
    final contactIdentityLines = _identityLinesNearContacts(lines);
    final identityLines = contactIdentityLines.isNotEmpty
      ? contactIdentityLines
      : headerIdentityLines;
    if (identityLines.isNotEmpty) {
      p.name = identityLines.first;
    } else if (lines.isNotEmpty && _looksLikeIdentityLine(lines.first)) {
      p.name = lines.first;
    }

    for (final line in identityLines.skip(1)) {
      if (line != p.name && !_looksLikeLocation(line)) {
        p.headline = line;
        break;
      }
    }
    if (p.headline.isEmpty && lines.length > 1 && _looksLikeIdentityLine(lines[1])) {
      p.headline = lines[1];
    }

    // ── Email ──────────────────────────────────────────────────────────────
    final emailRe = RegExp(
      r'[\w.+-]+@(?:[\w-]+\.)+[a-z]{2,}',
      caseSensitive: false,
    );
    for (final l in lines) {
      final m = emailRe.firstMatch(l);
      if (m != null) { p.email = m.group(0)!; break; }
    }

    // ── Phone ──────────────────────────────────────────────────────────────
    final phoneRe = RegExp(r'[\+]?[0-9 \-\(\)]{6,}\d(?:\s*\([^)]+\))?');
    final phoneCandidates = contactBlock.isNotEmpty ? contactBlock : lines;
    for (final l in phoneCandidates) {
      if (!_containsPhone(l)) {
        continue;
      }
      final m = phoneRe.firstMatch(l);
      if (m != null && m.group(0)!.replaceAll(RegExp(r'\D'), '').length >= 7) {
        p.phone = m.group(0)!.trim();
        break;
      }
    }

    // ── LinkedIn URL ───────────────────────────────────────────────────────
    final linkedInRe = RegExp(
      r'(https?://)?(?:www\.)?linkedin\.com/[^\s]+',
      caseSensitive: false,
    );
    for (final l in lines) {
      final m = linkedInRe.firstMatch(l);
      if (m != null) {
        p.linkedIn = m.group(0)!;
        break;
      }
    }

    for (final l in contactBlock) {
      if (_containsGitHubUrl(l)) {
        p.github = l.trim();
        break;
      }
    }

    for (final l in contactBlock) {
      if (_looksLikeWebsiteLine(l) &&
          !_containsLinkedInUrl(l) &&
          !_containsGitHubUrl(l)) {
        p.website = l.trim();
        break;
      }
    }

    // ── Location: line that looks like "City, State/Country" ──────────────
    final locationCandidates = <String>[
      ...headerLines,
      ...contactBlock,
      ..._sectionBlock(lines, sectionIndices, 'contact'),
    ];
    for (final candidate in locationCandidates) {
      if (_looksLikeLocation(candidate) && !_looksLikeContactLabel(candidate)) {
        p.location = candidate;
        break;
      }
    }

    final summaryPreludeIdentity =
        _identityPreludeBeforeSection(lines, sectionIndices, 'about');
    if (p.name.isEmpty && summaryPreludeIdentity.name.isNotEmpty) {
      p.name = summaryPreludeIdentity.name;
    }
    if (p.headline.isEmpty && summaryPreludeIdentity.headline.isNotEmpty) {
      p.headline = summaryPreludeIdentity.headline;
    }
    if (p.location.isEmpty && summaryPreludeIdentity.location.isNotEmpty) {
      p.location = summaryPreludeIdentity.location;
    }

    // ── Summary / About ─────────────────────────────────────────────────────
    final aboutBlock = _sectionBlock(lines, sectionIndices, 'about');
    if (aboutBlock.isNotEmpty) {
      final summaryLines = aboutBlock
          .where(
            (line) => !_looksLikeContactLabel(line) && !_hasContactDetail(line),
          )
          .toList(growable: false);
      p.summary = _joinContentLines(summaryLines);
    }

    // ── Experience ──────────────────────────────────────────────────────────
    final expBlock = _sectionBlock(lines, sectionIndices, 'experience');
    if (expBlock.isNotEmpty) {
      p.experience = _parseExperience(expBlock);
    }

    // ── Education ───────────────────────────────────────────────────────────
    final eduBlock = _sectionBlock(lines, sectionIndices, 'education');
    if (eduBlock.isNotEmpty) {
      p.education = _parseEducation(eduBlock);
    }

    // ── Skills ──────────────────────────────────────────────────────────────
    final skillBlock = _sectionBlock(lines, sectionIndices, 'skills');
    if (skillBlock.isNotEmpty) {
      p.skills = _parseSkills(skillBlock);
    } else {
      // Fallback: look for comma-separated skill lines
      for (final l in lines) {
        if (l.contains(',') && l.split(',').length >= 3) {
          p.skills = _parseSkills([l]);
          if (p.skills.isNotEmpty) break;
        }
      }
    }

    // ── Projects ───────────────────────────────────────────────────────────
    final projectBlock = _sectionBlock(lines, sectionIndices, 'projects');
    if (projectBlock.isNotEmpty) {
      p.projects = _parseProjects(projectBlock);
    }

    // ── Certifications ─────────────────────────────────────────────────────
    final certificationBlock = _sectionBlock(lines, sectionIndices, 'certifications');
    if (certificationBlock.isNotEmpty) {
      p.certifications = _parseCertifications(
        certificationBlock,
        fullName: p.name,
        headline: p.headline,
      );
    }

    // ── Languages ──────────────────────────────────────────────────────────
    final languageBlock = _sectionBlock(lines, sectionIndices, 'languages');
    if (languageBlock.isNotEmpty) {
      p.languages = _parseLanguages(languageBlock);
    }

    return p;
  }

  // ── Section parsers ────────────────────────────────────────────────────────

  static List<Experience> _parseExperience(List<String> block) {
    final result = <Experience>[];
    int i = 0;
    while (i < block.length && result.length < 6) {
      final dateIndex = _nextDateIndex(block, i);
      if (dateIndex == -1) {
        break;
      }
      final dates = block[dateIndex];
      final inlinePosition = _textBeforeDateRange(dates);
      final headerLines = _headerLinesBeforeDate(block, i, dateIndex);
      final header = _parseExperienceHeader(headerLines);
      final descLines = <String>[];
      final achievements = <String>[];
      var position = inlinePosition.isNotEmpty ? inlinePosition : header.position;
      var company = header.company;
      var location = '';
      int j = dateIndex + 1;

      if (j < block.length &&
          !_looksLikeSection(block[j]) &&
          !_looksLikeDateRange(block[j]) &&
          !_isExperienceMetaLine(block[j])) {
        final companyAndLocation = _splitCompanyAndLocation(block[j]);
        if (companyAndLocation.company.isNotEmpty) {
          company = company.isEmpty ? companyAndLocation.company : company;
          location = companyAndLocation.location;
          j++;
        }
      }

      if (location.isEmpty && j < block.length && _looksLikeWorkLocation(block[j])) {
        location = block[j];
        j++;
      }

      if (j < block.length && _isDescriptionLabel(block[j])) {
        j++;
      }

      while (j < block.length && !_looksLikeSection(block[j])) {
        final line = block[j];
        final startsNextEntry = _startsNextExperienceEntry(block, j);
        if (startsNextEntry) {
          break;
        }
        if (!_isExperienceMetaLine(line)) {
          descLines.add(line);
          achievements.add(_stripBulletPrefix(line));
        }
        j++;
      }

      if (company.isNotEmpty || position.isNotEmpty) {
        result.add(Experience(
          id: const Uuid().v4(),
          company: company,
          position: position,
          startDate: _extractStart(dates),
          endDate: _extractEnd(dates),
          isCurrentlyWorking: dates.toLowerCase().contains('present'),
          description: descLines.take(6).join('\n'),
          location: location,
          achievements: achievements.take(6).toList(growable: false),
        ));
      }

      i = j > dateIndex ? j : dateIndex + 1;
    }
    return result;
  }

  static List<Education> _parseEducation(List<String> block) {
    final result = <Education>[];
    int i = 0;
    while (i < block.length && result.length < 3) {
      final dateIndex = _nextDateIndex(block, i);
      if (dateIndex == -1) {
        break;
      }

      final headerLines = _headerLinesBeforeDate(
        block,
        i,
        dateIndex,
        maxLines: 4,
      );
      final header = _parseEducationHeader(headerLines);
      final inst = header.institution;
      final degree = header.degree;
      final fieldOfStudy = header.fieldOfStudy;
      final dates = block[dateIndex];

      if (inst.isNotEmpty) {
        result.add(Education(
          id: const Uuid().v4(),
          institution: inst,
          degree: degree.isNotEmpty ? degree : "Degree",
          fieldOfStudy: fieldOfStudy,
          startDate: _extractStart(dates),
          endDate: _extractEnd(dates),
          description: '',
        ));
        i = dateIndex + 1;
      } else {
        i = dateIndex + 1;
      }
    }
    return result;
  }

  static List<Skill> _parseSkills(List<String> block) {
    final result = <Skill>[];
    final seen = <String>{};
    for (int index = 0; index < block.length; index++) {
      final line = block[index];
      if (_looksLikeSection(line) || _looksLikeSkillTerminator(line)) {
        break;
      }
      if (_startsContactBlock(block, index)) {
        break;
      }

      // Split on commas, bullets, newlines, pipes
      final parts = line.split(RegExp(r'[,•|·\n]'));
      for (final part in parts) {
        final name = part.trim().replaceAll(RegExp(r'^[-–—]\s*'), '');
        if (_looksLikeSkill(name) && !seen.contains(name.toLowerCase())) {
          seen.add(name.toLowerCase());
          result.add(Skill(id: const Uuid().v4(), name: name, proficiency: 3, category: 'Technical'));
        }
      }
      if (result.length >= 20) break;
    }
    return result;
  }

  static List<Project> _parseProjects(List<String> block) {
    final result = <Project>[];
    int i = 0;
    while (i < block.length && result.length < 8) {
      final title = block[i].trim();
      if (title.isEmpty || _looksLikeUrl(title)) {
        i++;
        continue;
      }

      final descLines = <String>[];
      String? url;
      int j = i + 1;

      while (j < block.length && !_looksLikeSection(block[j])) {
        final line = block[j].trim();
        if (line.isEmpty) {
          j++;
          continue;
        }

        if (_looksLikeUrl(line)) {
          url = line;
          j++;
          if (j < block.length && _looksLikeProjectTitle(block[j])) {
            break;
          }
          continue;
        }

        if (_looksLikeProjectTitle(line) && (url != null || descLines.length >= 2)) {
          break;
        }

        descLines.add(line);
        j++;
      }

      result.add(
        Project(
          id: const Uuid().v4(),
          title: title,
          description: descLines.join('\n'),
          url: url,
        ),
      );

      i = j > i ? j : i + 1;
    }
    return result;
  }

  static List<Certification> _parseCertifications(
    List<String> block, {
    String fullName = '',
    String headline = '',
  }) {
    final result = <Certification>[];
    final normalizedName = fullName.trim().toLowerCase();
    final normalizedHeadline = headline.trim().toLowerCase();
    final seen = <String>{};
    int i = 0;
    while (i < block.length && result.length < 10) {
      final cleaned = block[i].trim();
      final key = cleaned.toLowerCase();
      if (cleaned.isEmpty ||
          _looksLikeSection(cleaned) ||
          _looksLikeLocation(cleaned) ||
          key == normalizedName ||
          key == normalizedHeadline ||
          _isCertificationMetaLine(cleaned) ||
          _looksLikeUrl(cleaned)) {
        i++;
        continue;
      }

      var issuer = '';
      DateTime? issueDate;
      String? credentialId;
      String? credentialUrl;
      int j = i + 1;

      while (j < block.length && !_looksLikeSection(block[j])) {
        final line = block[j].trim();
        final lower = line.toLowerCase();
        if (line.isEmpty || lower == normalizedName || lower == normalizedHeadline) {
          j++;
          continue;
        }
        if (_looksLikeCertificationTitle(line) &&
            (issuer.isNotEmpty ||
                issueDate != null ||
                credentialId != null ||
                credentialUrl != null)) {
          break;
        }
        if (_looksLikeUrl(line)) {
          credentialUrl = line;
          j++;
          continue;
        }
        final parsedIssueDate = _parseIssuedDate(line);
        if (parsedIssueDate != null) {
          issueDate = parsedIssueDate;
          j++;
          continue;
        }
        final parsedCredentialId = _extractCredentialId(line);
        if (parsedCredentialId != null) {
          credentialId = parsedCredentialId;
          j++;
          continue;
        }
        if (issuer.isEmpty) {
          final nextLine = j + 1 < block.length ? block[j + 1].trim() : '';
          final nextLower = nextLine.toLowerCase();
          final nextStartsAnotherItem = nextLine.isEmpty ||
              _looksLikeSection(nextLine) ||
              nextLower == normalizedName ||
              nextLower == normalizedHeadline ||
              _looksLikeCertificationTitle(nextLine);
          if (nextStartsAnotherItem) {
            break;
          }
          issuer = line;
          j++;
          continue;
        }
        break;
      }

      if (seen.add(key)) {
        result.add(
          Certification(
            id: const Uuid().v4(),
            name: cleaned,
            issuer: issuer,
            issueDate: issueDate,
            credentialId: credentialId,
            credentialUrl: credentialUrl,
          ),
        );
      }

      i = j > i ? j : i + 1;
    }
    return result;
  }

  static List<Language> _parseLanguages(List<String> block) {
    final result = <Language>[];
    final seen = <String>{};
    for (final line in block) {
      if (_looksLikeSection(line)) {
        break;
      }

      final parts = line.split(RegExp(r'[,•]'));
      for (final part in parts) {
        final normalized = part.trim();
        if (normalized.isEmpty || normalized.length > 40) {
          continue;
        }

        final language = _extractLanguageName(normalized);
        if (language.isEmpty) {
          continue;
        }

        final key = language.toLowerCase();
        if (seen.add(key)) {
          result.add(
            Language(
              id: const Uuid().v4(),
              name: language,
              proficiency: _extractLanguageProficiency(normalized),
            ),
          );
        }
      }
    }
    return result;
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static List<String> _normalizeLines(String raw) {
    final normalizedText = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ');

    final lines = <String>[];
    for (final rawLine in normalizedText.split('\n')) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty || _isNoiseLine(line)) {
        continue;
      }
      if (lines.isNotEmpty && lines.last.toLowerCase() == line.toLowerCase()) {
        continue;
      }
      lines.add(line);
    }
    return _removeKnownBoilerplateBlocks(lines);
  }

  static List<String> _removeKnownBoilerplateBlocks(List<String> lines) {
    if (lines.isEmpty) {
      return const <String>[];
    }

    final filtered = <String>[];
    var index = 0;
    while (index < lines.length) {
      final matchLength = _matchingBoilerplateLength(lines, index);
      if (matchLength > 0) {
        index += matchLength;
        continue;
      }
      filtered.add(lines[index]);
      index++;
    }
    return filtered;
  }

  static int _matchingBoilerplateLength(List<String> lines, int start) {
    for (final sequence in _linkedInImportBoilerplateLineSequences) {
      if (start + sequence.length > lines.length) {
        continue;
      }

      var matches = true;
      for (var offset = 0; offset < sequence.length; offset++) {
        if (lines[start + offset].toLowerCase() !=
            sequence[offset].toLowerCase()) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return sequence.length;
      }
    }

    return 0;
  }

  static List<String> _headerLines(
    List<String> lines,
    Map<String, int> sectionIndices,
  ) {
    var end = lines.length < 8 ? lines.length : 8;
    for (final index in sectionIndices.values) {
      if (index >= 0 && index < end) {
        end = index;
      }
    }
    return lines.take(end).toList(growable: false);
  }

  static List<String> _contactBlock(List<String> lines) {
    final firstContactIndex = _firstPrimaryContactIndex(lines);
    if (firstContactIndex == -1) {
      return const <String>[];
    }

    var start = firstContactIndex;
    while (start > 0 && firstContactIndex - start < 2) {
      final previous = lines[start - 1];
      if (_looksLikeSection(previous)) {
        break;
      }
      if (_looksLikeIdentityLine(previous) ||
          _looksLikeLocation(previous) ||
          _looksLikeContactLabel(previous)) {
        start--;
        continue;
      }
      break;
    }

    var end = firstContactIndex;
    while (end + 1 < lines.length) {
      final next = lines[end + 1];
      if (_looksLikeSection(next)) {
        break;
      }
      if (_hasContactDetail(next) ||
          _looksLikeContactLabel(next) ||
          _looksLikeLocation(next)) {
        end++;
        continue;
      }
      break;
    }

    return lines.sublist(start, end + 1);
  }

  static List<String> _identityLinesNearContacts(List<String> lines) {
    final firstContactIndex = _firstPrimaryContactIndex(lines);
    if (firstContactIndex == -1) {
      return const <String>[];
    }

    final trailing = <String>[];
    for (var index = firstContactIndex + 1; index < lines.length; index++) {
      final line = lines[index];
      if (_looksLikeSection(line)) {
        break;
      }
      if (_hasContactDetail(line) ||
          _looksLikeContactLabel(line) ||
          _looksLikeLocation(line)) {
        continue;
      }
      if (_looksLikeIdentityLine(line)) {
        trailing.add(line);
        if (trailing.length >= 2) {
          return trailing;
        }
        continue;
      }
      if (trailing.isNotEmpty) {
        break;
      }
    }

    if (firstContactIndex <= 0) {
      return const <String>[];
    }

    final candidates = <String>[];
    final start = firstContactIndex - 5 < 0 ? 0 : firstContactIndex - 5;
    for (var index = start; index < firstContactIndex; index++) {
      final line = lines[index];
      if (_looksLikeSection(line) ||
          _hasContactDetail(line) ||
          _looksLikeLocation(line) ||
          _looksLikeDateRange(line)) {
        continue;
      }
      if (_looksLikeIdentityLine(line)) {
        candidates.add(line);
      }
    }
    if (candidates.length <= 2) {
      return candidates;
    }
    final startIndex = candidates.length - 2;
    return candidates.sublist(startIndex);
  }

  static ({String name, String headline, String location})
      _identityPreludeBeforeSection(
    List<String> lines,
    Map<String, int> sectionIndices,
    String key,
  ) {
    final sectionIndex = sectionIndices[key];
    if (sectionIndex == null || sectionIndex < 3) {
      return (name: '', headline: '', location: '');
    }

    final location = lines[sectionIndex - 1].trim();
    final headline = lines[sectionIndex - 2].trim();
    final name = lines[sectionIndex - 3].trim();

    if (!_looksLikeLocation(location)) {
      return (name: '', headline: '', location: '');
    }
    if (!_looksLikePersonName(name)) {
      return (name: '', headline: '', location: '');
    }
    if (!_looksLikeHeadlineLine(headline)) {
      return (name: '', headline: '', location: '');
    }

    return (name: name, headline: headline, location: location);
  }

  static int _firstPrimaryContactIndex(List<String> lines) {
    int? firstIndex;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_containsPhone(line) ||
          _containsEmail(line) ||
          _containsLinkedInUrl(line) ||
          _containsGitHubUrl(line)) {
        firstIndex ??= index;
      }
    }
    return firstIndex ?? -1;
  }

  static List<String> _sectionBlock(
    List<String> lines,
    Map<String, int> sectionIndices,
    String key,
  ) {
    final index = sectionIndices[key];
    if (index == null || index < 0) {
      return const <String>[];
    }

    final end = _nextSectionIdx(lines, index + 1, sectionIndices.values.toList(growable: false));
    return lines.sublist(index + 1, end);
  }

  static int _nextSectionIdx(List<String> lines, int from, List<int> candidates) {
    int next = lines.length;
    for (final c in candidates) {
      if (c > from && c < next) next = c;
    }
    return next;
  }

  static Map<String, int> _findSectionIndices(List<String> lines) {
    final indices = <String, int>{};
    for (int i = 0; i < lines.length; i++) {
      final section = _sectionKey(lines[i]);
      if (section != null) {
        indices.putIfAbsent(section, () => i);
      }
    }
    return indices;
  }

  static String? _sectionKey(String line) {
    final normalized = line
        .toLowerCase()
        .replaceAll(RegExp(r'[:\-–—]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const aliases = <String, List<String>>{
      'about': ['about', 'summary', 'about me', 'professional summary', 'profile summary'],
      'experience': ['experience', 'work experience', 'professional experience'],
      'education': ['education'],
      'skills': ['skills', 'top skills', 'skills & endorsements'],
      'languages': ['languages'],
      'certifications': ['certifications', 'licenses & certifications', 'licenses and certifications'],
      'projects': ['projects'],
      'contact': ['contact', 'contact info', 'contact information', 'personal info'],
      'volunteering': ['volunteering', 'volunteer experience'],
      'interests': ['interests'],
      'accomplishments': ['accomplishments', 'honors & awards', 'awards'],
    };

    for (final entry in aliases.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  static bool _looksLikeSection(String line) {
    return _sectionKey(line) != null;
  }

  static bool _looksLikeSeparator(String line) {
    return _looksLikeSection(line) || RegExp(r'^\d{4}').hasMatch(line);
  }

  static bool _looksLikeIdentityLine(String line) {
    if (_looksLikeSection(line) || _looksLikeContactLabel(line)) return false;
    if (_hasContactDetail(line)) {
      return false;
    }
    if (_looksLikeLocation(line)) return false;
    if (RegExp(r'\b\d+\+?\s+(followers|connections)\b', caseSensitive: false)
        .hasMatch(line)) {
      return false;
    }
    if (line.length > 90) return false;
    return true;
  }

  static bool _looksLikePersonName(String line) {
    final normalized = line.trim();
    if (!_looksLikeIdentityLine(normalized) || normalized.length > 40) {
      return false;
    }
    if (RegExp(
      r'\b(lead|engineer|manager|developer|consultant|analyst|tester|architect|director|specialist|administrator|officer|intern|designer|associate|sdet|qa)\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return false;
    }

    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length < 2 || parts.length > 4) {
      return false;
    }

    return parts.every(
      (part) => RegExp(r"^[A-Z][A-Za-z'.-]*$").hasMatch(part),
    );
  }

  static bool _looksLikeHeadlineLine(String line) {
    final normalized = line.trim();
    if (!_looksLikeIdentityLine(normalized) || _looksLikePersonName(normalized)) {
      return false;
    }
    if (_looksLikeLocation(normalized) ||
        _looksLikeCompany(normalized) ||
        _looksLikeSchool(normalized) ||
        _looksLikeCertificationTitle(normalized) ||
        normalized.length > 70) {
      return false;
    }
    return true;
  }

  static bool _looksLikeContactLabel(String line) {
    final normalized = line.toLowerCase().replaceAll(':', '').trim();
    return const {
      'email',
      'phone',
      'mobile',
      'address',
      'website',
      'profile',
      'linkedin',
      'contact info',
    }.contains(normalized);
  }

  static bool _containsEmail(String line) {
    return RegExp(
      r'[\w.+-]+@(?:[\w-]+\.)+[a-z]{2,}',
      caseSensitive: false,
    )
        .hasMatch(line);
  }

  static bool _containsPhone(String line) {
    final normalized = line.trim();
    if (RegExp(r'^\d{4}\s*[-–—]\s*\d{4}$').hasMatch(normalized)) {
      return false;
    }
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'[+]?[0-9\s\-\(\)]{7,}').hasMatch(normalized) &&
        digits.length >= 10;
  }

  static bool _containsLinkedInUrl(String line) {
    return RegExp(r'(https?://)?(?:www\.)?linkedin\.com/', caseSensitive: false)
        .hasMatch(line);
  }

  static bool _containsGitHubUrl(String line) {
    return RegExp(r'(https?://)?(?:www\.)?github\.com/', caseSensitive: false)
        .hasMatch(line);
  }

  static bool _looksLikeWebsiteLine(String line) {
    return RegExp(
              r'(https?://)?(?:www\.)?[a-z0-9.-]+\.[a-z]{2,}(/[^\s]*)?$',
              caseSensitive: false,
            )
            .hasMatch(line) &&
        !_containsEmail(line);
  }

  static bool _hasContactDetail(String line) {
    return _containsEmail(line) ||
        _containsPhone(line) ||
        _containsLinkedInUrl(line) ||
        _containsGitHubUrl(line) ||
        _looksLikeWebsiteLine(line);
  }

  static bool _looksLikeSkill(String value) {
    final name = value.trim();
    if (name.isEmpty || name.length > 40) return false;
    if (name.contains('@') || name.contains('http')) return false;
    if (name.contains(':')) return false;
    if (RegExp(r'\d{4}|\bpresent\b', caseSensitive: false).hasMatch(name)) {
      return false;
    }
    if (_looksLikeSection(name)) return false;
    if (_looksLikeLocation(name)) return false;

    final wordCount = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;
    if (wordCount > 4) return false;

    return true;
  }

  static bool _looksLikeSkillTerminator(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty) return false;
    if (_looksLikeContactLabel(normalized)) return true;
    if (_hasContactDetail(normalized)) return true;
    if (RegExp(r'^[\w.+-]+@(?:[\w-]+\.)+[a-z]{2,}$', caseSensitive: false)
        .hasMatch(normalized)) {
      return true;
    }
    if (RegExp(r'[+]?[0-9\s\-\(\)]{7,}').hasMatch(normalized) &&
        normalized.replaceAll(RegExp(r'\D'), '').length >= 7) {
      return true;
    }
    if (normalized.contains(':')) return true;
    if (normalized.split(RegExp(r'\s+')).length > 6) return true;
    return false;
  }

  static bool _looksLikeLocation(String value) {
    final normalized = value.toLowerCase();
    const blocked = {
      'india',
      'united states',
      'usa',
      'uk',
      'andhra pradesh',
      'telangana',
      'hyderabad',
    };
    if (blocked.contains(normalized)) return true;
    return RegExp(r'^[A-Za-z .]+,\s*[A-Za-z .]+(?:,\s*[A-Za-z .]+)?$').hasMatch(value);
  }

  static bool _isNoiseLine(String line) {
    if (RegExp(r'^page\s+\d+\s+of\s+\d+$', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^(open to work|message|more)$', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    return false;
  }

  static String _joinContentLines(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikeDateRange(String line) {
    final normalized = line.toLowerCase();
    return RegExp(
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec|present|current|\d{4})',
      caseSensitive: false,
    ).hasMatch(normalized) && normalized.contains('-');
  }

  static int _nextDateIndex(List<String> lines, int from) {
    for (var index = from; index < lines.length; index++) {
      if (_looksLikeDateRange(lines[index])) {
        return index;
      }
    }
    return -1;
  }

  static List<String> _headerLinesBeforeDate(
    List<String> block,
    int start,
    int dateIndex, {
    int maxLines = 3,
  }) {
    final lines = <String>[];
    for (var index = dateIndex - 1; index >= start && lines.length < maxLines; index--) {
      final candidate = _stripEmploymentQualifier(block[index]);
      if (_looksLikeSection(candidate) || _looksLikeDateRange(candidate)) {
        break;
      }
      if (_looksLikeLocation(candidate) || _isExperienceMetaLine(candidate)) {
        continue;
      }
      lines.insert(0, candidate);
    }
    return lines;
  }

  static ({String position, String company}) _parseExperienceHeader(List<String> rawLines) {
    final lines = rawLines.where((line) => line.trim().isNotEmpty).toList(growable: false);
    if (lines.isEmpty) {
      return (position: '', company: '');
    }

    if (lines.length == 1) {
      return _splitPositionAndCompany(lines.first);
    }

    String company = '';
    for (final line in lines.reversed) {
      if (_looksLikeCompany(line)) {
        company = line;
        break;
      }
    }

    if (company.isNotEmpty) {
      for (final line in lines) {
        if (line != company) {
          return (position: line, company: company);
        }
      }
      return (position: '', company: company);
    }

    return (position: lines.first, company: lines[1]);
  }

  static ({String institution, String degree, String fieldOfStudy}) _parseEducationHeader(List<String> rawLines) {
    final lines = rawLines.where((line) => line.trim().isNotEmpty).toList(growable: false);
    if (lines.isEmpty) {
      return (institution: '', degree: '', fieldOfStudy: '');
    }

    if (lines.length == 1) {
      return (institution: lines.first, degree: '', fieldOfStudy: '');
    }

    final schoolIndex = lines.lastIndexWhere(_looksLikeSchool);
    final institution = schoolIndex >= 0 ? lines[schoolIndex] : lines.last;
    final studyLines = <String>[
      for (var index = 0; index < lines.length; index++)
        if (index != schoolIndex) lines[index],
    ];

    if (studyLines.isEmpty) {
      return (institution: institution, degree: '', fieldOfStudy: '');
    }

    var degree = studyLines.first;
    var fieldOfStudy = studyLines.length > 1
        ? studyLines.skip(1).join(' ').trim()
        : '';

    if (degree.contains(',')) {
      final degreeParts = degree.split(',');
      degree = degreeParts.first.trim();
      final degreeField = degreeParts.skip(1).join(',').trim();
      if (degreeField.isNotEmpty) {
        fieldOfStudy = fieldOfStudy.isEmpty
            ? degreeField
            : '$degreeField $fieldOfStudy'.trim();
      }
    }

    return (
      institution: institution,
      degree: degree,
      fieldOfStudy: fieldOfStudy,
    );
  }

  static ({String position, String company}) _splitPositionAndCompany(String line) {
    final atMatch = RegExp(r'^(.+?)\s+(?:at|@)\s+(.+)$', caseSensitive: false)
        .firstMatch(line);
    if (atMatch != null) {
      return (
        position: atMatch.group(1)?.trim() ?? '',
        company: atMatch.group(2)?.trim() ?? '',
      );
    }

    return (position: line.trim(), company: '');
  }

  static bool _startsNextExperienceEntry(List<String> block, int index) {
    if (_looksLikeDateRange(block[index]) &&
        _textBeforeDateRange(block[index]).isNotEmpty) {
      return true;
    }
    if (!_looksLikePotentialExperienceHeader(block[index])) {
      return false;
    }
    if (index + 1 < block.length && _looksLikeDateRange(block[index + 1])) {
      return true;
    }
    if (index + 2 < block.length &&
        _looksLikePotentialExperienceHeader(block[index + 1]) &&
        _looksLikeDateRange(block[index + 2])) {
      return true;
    }
    return false;
  }

  static bool _looksLikePotentialExperienceHeader(String line) {
    if (line.trim().isEmpty) return false;
    if (_looksLikeSection(line) || _looksLikeLocation(line) || _containsEmail(line)) {
      return false;
    }
    if (_containsPhone(line) || _containsLinkedInUrl(line) || _looksLikeDateRange(line)) {
      return false;
    }
    return !_isExperienceMetaLine(line);
  }

  static bool _isExperienceMetaLine(String line) {
    final normalized = line.toLowerCase();
    return _looksLikeContactLabel(line) ||
        _isDescriptionLabel(line) ||
        _looksLikeEmploymentType(normalized) ||
        RegExp(r'^\d+\s+yrs?', caseSensitive: false).hasMatch(normalized);
  }

  static bool _isDescriptionLabel(String line) {
    final normalized = line.toLowerCase().replaceAll(':', '').trim();
    return normalized == 'description';
  }

  static String _stripBulletPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[\-•*]+\s*'), '').trim();
  }

  static bool _startsContactBlock(List<String> block, int index) {
    final current = block[index];
    if (_hasContactDetail(current) || _looksLikeContactLabel(current)) {
      return true;
    }
    final wordCount = current
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    final looksLikeIdentityAnchor =
        _looksLikeLocation(current) || (_looksLikeIdentityLine(current) && wordCount >= 2);
    if (!looksLikeIdentityAnchor) {
      return false;
    }

    final end = index + 4 < block.length ? index + 4 : block.length - 1;
    for (var i = index + 1; i <= end; i++) {
      if (_hasContactDetail(block[i])) {
        return true;
      }
    }
    return false;
  }

  static bool _looksLikeEmploymentType(String value) {
    return const [
      'full-time',
      'part-time',
      'contract',
      'freelance',
      'self-employed',
      'internship',
      'apprenticeship',
      'temporary',
      'remote',
      'hybrid',
      'on-site',
    ].contains(value.trim());
  }

  static String _textBeforeDateRange(String line) {
    final match = RegExp(
      r'^(.*?)(?=(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec|\d{4}).*(?:-|–|—))',
      caseSensitive: false,
    ).firstMatch(line);
    return match?.group(1)?.trim() ?? '';
  }

  static ({String company, String location}) _splitCompanyAndLocation(String line) {
    final pipeParts = line
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (pipeParts.length >= 2) {
      return (
        company: pipeParts.first,
        location: pipeParts.skip(1).join(' | '),
      );
    }

    final dashParts = line
        .split(RegExp(r'\s+[\-–—]\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (dashParts.length >= 2) {
      return (
        company: dashParts.first,
        location: dashParts.skip(1).join(', '),
      );
    }

    return (company: line.trim(), location: '');
  }

  static bool _looksLikeWorkLocation(String line) {
    final normalized = line.trim().toLowerCase();
    return _looksLikeLocation(line) ||
        normalized == 'remote' ||
        normalized == 'hybrid' ||
        normalized == 'on-site' ||
        normalized == 'onsite';
  }

  static String _stripEmploymentQualifier(String line) {
    final parts = line.split('·').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.length > 1 && _looksLikeEmploymentType(parts.last.toLowerCase())) {
      return parts.first;
    }
    return line.trim();
  }

  static bool _looksLikeCompany(String line) {
    return RegExp(
      r'\b(inc|llc|ltd|limited|corp|corporation|company|co\.?|consultancy|services|solutions|technologies|systems|group|university|college|school|institute|bank)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _looksLikeSchool(String line) {
    return RegExp(
      r'\b(university|college|school|institute|academy)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _looksLikeProjectTitle(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty || _looksLikeUrl(normalized)) {
      return false;
    }
    if (normalized.length > 60) {
      return false;
    }
    if (normalized.endsWith('.')) {
      return false;
    }
    final wordCount = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .length;
    return wordCount <= 6;
  }

  static bool _looksLikeCertificationTitle(String line) {
    return RegExp(
      r'\b(certification|certified|certificate|license|licence)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _looksLikeUrl(String line) {
    return _looksLikeWebsiteLine(line);
  }

  static bool _isCertificationMetaLine(String line) {
    return _looksLikeDateRange(line) ||
        RegExp(r'^issued\s', caseSensitive: false).hasMatch(line) ||
        RegExp(r'^credential', caseSensitive: false).hasMatch(line);
  }

  static DateTime? _parseIssuedDate(String line) {
    final match = RegExp(
      r'issued\s+([a-z]{3,9})?\s*(\d{4})',
      caseSensitive: false,
    ).firstMatch(line);
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(2) ?? '');
    if (year == null) {
      return null;
    }

    final month = _monthNumber(match.group(1));
    return DateTime(year, month ?? 1);
  }

  static String? _extractCredentialId(String line) {
    final match = RegExp(r'credential id\s*:\s*(.+)$', caseSensitive: false)
        .firstMatch(line);
    return match?.group(1)?.trim();
  }

  static int? _monthNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    const months = <String, int>{
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return months[value.trim().toLowerCase()];
  }

  static String _extractLanguageName(String line) {
    final match = RegExp(r'^([A-Za-z][A-Za-z\s]+?)(?:\s*(?:\||[-–(]).*)?$').firstMatch(line);
    final value = match?.group(1)?.trim() ?? '';
    if (value.isEmpty || _looksLikeLocation(value) || _looksLikeContactLabel(value)) {
      return '';
    }
    return value;
  }

  static String _extractLanguageProficiency(String line) {
    final normalized = line.toLowerCase();
    if (normalized.contains('native')) return 'Native';
    if (normalized.contains('fluent')) return 'Fluent';
    if (normalized.contains('professional')) return 'Professional';
    if (normalized.contains('basic') || normalized.contains('beginner')) {
      return 'Beginner';
    }
    return 'Professional';
  }

  static DateTime _extractStart(String dates) {
    final m = RegExp(r'\d{4}').firstMatch(dates);
    final year = m != null ? int.tryParse(m.group(0)!) ?? DateTime.now().year : DateTime.now().year;
    return DateTime(year);
  }

  static DateTime? _extractEnd(String dates) {
    if (dates.toLowerCase().contains('present')) return null;
    final all = RegExp(r'\d{4}').allMatches(dates).toList();
    if (all.length >= 2) {
      final year = int.tryParse(all.last.group(0)!);
      if (year != null) return DateTime(year);
    }
    return null;
  }
}
