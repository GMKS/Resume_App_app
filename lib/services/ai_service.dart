import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' as td;
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart' as ar;
import 'package:url_launcher/url_launcher.dart';

import 'ai_resume_service.dart';

/// Smart Assist tip generator
///
/// Tries AI-powered feedback first; if unavailable, falls back to
/// fast, local heuristics to provide actionable guidance.
Future<String> getResumeTips(String resumeContent) async {
  final text = resumeContent.trim();
  if (text.isEmpty) {
    return 'Paste your resume content above to get personalized tips.';
  }

  final tips = <String>[];

  // 1) Try AI feedback (best effort)
  try {
    final feedback = await AIResumeService.getFeedback(
      content: text,
      section: 'resume',
    );
    final score = feedback['score'];
    final suggestions = (feedback['suggestions'] is List)
        ? List<String>.from(feedback['suggestions'])
        : <String>[];

    if (score is num) {
      tips.add('Overall quality score: ${score.toInt()}/100');
    }
    // Add top 5 AI suggestions
    for (final s in suggestions.take(5)) {
      final line = s.toString().trim();
      if (line.isNotEmpty) tips.add(line);
    }
  } catch (_) {
    // Ignore; weâ€™ll provide heuristic tips below
  }

  // 2) Heuristic tips (always available)
  tips.addAll(_heuristicTips(text));

  // De-duplicate while preserving order
  final seen = <String>{};
  final uniqueTips = <String>[];
  for (final t in tips) {
    final key = t.toLowerCase();
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    uniqueTips.add(t);
  }

  if (uniqueTips.isEmpty) {
    return 'No specific issues found. Looks good! Consider tailoring to a specific job description for higher ATS match.';
  }

  // Combine into a readable block
  final buffer = StringBuffer('Smart Tips:\n');
  for (final t in uniqueTips) {
    buffer.writeln('â€¢ $t');
  }
  return buffer.toString().trim();
}

List<String> _heuristicTips(String text) {
  final tips = <String>[];
  final lower = text.toLowerCase();

  // Length and conciseness
  final wordCount = _wordCount(text);
  if (wordCount > 900) {
    tips.add(
      'Your resume is quite long (~$wordCount words). Aim for a concise one-page summary if possible.',
    );
  } else if (wordCount < 80) {
    tips.add(
      'Consider adding more detail (projects, achievements, impact). The content is very brief (~$wordCount words).',
    );
  }

  // Numbers and quantification
  final hasNumbers = RegExp(r'[\d%]').hasMatch(text);
  if (!hasNumbers) {
    tips.add(
      'Add quantifiable results (e.g., â€œincreased revenue by 15%â€, â€œreduced latency by 200msâ€).',
    );
  }

  // Contact info
  final hasEmail = RegExp(r'[\w\.+-]+@[\w-]+\.[\w\.-]+').hasMatch(text);
  final hasPhone = RegExp(r'(\+?\d[\d\s\-()]{7,})').hasMatch(text);
  if (!hasEmail || !hasPhone) {
    tips.add('Include complete contact info (email and phone).');
  }

  // LinkedIn/Portfolio
  if (!lower.contains('linkedin') &&
      !RegExp(r'https?://[^\s]+').hasMatch(text)) {
    tips.add(
      'Add a LinkedIn or Portfolio URL to showcase projects and credibility.',
    );
  }

  // Skills section
  if (!lower.contains('skill')) {
    tips.add(
      'Include a clear Skills section with relevant keywords (match target job description).',
    );
  }

  // Experience bullets
  final bulletCount = RegExp(
    r'^(\s*[â€¢\-\*])',
    multiLine: true,
  ).allMatches(text).length;
  if (bulletCount < max(2, (wordCount / 200).floor())) {
    tips.add(
      'Use concise bullet points under each role to highlight impact and scope.',
    );
  }

  // Dates format
  if (!RegExp(
        r'\d{4}\s?[-â€“]\s?(\d{4}|present)',
        caseSensitive: false,
      ).hasMatch(lower) &&
      !RegExp(r'\d{4}-\d{2}').hasMatch(lower)) {
    tips.add(
      'Use consistent date ranges (e.g., â€œ2023-01 â€“ 2024-06â€ or â€œ2023 â€“ Presentâ€).',
    );
  }

  // Action verbs suggestion (heuristic check of sentence starts)
  final lines = text
      .split(RegExp(r'\r?\n+'))
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final verbStarters = RegExp(
    r'^(Led|Built|Improved|Increased|Reduced|Designed|Developed|Managed|Owned|Implemented|Optimized)\b',
    caseSensitive: false,
  );
  final actionStartCount = lines
      .where((l) => verbStarters.hasMatch(l.trim()))
      .length;
  if (actionStartCount < max(2, (lines.length * 0.2).round())) {
    tips.add(
      'Start bullets with strong action verbs (Led, Built, Improved, Designed, etc.).',
    );
  }

  return tips;
}

int _wordCount(String text) => RegExp(r'[A-Za-z0-9_]+').allMatches(text).length;

// ===================== Advanced Smart Assist =====================

enum SectionStatus { good, warn, missing }

class SectionInsight {
  final String name;
  final SectionStatus status;
  final List<String> notes;
  SectionInsight({
    required this.name,
    required this.status,
    this.notes = const [],
  });
}

class SmartAssistResult {
  final List<SectionInsight> sections;
  final String suggestedSummary;
  final List<String> suggestedKeywords;
  final List<String> atsTerms;
  final List<String> enhancedBullets;
  final List<String> grammarSuggestions;
  final List<String> alerts;
  final String improvedPlainText;
  // Structured fields for formatted preview
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? location;
  final String? website;
  final String? linkedIn;
  final String? twitter;
  final List<String> coreSkills;
  final Map<String, String> sectionsRaw;
  SmartAssistResult({
    required this.sections,
    required this.suggestedSummary,
    required this.suggestedKeywords,
    required this.atsTerms,
    required this.enhancedBullets,
    required this.grammarSuggestions,
    required this.alerts,
    required this.improvedPlainText,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.location,
    required this.website,
    required this.linkedIn,
    required this.twitter,
    required this.coreSkills,
    required this.sectionsRaw,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== SMART ASSIST ANALYSIS ===');
    buffer.writeln('Name: $name');
    buffer.writeln('Role: $role');

    if (email?.isNotEmpty == true) buffer.writeln('Email: $email');
    if (phone?.isNotEmpty == true) buffer.writeln('Phone: $phone');

    buffer.writeln('\nSUMMARY:');
    buffer.writeln(suggestedSummary);

    if (coreSkills.isNotEmpty) {
      buffer.writeln('\nCORE SKILLS:');
      buffer.writeln(coreSkills.join(', '));
    }

    if (enhancedBullets.isNotEmpty) {
      buffer.writeln('\nENHANCED EXPERIENCE:');
      for (final bullet in enhancedBullets) {
        buffer.writeln('â€¢ $bullet');
      }
    }

    return buffer.toString();
  }
}

/// Analyze resume content and return structured insights + improved content.
Future<SmartAssistResult> analyzeResume({
  required String resumeContent,
  String? jobDescription,
  String? targetRole,
}) async {
  final text = resumeContent.trim();
  final role = (targetRole ?? '').trim();
  final sections = _detectSections(text);
  final name = _extractName(text);
  final contacts = _extractContacts(text);

  // Section scoring
  final insights = <SectionInsight>[];
  void addSection(String key, String display) {
    final content = sections[key] ?? '';
    if (content.isEmpty) {
      insights.add(
        SectionInsight(name: display, status: SectionStatus.missing),
      );
    } else {
      final wc = _wordCount(content);
      if (wc < 15) {
        insights.add(
          SectionInsight(
            name: display,
            status: SectionStatus.warn,
            notes: ['Content is very brief; add more specifics and results.'],
          ),
        );
      } else {
        insights.add(SectionInsight(name: display, status: SectionStatus.good));
      }
    }
  }

  addSection('summary', 'Summary');
  addSection('experience', 'Experience');
  addSection('education', 'Education');
  addSection('skills', 'Skills');
  addSection('projects', 'Projects');
  addSection('certifications', 'Certifications');

  // Professional summary generation (AI first, fallback)
  String suggestedSummary = '';
  try {
    suggestedSummary = await AIResumeService.generateSummary(
      name: name,
      targetRole: role.isNotEmpty ? role : 'Professional',
      skills: _extractSkillsFromText(sections['skills'] ?? ''),
      experience: _extractHighlightsFromExperience(
        sections['experience'] ?? '',
      ),
    );
  } catch (_) {
    final skills = _extractSkillsFromText(sections['skills'] ?? '');
    suggestedSummary = _fallbackSummary(role, skills);
  }

  // Keyword optimization (very light heuristic + ATS terms)
  final suggestedKeywords = <String>[];
  final atsTerms = <String>[];
  if (jobDescription != null && jobDescription.trim().isNotEmpty) {
    final jd = jobDescription.toLowerCase();
    final common = [
      'leadership',
      'communication',
      'team',
      'problem',
      'design',
      'security',
      'testing',
      'cloud',
      'agile',
      'data',
    ];
    for (final k in common) {
      if (jd.contains(k) && !text.toLowerCase().contains(k)) {
        suggestedKeywords.add(k);
      }
    }
    atsTerms.addAll([
      'Responsibilities',
      'Achievements',
      'Technologies',
      'Tools',
    ]);
  }

  // Bullet point enhancer
  final experienceContent = sections['experience'] ?? '';
  final srcBullets = _extractBullets(experienceContent);
  List<String> enhancedBullets = [];
  if (srcBullets.isNotEmpty) {
    // Try AI rewrite using bullet generator when possible
    try {
      final joined = srcBullets.take(1).join(' ');
      final aiBullets = await AIResumeService.generateBulletPoints(
        jobTitle: role.isNotEmpty ? role : 'Professional',
        company: '',
        description: joined,
        count: max(3, min(5, srcBullets.length)),
      );
      enhancedBullets = aiBullets;
    } catch (_) {
      enhancedBullets = srcBullets.map(_rewriteBulletHeuristic).toList();
    }
  }

  // Grammar & clarity heuristics
  final grammarSuggestions = _grammarClaritySuggestions(text);

  // Smart alerts
  final alerts = _smartAlerts(text, sections);

  // Compose improved plain text
  final improved = _composeImprovedText(
    original: text,
    sections: sections,
    newSummary: suggestedSummary,
    enhancedBullets: enhancedBullets,
  );

  return SmartAssistResult(
    sections: insights,
    suggestedSummary: suggestedSummary,
    suggestedKeywords: suggestedKeywords,
    atsTerms: atsTerms,
    enhancedBullets: enhancedBullets,
    grammarSuggestions: grammarSuggestions,
    alerts: alerts,
    improvedPlainText: improved,
    name: name,
    role: role.isNotEmpty ? role : 'Professional',
    email: contacts['email'],
    phone: contacts['phone'],
    location: contacts['location'],
    website: contacts['website'],
    linkedIn: contacts['linkedin'],
    twitter: contacts['twitter'],
    coreSkills: _extractSkillsFromText(sections['skills'] ?? ''),
    sectionsRaw: sections,
  );
}

Map<String, String> _detectSections(String text) {
  final lower = text.toLowerCase();
  final keys = {
    'summary': RegExp(r'\b(summary|objective|profile)\b', caseSensitive: false),
    'experience': RegExp(
      r'\b(experience|work|employment)\b',
      caseSensitive: false,
    ),
    'education': RegExp(
      r'\b(education|academics|university|college|school)\b',
      caseSensitive: false,
    ),
    'skills': RegExp(r'\b(skills|technologies|tools)\b', caseSensitive: false),
    'projects': RegExp(r'\b(projects)\b', caseSensitive: false),
    'certifications': RegExp(
      r'\b(certifications|certificates)\b',
      caseSensitive: false,
    ),
  };
  // Simple heading-based split
  final map = <String, String>{};
  for (final entry in keys.entries) {
    final idx = lower.indexOf(entry.value);
    if (idx >= 0) {
      // Take from heading to next heading or end
      final nextIdx = keys.entries
          .where((e) => e.key != entry.key)
          .map((e) => lower.indexOf(e.value))
          .where((i) => i > idx)
          .fold<int>(text.length, (p, c) => c < p ? c : p);
      map[entry.key] = text.substring(idx, nextIdx).trim();
    }
  }
  return map;
}

String _extractName(String text) {
  // Assume first non-empty line is name
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return lines.isNotEmpty ? lines.first : 'Candidate';
}

Map<String, String?> _extractContacts(String text) {
  final map = <String, String?>{};
  final email = RegExp(r'[\w\.+-]+@[\w-]+\.[\w\.-]+').firstMatch(text);
  final phone = RegExp(r'(\+?\d[\d\s\-()]{7,})').firstMatch(text);
  final urlMatch = RegExp(r'https?://[^\s)]+').firstMatch(text);
  final linkedin = RegExp(
    r'linkedin\.com/[^\s)]+',
    caseSensitive: false,
  ).firstMatch(text);
  final twitter = RegExp(
    r'(twitter|x)\.com/[^\s)]+',
    caseSensitive: false,
  ).firstMatch(text);
  // Naive location: search for a line with a comma and <= 3 letter state/country
  String? location;
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final l = raw.trim();
    if (RegExp(r'[,]\s*[A-Za-z]{2,3}(\b|\.)').hasMatch(l) &&
        l.length < 60 &&
        !l.contains('@') &&
        !l.toLowerCase().startsWith('summary')) {
      location = l;
      break;
    }
  }
  map['email'] = email?.group(0);
  map['phone'] = phone?.group(0)?.replaceAll(RegExp(r'\s+'), ' ').trim();
  map['website'] = urlMatch?.group(0);
  map['linkedin'] = linkedin?.group(0);
  map['twitter'] = twitter?.group(0);
  map['location'] = location;
  return map;
}

List<String> _extractSkillsFromText(String skillsBlock) {
  if (skillsBlock.isEmpty) return const [];
  final csv = skillsBlock
      .split(RegExp(r'[\n,â€¢]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return csv.take(20).toList();
}

List<String> _extractHighlightsFromExperience(String exp) {
  if (exp.isEmpty) return const [];
  final bullets = _extractBullets(exp);
  return bullets.take(5).toList();
}

List<String> _extractBullets(String block) {
  final lines = block.split(RegExp(r'\r?\n'));
  return lines
      .map((l) => l.trim())
      .where(
        (l) => l.startsWith('â€¢') || l.startsWith('-') || l.startsWith('*'),
      )
      .map((l) => l.replaceFirst(RegExp(r'^[â€¢\-*]\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();
}

String _rewriteBulletHeuristic(String input) {
  var s = input.trim();
  // Replace weak starters
  s = s.replaceFirst(
    RegExp(r'^(worked on|helped|assisted in)\b', caseSensitive: false),
    'Developed',
  );
  // Add quantifier hint if none
  if (!RegExp(r'[\d%]').hasMatch(s)) {
    s += ' (achieved measurable impact, e.g., 20% improvement).';
  }
  // Prefer strong verbs
  s = s.replaceAll(RegExp(r'\bmade\b', caseSensitive: false), 'delivered');
  s = s.replaceAll(RegExp(r'\bused\b', caseSensitive: false), 'leveraged');
  return s;
}

List<String> _grammarClaritySuggestions(String text) {
  final out = <String>[];
  // Passive voice heuristic
  final passive = RegExp(
    r'\b(was|were|been|be|being)\b\s+\w+\b\s+by\b',
    caseSensitive: false,
  );
  if (passive.hasMatch(text)) {
    out.add(
      'Reduce passive voice (e.g., â€œwas implemented byâ€) to active voice.',
    );
  }
  // Long sentences
  final sentences = text.split(RegExp(r'[.!?]'));
  for (final s in sentences) {
    final wc = _wordCount(s);
    if (wc > 30) {
      out.add('Break long sentences (>30 words) into concise statements.');
      break;
    }
  }
  return out;
}

List<String> _smartAlerts(String text, Map<String, String> sections) {
  final alerts = <String>[];
  final wc = _wordCount(text);
  if (wc > 1200) {
    alerts.add('Resume may be too long; consider a concise one-page version.');
  }
  if (wc < 100) {
    alerts.add(
      'Resume seems too short; add details (impact, metrics, projects).',
    );
  }

  // Date consistency
  final dateRanges = RegExp(
    r'(\d{4})\s?[\u2013\-]\s?(\d{4}|present)',
    caseSensitive: false,
  ).allMatches(text).toList();
  for (final m in dateRanges) {
    final start = int.tryParse(m.group(1) ?? '0') ?? 0;
    final endStr = (m.group(2) ?? '0').toLowerCase();
    if (endStr != 'present') {
      final end = int.tryParse(endStr) ?? start;
      if (end < start) {
        alerts.add('Found a date range where end year < start year.');
        break;
      }
    }
  }

  // Outdated skills simple list
  final outdated = ['windows xp', 'ms office', 'ms word', 'cobol'];
  final lower = text.toLowerCase();
  for (final o in outdated) {
    if (lower.contains(o)) {
      alerts.add(
        'Consider removing or downplaying outdated skill: ${o.toUpperCase()}',
      );
    }
  }
  if (!(sections['skills'] ?? '').contains(RegExp(r'[A-Za-z]'))) {
    alerts.add('Skills section seems missing or empty.');
  }
  return alerts;
}

String _fallbackSummary(String role, List<String> skills) {
  final top = skills.take(3).toList();
  final skillLine = top.isNotEmpty ? top.join(', ') : 'core competencies';
  return '${role.isNotEmpty ? role : 'Professional'} with strengths in $skillLine. Proven ability to deliver results and collaborate across teams; seeking to drive impact in a ${role.isNotEmpty ? role : 'new role'}.';
}

String _composeImprovedText({
  required String original,
  required Map<String, String> sections,
  required String newSummary,
  required List<String> enhancedBullets,
}) {
  final b = StringBuffer();
  b.writeln('SUMMARY');
  b.writeln(newSummary);
  b.writeln('');
  if (sections['skills']?.isNotEmpty == true) {
    b.writeln('SKILLS');
    b.writeln(sections['skills']!.trim());
    b.writeln('');
  }
  if (sections['experience']?.isNotEmpty == true) {
    b.writeln('EXPERIENCE');
    if (enhancedBullets.isNotEmpty) {
      for (final e in enhancedBullets) {
        b.writeln('â€¢ $e');
      }
    } else {
      b.writeln(sections['experience']!.trim());
    }
    b.writeln('');
  }
  if (sections['projects']?.isNotEmpty == true) {
    b.writeln('PROJECTS');
    b.writeln(sections['projects']!.trim());
    b.writeln('');
  }
  if (sections['education']?.isNotEmpty == true) {
    b.writeln('EDUCATION');
    b.writeln(sections['education']!.trim());
    b.writeln('');
  }
  if (sections['certifications']?.isNotEmpty == true) {
    b.writeln('CERTIFICATIONS');
    b.writeln(sections['certifications']!.trim());
  }
  return b.toString().trim();
}

// ===================== Export helpers =====================

Future<File> exportSmartAssistTxt(
  String content, {
  String fileName = 'resume_improved',
}) async {
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.txt'));
  await file.writeAsString(content);
  return file;
}

Future<File> exportSmartAssistDocx(
  String content, {
  String fileName = 'resume_improved',
}) async {
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.docx'));

  // Build DOCX bytes and write
  final bytes = buildDocxBytesFromPlainText(content);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Export DOCX that mirrors the styled Smart Assist preview from a result.
Future<File> exportSmartAssistDocxFromResult(
  SmartAssistResult res, {
  String fileName = 'resume_improved',
}) async {
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.docx'));
  final lines = _buildStructuredLines(res);
  final bytes = buildDocxBytesFromPlainText(lines.join('\n'));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Build a minimal, valid DOCX (WordprocessingML) from plain text lines.
/// Returns the .docx zip bytes for testing or custom I/O.
List<int> buildDocxBytesFromPlainText(String content) {
  final zip = ar.Archive();
  zip.addFile(ar.ArchiveFile.string('[Content_Types].xml', _contentTypesXml));
  zip.addFile(ar.ArchiveFile.string('_rels/.rels', _relsXml));
  zip.addFile(ar.ArchiveFile.string('docProps/app.xml', _appPropsXml));
  zip.addFile(ar.ArchiveFile.string('docProps/core.xml', _corePropsXml));
  zip.addFile(
    ar.ArchiveFile.string('word/document.xml', _buildDocumentXml(content)),
  );
  zip.addFile(ar.ArchiveFile.string('word/styles.xml', _stylesXml));
  zip.addFile(
    ar.ArchiveFile.string('word/_rels/document.xml.rels', _wordRelsXml),
  );
  return ar.ZipEncoder().encode(zip)!;
}

Future<File> exportSmartAssistPdf(
  String content, {
  String fileName = 'resume_improved',
}) async {
  final bytes = _buildMinimalPdfFromText(content.split('\n'));
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.pdf'));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Styled PDF that mirrors the on-screen formatted preview.
Future<File> exportSmartAssistStyledPdfFromResult(
  SmartAssistResult res, {
  String fileName = 'resume_improved',
}) async {
  final bytes = await _buildStyledPdfBytes(res);
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.pdf'));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Export TXT that mirrors the styled Smart Assist preview from a result.
Future<File> exportSmartAssistTxtFromResult(
  SmartAssistResult res, {
  String fileName = 'resume_improved',
}) async {
  final outDir = await _getExportBaseDir();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final file = File(p.join(outDir.path, '${fileName}_$ts.txt'));
  final lines = _buildStructuredLines(res);
  await file.writeAsString(lines.join('\n'));
  return file;
}

/// Resolve a user-visible export directory:
/// - Android: app-specific external files dir: /storage/emulated/0/Android/data/<package>/files/Resumes
/// - iOS/others: app documents dir: <app-docs>/Resumes
Future<Directory> _getExportBaseDir() async {
  Directory base;
  if (Platform.isAndroid) {
    base =
        (await getExternalStorageDirectory()) ?? await getTemporaryDirectory();
  } else {
    base = await getApplicationDocumentsDirectory();
  }
  final out = Directory(p.join(base.path, 'Resumes'));
  if (!await out.exists()) {
    await out.create(recursive: true);
  }
  return out;
}

List<int> _buildMinimalPdfFromText(List<String> lines) {
  const pageWidth = 595, pageHeight = 842;
  const marginLeft = 50, marginTop = 50, fontSize = 12, leading = 16;
  final wrapped = <String>[];
  for (final l in lines) {
    final ascii = _toAscii(l);
    if (ascii.length <= 90) {
      wrapped.add(ascii);
    } else {
      wrapped.addAll(_wrapByChars(ascii, 90));
    }
  }
  final buffer = StringBuffer()
    ..writeln('BT')
    ..writeln('/F1 $fontSize Tf')
    ..writeln('$leading TL')
    ..writeln('1 0 0 1 $marginLeft ${pageHeight - marginTop} Tm');
  for (var i = 0; i < wrapped.length; i++) {
    final txt = _pdfEscape(wrapped[i]);
    if (i == 0) {
      buffer.writeln('($txt) Tj');
    } else {
      buffer.writeln('T*');
      buffer.writeln('($txt) Tj');
    }
  }
  buffer.writeln('ET');
  final content = utf8.encode(buffer.toString());
  final out = td.BytesBuilder();
  final offsets = <int>[];
  void w(String s) => out.add(utf8.encode(s));
  w('%PDF-1.4\n');
  offsets.add(out.length);
  w('1 0 obj\n');
  w('<< /Type /Catalog /Pages 2 0 R >>\n');
  w('endobj\n');
  offsets.add(out.length);
  w('2 0 obj\n');
  w('<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n');
  w('endobj\n');
  offsets.add(out.length);
  w('3 0 obj\n');
  w('<< /Type /Page /Parent 2 0 R ');
  w(
    '/MediaBox [0 0 $pageWidth $pageHeight] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\n',
  );
  w('endobj\n');
  offsets.add(out.length);
  w('4 0 obj\n');
  w('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n');
  w('endobj\n');
  offsets.add(out.length);
  w('5 0 obj\n');
  w('<< /Length ${content.length} >>\n');
  w('stream\n');
  out.add(content);
  w('\nendstream\nendobj\n');
  final xrefStart = out.length;
  w('xref\n');
  w('0 6\n');
  w('0000000000 65535 f \n');
  for (final off in offsets) {
    final line = off.toString().padLeft(10, '0');
    w('$line 00000 n \n');
  }
  w('trailer\n');
  w('<< /Size 6 /Root 1 0 R >>\n');
  w('startxref\n');
  w('$xrefStart\n');
  w('%%EOF');
  return out.takeBytes();
}

String _toAscii(String input) {
  final sb = StringBuffer();
  for (final cu in input.codeUnits) {
    if (cu >= 32 && cu <= 126) {
      sb.writeCharCode(cu);
    } else {
      sb.write('?');
    }
  }
  return sb.toString();
}

String _pdfEscape(String text) =>
    text.replaceAll('\\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

List<String> _wrapByChars(String text, int maxChars) {
  final words = text.split(RegExp(r'\s+'));
  final lines = <String>[];
  var current = StringBuffer();
  for (final w in words) {
    if (current.isEmpty) {
      current.write(w);
    } else if ((current.length + 1 + w.length) <= maxChars) {
      current.write(' ');
      current.write(w);
    } else {
      lines.add(current.toString());
      current = StringBuffer(w);
    }
  }
  if (current.isNotEmpty) lines.add(current.toString());
  return lines;
}

// Normalize some unicode characters that default PDF fonts may not support.
String _normalizeForPdf(String input) {
  return input
      .replaceAll('\u2013', '-') // en dash
      .replaceAll('\u2014', '-') // em dash
      .replaceAll('\u2019', "'") // right single quote
      .replaceAll('\u2018', "'") // left single quote
      .replaceAll('\u2022', 'â€¢'); // bullet
}

Future<List<int>> _buildStyledPdfBytes(SmartAssistResult res) async {
  try {
    print('DEBUG: Starting PDF generation for ${res.name}');
    final doc = pw.Document();
    final blue = PdfColor.fromHex('#1E4F8A');
    final blueLight = PdfColor.fromHex('#A8C5E6');

    // Build contact row parts
    final contacts = <String>[];
    if ((res.phone ?? '').isNotEmpty) contacts.add(res.phone!);
    if ((res.email ?? '').isNotEmpty) contacts.add(res.email!);
    if ((res.location ?? '').isNotEmpty) contacts.add(res.location!);
    if ((res.website ?? '').isNotEmpty) contacts.add(res.website!);
    if ((res.linkedIn ?? '').isNotEmpty) contacts.add(res.linkedIn!);
    if ((res.twitter ?? '').isNotEmpty) contacts.add(res.twitter!);

    // Include ALL experience bullets - no limits
    final bullets = res.enhancedBullets.isNotEmpty
        ? res.enhancedBullets
        : _extractBullets(res.sectionsRaw['experience'] ?? '');

    // Include full summary text - no truncation
    final summary = res.suggestedSummary.isNotEmpty
        ? res.suggestedSummary
        : 'Professional seeking new opportunities.';

    // Include full education text - no limits
    final education = (res.sectionsRaw['education'] ?? '').isNotEmpty
        ? res.sectionsRaw['education']!
        : 'Add your education details.';

    print(
      'DEBUG: Data prepared - contacts: ${contacts.length}, bullets: ${bullets.length}',
    );

    pw.Widget sectionHeader(String title) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 4, top: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: blueLight, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: blue,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        pageFormat: PdfPageFormat.a4,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (ctx) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                res.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: blue,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                res.role,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              pw.SizedBox(height: 8),
              if (contacts.isNotEmpty)
                pw.Center(
                  child: pw.Wrap(
                    alignment: pw.WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: contacts
                        .map(
                          (c) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#EAF2FB'),
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(color: blueLight),
                            ),
                            child: pw.Text(
                              c,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Paragraph(
            text: _normalizeForPdf(summary),
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),

          // Experience - include ALL bullets with full text
          sectionHeader('PROFESSIONAL EXPERIENCE'),
          pw.SizedBox(height: 6),
          if (bullets.isNotEmpty)
            ...bullets.map(
              (b) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Bullet(
                  text: _normalizeForPdf(b),
                ), // Full bullet text, no truncation
              ),
            )
          else
            pw.Paragraph(
              text: _normalizeForPdf(res.sectionsRaw['experience'] ?? ''),
            ),

          // Education - full content
          sectionHeader('EDUCATION'),
          pw.SizedBox(height: 6),
          pw.Paragraph(text: _normalizeForPdf(education)),

          // Skills
          sectionHeader('SKILLS'),
          pw.SizedBox(height: 6),
          if (res.coreSkills.isNotEmpty)
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: res
                  .coreSkills // Include ALL skills
                  .map(
                    (s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: blueLight),
                        borderRadius: pw.BorderRadius.circular(10),
                        color: PdfColor.fromHex('#F4F8FD'),
                      ),
                      child: pw.Text(
                        s,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            pw.Text('List your core skills to showcase strengths.'),
        ],
      ),
    );

    print('DEBUG: PDF generation completed successfully');
    return doc.save();
  } catch (e, stackTrace) {
    print('DEBUG: PDF generation failed with error: $e');
    print('DEBUG: Stack trace: $stackTrace');
    rethrow;
  }
}

// ===================== Share helpers =====================

/// Share the styled PDF via email
Future<void> shareSmartAssistStyledViaEmail(SmartAssistResult result) async {
  final pdfFile = await exportSmartAssistStyledPdfFromResult(result);
  final subject = 'Smart Assist Resume Analysis: ${result.name}';
  final pdfBytes = await pdfFile.readAsBytes();
  final fileName =
      '${result.name.replaceAll(' ', '_')}_analysis_${DateTime.now().millisecondsSinceEpoch}.pdf';

  try {
    final xFile = XFile.fromData(
      pdfBytes,
      mimeType: 'application/pdf',
      name: fileName,
    );

    final params = ShareParams(
      files: [xFile],
      subject: subject,
      text: 'Please find the attached resume analysis.',
      fileNameOverrides: [fileName],
    );

    final shareResult = await SharePlus.instance.share(params);

    if (shareResult.status != ShareResultStatus.success) {
      await _launchEmailFallback(subject);
    }
  } catch (e) {
    await _launchEmailFallback(subject);
  }
}

Future<void> _launchEmailFallback(String subject) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    query:
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent('Please find the attached resume analysis.')}',
  );

  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  } else {
    // Cannot show dialog without context, so just print
    print('Error: Could not open email app.');
  }
}

/// Share the styled PDF via WhatsApp
Future<void> shareSmartAssistStyledViaWhatsApp(SmartAssistResult result) async {
  final pdfFile = await exportSmartAssistStyledPdfFromResult(result);
  final pdfBytes = await pdfFile.readAsBytes();
  final fileName =
      '${result.name.replaceAll(' ', '_')}_analysis_${DateTime.now().millisecondsSinceEpoch}.pdf';

  try {
    final xFile = XFile.fromData(
      pdfBytes,
      mimeType: 'application/pdf',
      name: fileName,
    );

    final params = ShareParams(
      files: [xFile],
      text: 'Here is the resume analysis.',
      fileNameOverrides: [fileName],
    );

    final shareResult = await SharePlus.instance.share(params);

    if (shareResult.status != ShareResultStatus.success) {
      await _launchWhatsAppFallback();
    }
  } catch (e) {
    await _launchWhatsAppFallback();
  }
}

Future<void> _launchWhatsAppFallback() async {
  const message = 'Here is the resume analysis.';
  final whatsappUrl = "https://wa.me/?text=${Uri.encodeComponent(message)}";

  try {
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Error: Could not open WhatsApp.');
    }
  } catch (e) {
    print('Error: Failed to open WhatsApp.');
  }
}

// ---------------- WordprocessingML (DOCX) payloads ----------------

const String _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

const String _relsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

const String _wordRelsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';

const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="character" w:default="1" w:styleId="DefaultParagraphFont">
    <w:name w:val="Default Paragraph Font"/>
  </w:style>
</w:styles>''';

const String _appPropsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Resume Builder</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <Company></Company>
</Properties>''';

const String _corePropsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Resume</dc:title>
  <dc:subject></dc:subject>
  <dc:creator>Resume Builder</dc:creator>
  <cp:keywords>resume</cp:keywords>
  <cp:lastModifiedBy>Resume Builder</cp:lastModifiedBy>
</cp:coreProperties>''';

String _buildDocumentXml(String content) {
  String esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  final parts = content
      .split(RegExp(r'\r?\n+'))
      .where((l) => l.trim().isNotEmpty)
      // Disable proofing to avoid red underlines in Word
      .map(
        (l) =>
            '<w:p><w:r><w:rPr><w:noProof/></w:rPr><w:t>${esc(l)}</w:t></w:r></w:p>',
      )
      .join();
  return '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $parts
  </w:body>
</w:document>''';
}

/// Build the structured lines that mirror the styled preview for TXT/DOCX.
List<String> _buildStructuredLines(SmartAssistResult res) {
  final lines = <String>[];
  // Header
  lines.add(res.name);
  lines.add(res.role);
  final contacts = <String>[];
  if ((res.phone ?? '').isNotEmpty) contacts.add(res.phone!);
  if ((res.email ?? '').isNotEmpty) contacts.add(res.email!);
  if ((res.location ?? '').isNotEmpty) contacts.add(res.location!);
  if ((res.website ?? '').isNotEmpty) contacts.add(res.website!);
  if ((res.linkedIn ?? '').isNotEmpty) contacts.add(res.linkedIn!);
  if ((res.twitter ?? '').isNotEmpty) contacts.add(res.twitter!);
  if (contacts.isNotEmpty) lines.add(contacts.join(' â€¢ '));

  lines.add('');
  lines.add('SUMMARY');
  lines.add(res.suggestedSummary);

  // Experience
  lines.add('');
  lines.add('PROFESSIONAL EXPERIENCE');
  final bullets = res.enhancedBullets.isNotEmpty
      ? res.enhancedBullets
      : _extractBullets(res.sectionsRaw['experience'] ?? '');
  if (bullets.isNotEmpty) {
    for (final b in bullets) {
      lines.add('- $b');
    }
  } else {
    final raw = (res.sectionsRaw['experience'] ?? '').trim();
    if (raw.isNotEmpty) {
      for (final l in raw.split(RegExp(r'\r?\n+'))) {
        final s = l.trim();
        if (s.isEmpty) continue;
        if (s.startsWith(RegExp(r'[â€¢\-*]\s*'))) {
          lines.add('- ${s.replaceFirst(RegExp(r'^[â€¢\-*]\s*'), '')}');
        } else {
          lines.add(s);
        }
      }
    }
  }

  // Education
  final edu = (res.sectionsRaw['education'] ?? '').trim();
  lines.add('');
  lines.add('EDUCATION');
  lines.add(edu.isNotEmpty ? edu : 'Add your education details.');

  // Skills
  lines.add('');
  lines.add('SKILLS');
  if (res.coreSkills.isNotEmpty) {
    lines.add(res.coreSkills.join(', '));
  } else {
    lines.add('List your core skills to showcase strengths.');
  }

  return lines;
}

class AiService {
  /// Generates resume data from pasted text.
  /// Enhanced extraction to capture ALL resume content
  Future<Map<String, dynamic>> generateResumeFromText(String text) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    print('DEBUG AI Service: Starting text extraction...');
    print('DEBUG AI Service: Text length: ${text.length} characters');

    final lines = text.split('\n').map((l) => l.trim()).toList();
    final nonEmptyLines = lines.where((l) => l.isNotEmpty).toList();

    // Extract name (first non-empty line or line before job title)
    String name = 'Your Name';
    String jobTitle = '';

    if (nonEmptyLines.isNotEmpty) {
      name = nonEmptyLines.first;
      // If second line looks like a job title (all caps or title case), capture it
      if (nonEmptyLines.length > 1) {
        final secondLine = nonEmptyLines[1];
        if (secondLine == secondLine.toUpperCase() ||
            RegExp(r'^[A-Z][a-z]+ [A-Z]').hasMatch(secondLine)) {
          jobTitle = secondLine;
        }
      }
    }

    // Extract email
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b');
    final email = emailRegex.firstMatch(text)?.group(0) ?? '';

    // Extract phone (multiple patterns)
    final phoneRegex = RegExp(
      r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\+\d{1,3}\s?\d{4,}',
    );
    final phone = phoneRegex.firstMatch(text)?.group(0) ?? '';

    // Extract location (look for address/city patterns)
    String location = '';
    final locationPatterns = [
      RegExp(
        r'(?:📍|Location:|Address:)\s*(.+?)(?:\n|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'\d+\s+[\w\s]+(?:St\.|Street|Ave|Avenue|Rd|Road|Boulevard|Blvd)[^\n]+',
        caseSensitive: false,
      ),
      RegExp(r'[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?,\s*[A-Z]{2}(?:\s+\d{5})?'),
    ];
    for (final pattern in locationPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        location = match.group(1) ?? match.group(0) ?? '';
        break;
      }
    }

    // Extract LinkedIn
    final linkedInRegex = RegExp(
      r'(?:linkedin\.com/in/|@linkedin:)\s*([\w\-]+)',
      caseSensitive: false,
    );
    final linkedInMatch = linkedInRegex.firstMatch(text);
    final linkedin = linkedInMatch != null
        ? 'https://linkedin.com/in/${linkedInMatch.group(1)}'
        : '';

    // Extract sections using flexible patterns
    Map<String, String> sections = _extractSections(text);

    print('DEBUG AI Service: Extracted sections: ${sections.keys.join(", ")}');

    // Extract summary/profile
    String summary =
        sections['PROFILE'] ??
        sections['SUMMARY'] ??
        sections['PROFESSIONAL SUMMARY'] ??
        sections['OBJECTIVE'] ??
        sections['ABOUT'] ??
        '';

    print('DEBUG AI Service: Summary length: ${summary.length}');

    // Extract skills
    String coreSkills =
        sections['CORE SKILLS'] ??
        sections['KEY SKILLS'] ??
        sections['SKILLS'] ??
        '';

    // Extract technical skills into structured format
    final technicalSkills = <String, String>{};
    final techSkillsText =
        sections['TECHNICAL SKILLS'] ?? sections['TECHNOLOGIES'] ?? '';
    if (techSkillsText.isNotEmpty) {
      final categoryLines = techSkillsText.split('\n');
      for (final line in categoryLines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length == 2) {
            technicalSkills[parts[0].trim()] = parts[1].trim();
          }
        }
      }
    }

    // Extract achievements
    String achievements =
        sections['ACHIEVEMENTS'] ??
        sections['AWARDS'] ??
        sections['HONORS'] ??
        '';

    // Extract work experience with FULL details
    final workExperience = _extractWorkExperience(text, sections);
    print(
      'DEBUG AI Service: Extracted ${workExperience.length} work experiences',
    );

    // Extract education
    final education = _extractEducation(text, sections);
    print('DEBUG AI Service: Extracted ${education.length} education entries');

    // Extract certifications
    String certifications =
        sections['CERTIFICATIONS'] ?? sections['CERTIFICATES'] ?? '';

    // Extract personal details
    final personalDetails = <String, String>{};
    final personalDetailsText =
        sections['PERSONAL DETAILS'] ?? sections['PERSONAL INFORMATION'] ?? '';
    if (personalDetailsText.isNotEmpty) {
      final detailLines = personalDetailsText.split('\n');
      for (final line in detailLines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length == 2) {
            personalDetails[parts[0].trim()] = parts[1].trim();
          }
        }
      }
    }

    final extractedData = {
      'resumeTitle': 'Smart Assist Resume',
      'personalInfo': {
        'name': name,
        'email': email,
        'phone': phone,
        'linkedin': linkedin,
        'location': location,
      },
      'jobTitle': jobTitle,
      'summary': summary,
      'coreSkills': coreSkills,
      'technicalSkills': technicalSkills,
      'skills': coreSkills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'skillsCsv': coreSkills,
      'keySkills': coreSkills,
      'workExperience': workExperience,
      'workExperiencesJson': '[]',
      'education': education,
      'educationsJson': '[]',
      'certifications': certifications,
      'achievements': achievements,
      'personalDetails': personalDetails,
      'hobbies': sections['HOBBIES'] ?? sections['INTERESTS'] ?? '',
      // Store full original text for reference
      'originalText': text,
    };

    print(
      'DEBUG AI Service: Extraction complete. Data keys: ${extractedData.keys.join(", ")}',
    );
    return extractedData;
  }

  /// Extract sections from text based on common headings
  Map<String, String> _extractSections(String text) {
    final sections = <String, String>{};

    // Common section headers (case-insensitive)
    final sectionHeaders = [
      'EDUCATION',
      'EXPERIENCE',
      'WORK EXPERIENCE',
      'PROFESSIONAL EXPERIENCE',
      'EMPLOYMENT HISTORY',
      'PROFILE',
      'SUMMARY',
      'PROFESSIONAL SUMMARY',
      'OBJECTIVE',
      'ABOUT',
      'SKILLS',
      'CORE SKILLS',
      'KEY SKILLS',
      'TECHNICAL SKILLS',
      'TECHNOLOGIES',
      'CERTIFICATIONS',
      'CERTIFICATES',
      'ACHIEVEMENTS',
      'AWARDS',
      'HONORS',
      'PROJECTS',
      'PERSONAL DETAILS',
      'PERSONAL INFORMATION',
      'HOBBIES',
      'INTERESTS',
      'LANGUAGES',
    ];

    final lines = text.split('\n');
    String? currentSection;
    final sectionContent = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final upperLine = line.toUpperCase();

      // Check if this line is a section header
      bool isHeader = false;
      String? matchedHeader;

      for (final header in sectionHeaders) {
        if (upperLine == header ||
            upperLine.startsWith(header) ||
            (line.length < 30 && upperLine.contains(header))) {
          isHeader = true;
          matchedHeader = header;
          break;
        }
      }

      if (isHeader && matchedHeader != null) {
        // Save previous section
        if (currentSection != null && sectionContent.isNotEmpty) {
          sections[currentSection] = sectionContent.join('\n').trim();
        }
        // Start new section
        currentSection = matchedHeader;
        sectionContent.clear();
      } else if (currentSection != null && line.isNotEmpty) {
        // Add to current section
        sectionContent.add(line);
      }
    }

    // Save last section
    if (currentSection != null && sectionContent.isNotEmpty) {
      sections[currentSection] = sectionContent.join('\n').trim();
    }

    return sections;
  }

  /// Extract work experience with full details
  List<Map<String, dynamic>> _extractWorkExperience(
    String text,
    Map<String, String> sections,
  ) {
    final workExperience = <Map<String, dynamic>>[];

    final expText =
        sections['EXPERIENCE'] ??
        sections['WORK EXPERIENCE'] ??
        sections['PROFESSIONAL EXPERIENCE'] ??
        sections['EMPLOYMENT HISTORY'] ??
        '';

    if (expText.isEmpty) return workExperience;

    // Split by common job entry patterns
    final lines = expText.split('\n');
    Map<String, dynamic>? currentJob;
    List<String> responsibilities = [];
    List<Map<String, dynamic>> projects = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if this is a job title line (usually bold/capitalized)
      final isJobTitle =
          line == line.toUpperCase() ||
          RegExp(r'^[A-Z][a-z]+ [A-Z]').hasMatch(line) ||
          line.contains('Engineer') ||
          line.contains('Manager') ||
          line.contains('Developer') ||
          line.contains('Designer') ||
          line.contains('Analyst') ||
          line.contains('Specialist');

      if (isJobTitle &&
          !line.contains('•') &&
          !line.contains('-') &&
          line.length < 100) {
        // Save previous job
        if (currentJob != null) {
          currentJob['responsibilities'] = responsibilities;
          currentJob['projects'] = projects;
          workExperience.add(currentJob);
        }

        // Start new job
        currentJob = {
          'role': line,
          'company': '',
          'location': '',
          'start': '',
          'end': '',
          'duration': '',
          'currentlyWorking': false,
          'teamSize': '',
          'tools': '',
        };
        responsibilities = [];
        projects = [];

        // Next line might be company | location
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.contains('|')) {
            final parts = nextLine.split('|');
            currentJob['company'] = parts[0].trim();
            if (parts.length > 1) {
              currentJob['location'] = parts[1].trim();
            }
          } else {
            currentJob['company'] = nextLine;
          }
        }

        // Line after might be duration
        if (i + 2 < lines.length) {
          final durationLine = lines[i + 2].trim();
          if (RegExp(r'\d{4}').hasMatch(durationLine) ||
              durationLine.toLowerCase().contains('present') ||
              durationLine.toLowerCase().contains('current')) {
            currentJob['duration'] = durationLine;
            currentJob['currentlyWorking'] =
                durationLine.toLowerCase().contains('present') ||
                durationLine.toLowerCase().contains('current');
          }
        }
      } else if (currentJob != null) {
        // This is a responsibility or project detail
        if (line.startsWith('•') ||
            line.startsWith('-') ||
            line.startsWith('*')) {
          responsibilities.add(line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''));
        } else if (!line.contains('|') && !RegExp(r'\d{4}').hasMatch(line)) {
          // Continuation of previous responsibility or additional detail
          if (responsibilities.isNotEmpty) {
            responsibilities[responsibilities.length - 1] += ' $line';
          } else {
            responsibilities.add(line);
          }
        }
      }
    }

    // Save last job
    if (currentJob != null) {
      currentJob['responsibilities'] = responsibilities;
      currentJob['projects'] = projects;
      workExperience.add(currentJob);
    }

    return workExperience;
  }

  /// Extract education with full details
  List<Map<String, dynamic>> _extractEducation(
    String text,
    Map<String, String> sections,
  ) {
    final education = <Map<String, dynamic>>[];

    final eduText = sections['EDUCATION'] ?? '';
    if (eduText.isEmpty) return education;

    final lines = eduText.split('\n');
    Map<String, String>? currentEdu;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if this is a degree line
      final isDegree =
          line.contains('degree') ||
          line.contains('Degree') ||
          line.contains('Bachelor') ||
          line.contains('Master') ||
          line.contains('PhD') ||
          line.contains('Diploma') ||
          line.contains('Certificate');

      if (isDegree) {
        // Save previous education
        if (currentEdu != null) {
          education.add(currentEdu);
        }

        currentEdu = {'degree': line, 'school': '', 'start': '', 'end': ''};

        // Next line is usually school
        if (i + 1 < lines.length) {
          final schoolLine = lines[i + 1].trim();
          if (!RegExp(r'\d{4}').hasMatch(schoolLine)) {
            currentEdu['school'] = schoolLine;
          }
        }

        // Look for year/date
        if (i + 2 < lines.length) {
          final yearLine = lines[i + 2].trim();
          final yearMatch = RegExp(
            r'(\d{4})\s*-?\s*(\d{4})?',
          ).firstMatch(yearLine);
          if (yearMatch != null) {
            currentEdu['start'] = yearMatch.group(1) ?? '';
            currentEdu['end'] = yearMatch.group(2) ?? yearMatch.group(1) ?? '';
          }
        }
      }
    }

    // Save last education
    if (currentEdu != null) {
      education.add(currentEdu);
    }

    return education;
  }

  // Keep existing methods for backward compatibility
  Future<String> suggestImprovements(String currentText) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'Consider adding quantifiable achievements and action verbs.';
  }

  Future<Map<String, dynamic>> enhanceSection(
    String sectionName,
    String currentContent,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'enhanced': currentContent,
      'suggestions': ['Add metrics', 'Use action verbs'],
    };
  }

  Future<List<String>> suggestSkills(String jobTitle) async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Communication', 'Problem Solving', 'Leadership'];
  }

  Future<String> generateCoverLetter(Map<String, dynamic> resumeData) async {
    await Future.delayed(const Duration(seconds: 3));
    final name = resumeData['name'] ?? 'Applicant';
    return '''Dear Hiring Manager,

I am writing to express my interest in the position at your company. With my background and skills, I believe I would be a valuable addition to your team.

Best regards,
$name''';
  }

  Map<String, dynamic> analyzeTone(String text) {
    return {
      'score': 0.8,
      'suggestions': ['Good professional tone'],
    };
  }

  List<String> extractKeywords(String jobDescription) {
    final words = jobDescription.split(RegExp(r'\s+'));
    return words.where((w) => w.length > 5).take(10).toList();
  }

  double calculateMatch(Map<String, dynamic> resume, String jobDescription) {
    return 0.75;
  }

  String formatSection(String sectionName, String content) {
    return '## $sectionName\n\n$content';
  }

  bool validateContent(String content) {
    return content.trim().isNotEmpty && content.length > 10;
  }

  Map<String, dynamic> getStatistics(String text) {
    return {
      'wordCount': text.split(RegExp(r'\s+')).length,
      'characterCount': text.length,
    };
  }
}
