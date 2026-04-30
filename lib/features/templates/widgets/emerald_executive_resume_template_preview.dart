import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';

class EmeraldExecutiveResumeTemplatePreview extends StatelessWidget {
  const EmeraldExecutiveResumeTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  static final RegExp _linkPattern = RegExp(
    r'((?:https?:\/\/|www\.)[^\s,;|]+|(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:\/[^\s,;|]+)?)',
    caseSensitive: false,
  );
  static final RegExp _leadingBulletPattern = RegExp(
    r'^[-•*▪■□✪✦★☆➣►→➜➤◦○]+\s*',
  );
  static final RegExp _inlineBulletSeparatorPattern = RegExp(
    r'\s+[•▪■□✪✦★☆➣►→➜➤◦○]+\s+',
  );

  Color get _accent => templateColor ?? accentColor;
  Color get _deepAccent => Color.lerp(_accent, Colors.black, 0.28)!;
  Color get _ink => const Color(0xFF18261E);
  Color get _muted => const Color(0xFF65756E);
  Color get _rule => Color.lerp(_accent, Colors.white, 0.55)!;

  Uint8List? get _photoBytes {
    final value = resume?.personalInfo.profileImage?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value.split(',').last);
    } catch (_) {
      return null;
    }
  }

  String get _name {
    final value = resume?.personalInfo.fullName.trim() ?? '';
    return value.isNotEmpty ? value : 'GMK Seenai';
  }

  String get _title {
    final value = resume?.personalInfo.jobTitle?.trim() ?? '';
    return value.isNotEmpty ? value : 'Senior Manager';
  }

  String get _initials {
    final parts = _name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'GS';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  List<_EmeraldContactItem> get _contacts {
    final info = resume?.personalInfo;
    final items = <_EmeraldContactItem>[];

    void addItem(String icon, String value, {bool compact = false}) {
      final text = compact ? _compactUrl(value) : value.trim();
      if (text.isEmpty || items.any((item) => item.text == text)) {
        return;
      }
      items.add(_EmeraldContactItem(icon: icon, text: text));
    }

    addItem('phone', info?.phone ?? '');
    addItem('email', info?.email ?? '');
    addItem('location', info?.address ?? '');
    addItem('linkedin', info?.linkedIn ?? '', compact: true);
    addItem('website', info?.website ?? '', compact: true);
    addItem('website', info?.github ?? '', compact: true);

    if (items.isNotEmpty) {
      return items.take(6).toList(growable: false);
    }

    return const [
      _EmeraldContactItem(icon: 'phone', text: '+91 99999 22226'),
      _EmeraldContactItem(icon: 'email', text: 'seenai@example.com'),
      _EmeraldContactItem(icon: 'location', text: 'Hyderabad, India'),
      _EmeraldContactItem(icon: 'linkedin', text: 'linkedin.com/in/seenai'),
    ];
  }

  List<String> get _summaryLines {
    final raw = resume?.objective?.trim() ?? '';
    if (raw.isEmpty) {
      return const [
        'Over 13 years in software testing and development, with strong experience across automation, debugging, and quality delivery.',
        'Programming, API validation, and problem solving across Selenium, Java, and modern test frameworks.',
        'Skilled at working with developers and stakeholders to keep releases accurate, reliable, and well documented.',
      ];
    }

    final lines = _splitLines(raw, maxItems: null);
    return lines.isNotEmpty ? lines : [raw];
  }

  List<_EmeraldPreviewExperience> get _experiences {
    final values = resume?.experience ?? const <Experience>[];
    if (values.isEmpty) {
      return const [
        _EmeraldPreviewExperience(
          title: 'Automation Lead',
          company: 'Tata Consultancy Services Limited',
          dateRange: 'Feb 2019 - Mar 2021',
          details: [
            'Led the automation team in developing and executing test automation scripts.',
            'Managed test scheduling, defect tracking, and cross-team communication.',
          ],
        ),
        _EmeraldPreviewExperience(
          title: 'Senior Software Engineer',
          company: 'UST Global Pvt Ltd',
          dateRange: 'Feb 2017 - Mar 2019',
          details: [
            'Developed and maintained automation suites using Selenium and Core Java.',
          ],
        ),
      ];
    }

    return values.take(2).map((experience) {
      final details = <String>[];
      details.addAll(
        experience.achievements
            .map(_cleanListMarker)
            .where((line) => line.isNotEmpty)
            .take(2),
      );
      if (details.isEmpty && experience.description.trim().isNotEmpty) {
        details.addAll(_splitLines(experience.description, maxItems: 2));
      }

      return _EmeraldPreviewExperience(
        title: experience.position.trim().isNotEmpty
            ? experience.position.trim()
            : 'Role',
        company: experience.company.trim().isNotEmpty
            ? experience.company.trim()
            : 'Company',
        dateRange: _dateRange(
          experience.startDate,
          experience.endDate,
          ongoing: experience.isCurrentlyWorking,
        ),
        details: details,
      );
    }).toList(growable: false);
  }

  List<_EmeraldPreviewEducation> get _educationItems {
    final values = resume?.education ?? const <Education>[];
    if (values.isEmpty) {
      return const [
        _EmeraldPreviewEducation(
          institution: 'Holy Jesus and Mary PU College',
          degree: 'MCA',
          supportingLine: 'Computer Applications',
          dateRange: '2006 - 2009',
        ),
      ];
    }

    return values.take(2).map((education) {
      final degreeLine = [
        education.degree.trim(),
        education.fieldOfStudy.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      final supporting = [
        education.grade?.trim() ?? '',
        education.description?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' • ');

      return _EmeraldPreviewEducation(
        institution: education.institution.trim().isNotEmpty
            ? education.institution.trim()
            : 'Institution',
        degree: degreeLine.isNotEmpty ? degreeLine : 'Education',
        supportingLine: supporting,
        dateRange: _dateRange(
          education.startDate,
          education.endDate,
          ongoing: education.isCurrentlyStudying,
          monthYear: false,
        ),
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        _name.toUpperCase(),
                        size: 7.3,
                        color: _accent,
                        weight: FontWeight.w800,
                        maxLines: 1,
                      ),
                      _text(
                        _title,
                        size: 3.7,
                        color: _muted,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Container(height: 0.55, color: Colors.grey.shade300),
                      const SizedBox(height: 2.5),
                      ..._buildContactRows(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 4.2, color: _accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('SUMMARY'),
                    ..._summaryLines.map(_summaryLine),
                    const SizedBox(height: 4),
                    _sectionHeader('PROFESSIONAL EXPERIENCE'),
                    ..._experiences.map(_experienceBlock),
                    const SizedBox(height: 4),
                    _sectionHeader('EDUCATION'),
                    ..._educationItems.map(_educationBlock),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final photoBytes = _photoBytes;
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accent, width: 1.4),
        color: Color.lerp(_accent, Colors.white, 0.9),
      ),
      child: ClipOval(
        child: photoBytes != null
            ? Image.memory(photoBytes, fit: BoxFit.cover)
            : Container(
                color: _deepAccent,
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildContactRows() {
    final rows = <Widget>[];
    final contacts = _contacts;
    for (var index = 0; index < contacts.length; index += 2) {
      final pair = contacts.skip(index).take(2).toList(growable: false);
      rows.add(
        Padding(
          padding:
              EdgeInsets.only(bottom: index + 2 < contacts.length ? 1.4 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _contactItem(pair.first)),
              if (pair.length == 2) ...[
                const SizedBox(width: 4),
                Expanded(child: _contactItem(pair.last)),
              ],
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _contactItem(_EmeraldContactItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.2),
          child: Container(
            width: 4.2,
            height: 4.2,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 2.2),
        Expanded(
          child: _text(
            item.text,
            size: 3.0,
            color: _muted,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            title,
            size: 4.3,
            color: _accent,
            weight: FontWeight.w800,
            maxLines: 1,
          ),
          const SizedBox(height: 1.4),
          SizedBox(
            height: 5,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(height: 0.95, color: _rule),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(width: 1.55, color: _accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 2.8,
              height: 2.8,
              decoration: BoxDecoration(
                color: _deepAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 3.2),
          Expanded(
            child: _text(
              line,
              size: 3.25,
              color: _ink,
              align: TextAlign.justify,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceBlock(_EmeraldPreviewExperience experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  experience.title,
                  size: 3.65,
                  color: _deepAccent,
                  weight: FontWeight.w700,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 55),
                child: _text(
                  experience.dateRange,
                  size: 2.7,
                  color: _muted,
                  align: TextAlign.right,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          _text(
            experience.company,
            size: 3.0,
            color: _accent,
            weight: FontWeight.w600,
            maxLines: 2,
          ),
          const SizedBox(height: 0.8),
          ...experience.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 1.1),
              child: _text(
                detail,
                size: 2.85,
                color: _muted,
                align: TextAlign.justify,
                maxLines: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationBlock(_EmeraldPreviewEducation education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _text(
                  education.institution,
                  size: 3.5,
                  color: _deepAccent,
                  weight: FontWeight.w700,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 50),
                child: _text(
                  education.dateRange,
                  size: 2.7,
                  color: _muted,
                  align: TextAlign.right,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          _text(
            education.degree,
            size: 2.95,
            color: _accent,
            weight: FontWeight.w600,
            maxLines: 2,
          ),
          if (education.supportingLine.isNotEmpty)
            _text(
              education.supportingLine,
              size: 2.75,
              color: _muted,
              align: TextAlign.justify,
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  String _dateRange(
    DateTime start,
    DateTime? end, {
    required bool ongoing,
    bool monthYear = true,
  }) {
    final format = DateFormat(monthYear ? 'MMM yyyy' : 'yyyy');
    final startLabel = format.format(start);
    final endLabel = ongoing
        ? 'Present'
        : (end != null ? format.format(end) : format.format(start));
    return '$startLabel - $endLabel';
  }

  List<String> _splitLines(String text, {int? maxItems}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final parts = raw
        .split(RegExp(r'\n+'))
        .expand(_splitInlineBulletSegments)
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length > 1) {
      if (maxItems == null) {
        return parts;
      }
      return parts.take(maxItems).toList(growable: false);
    }

    final sentenceParts = raw
        .split(RegExp(r'(?<=[.!?])\s+'))
        .expand(_splitInlineBulletSegments)
        .map(_cleanListMarker)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (maxItems == null) {
      return sentenceParts;
    }
    return sentenceParts.take(maxItems).toList(growable: false);
  }

  String _cleanListMarker(String value) {
    return value.trim().replaceFirst(_leadingBulletPattern, '');
  }

  Iterable<String> _splitInlineBulletSegments(String value) sync* {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    for (final segment in trimmed.split(_inlineBulletSeparatorPattern)) {
      final normalized = segment.trim();
      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
  }

  String _compactUrl(String value) {
    var compact = value.trim();
    if (compact.isEmpty) {
      return '';
    }

    final match = _linkPattern.firstMatch(compact);
    compact = match?.group(0) ?? compact;
    compact =
        compact.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    compact = compact.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    return compact.replaceAll(RegExp(r'/$'), '');
  }

  Widget _text(
    String text, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    TextAlign align = TextAlign.left,
    int maxLines = 1,
  }) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines <= 0 ? null : maxLines,
      overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.16,
      ),
    );
  }
}

class _EmeraldContactItem {
  const _EmeraldContactItem({required this.icon, required this.text});

  final String icon;
  final String text;
}

class _EmeraldPreviewExperience {
  const _EmeraldPreviewExperience({
    required this.title,
    required this.company,
    required this.dateRange,
    required this.details,
  });

  final String title;
  final String company;
  final String dateRange;
  final List<String> details;
}

class _EmeraldPreviewEducation {
  const _EmeraldPreviewEducation({
    required this.institution,
    required this.degree,
    required this.supportingLine,
    required this.dateRange,
  });

  final String institution;
  final String degree;
  final String supportingLine;
  final String dateRange;
}
