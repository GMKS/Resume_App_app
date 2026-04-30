import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/resume_model.dart';
import '../flexcolor_sidebar_template_support.dart';

class FlexColorSidebarTemplatePreview extends StatelessWidget {
  const FlexColorSidebarTemplatePreview({
    super.key,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  Color get _accent => templateColor ?? accentColor;
  Color get _accentSoft => _accent.withValues(alpha: 0.12);
  Color get _accentBorder => _accent.withValues(alpha: 0.28);
  Color get _canvas => const Color(0xFFF1F5F9);
  Color get _panel => Colors.white;
  Color get _mist => const Color(0xFFD8E1EA);
  Color get _ink => const Color(0xFF172033);
  Color get _muted => const Color(0xFF6B7280);

  String get _name => FlexColorSidebarTemplateSupport.displayName(resume);

  String get _title => FlexColorSidebarTemplateSupport.displayTitle(resume);

  Uint8List? get _photoBytes =>
      FlexColorSidebarTemplateSupport.photoBytes(resume?.personalInfo);

  String get _initials => FlexColorSidebarTemplateSupport.initials(_name);

  List<String> get _contacts => FlexColorSidebarTemplateSupport.contactLines(
        resume?.personalInfo,
        maxItems: 6,
      );

  List<String> get _languageLines =>
      FlexColorSidebarTemplateSupport.languageLines(
        resume?.languages ?? const <Language>[],
        maxItems: 2,
      );

  List<String> get _summaryLines =>
      FlexColorSidebarTemplateSupport.summaryLines(
        resume?.objective,
        maxItems: 2,
      );

  FlexColorSidebarExperienceEntry get _experience =>
      FlexColorSidebarTemplateSupport.experienceEntries(
        resume?.experience ?? const <Experience>[],
        maxItems: 1,
        maxDetailLines: 1,
      ).first;

  List<String> get _skills => FlexColorSidebarTemplateSupport.skillNames(
        resume?.skills ?? const <Skill>[],
        maxItems: 4,
      );

  FlexColorSidebarProjectEntry get _project =>
      FlexColorSidebarTemplateSupport.projectEntries(
        resume?.projects ?? const <Project>[],
        maxItems: 1,
        maxDetailLines: 1,
      ).first;

  FlexColorSidebarCertificationEntry get _certification =>
      FlexColorSidebarTemplateSupport.certificationEntries(
        resume?.certifications ?? const <Certification>[],
        maxItems: 1,
      ).first;

  FlexColorSidebarEducationEntry get _education =>
      FlexColorSidebarTemplateSupport.educationEntries(
        resume?.education ?? const <Education>[],
        maxItems: 1,
      ).first;

  Widget _text(
    String text, {
    required double size,
    Color? color,
    FontWeight weight = FontWeight.normal,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
  }) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        color: color ?? _muted,
        fontWeight: weight,
        height: 1.12,
      ),
    );
  }

  Widget _sectionTag(String label) {
    return Row(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.3),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _accentBorder),
            ),
            child: _text(
              label,
              size: 2.7,
              color: _accent,
              weight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 2.5),
        Expanded(child: Container(height: 0.7, color: _mist)),
      ],
    );
  }

  Widget _sideCard(String label, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(3.5, 3.5, 3.5, 2.5),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: _text(
              label,
              size: 2.7,
              color: _accent,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          ...children,
        ],
      ),
    );
  }

  Widget _experienceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2.5),
      padding: const EdgeInsets.fromLTRB(3.5, 3.5, 3.5, 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 1.2,
            margin: const EdgeInsets.only(bottom: 2.5),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          _text(_experience.title,
              size: 4.1, color: _ink, weight: FontWeight.w700),
          _text(_experience.companyLine,
              size: 3.0, color: _accent, weight: FontWeight.w600),
          _text(
            _experience.detailLines.isNotEmpty
                ? _experience.detailLines.first
                : 'Delivered product updates and maintained core features.',
            size: 2.9,
            color: Colors.grey.shade600,
            maxLines: 2,
            align: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String label, Color fill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _mist),
      ),
      child: _text(label, size: 3.0, color: _ink, weight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipBackgrounds = [
      _accentSoft,
      const Color(0xFFE2E8F0),
      const Color(0xFFEEF2F7),
    ];

    return Container(
      color: _canvas,
      padding: const EdgeInsets.all(5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 12,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(6),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 22, 4, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _accentSoft,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _accentBorder),
                                ),
                                child: _photoBytes == null
                                    ? Center(
                                        child: _text(
                                          _initials,
                                          size: 4.9,
                                          color: _accent,
                                          weight: FontWeight.bold,
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(1.5),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          child: Image.memory(
                                            _photoBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 3),
                              _sideCard(
                                'CONTACT',
                                _contacts
                                    .map(
                                      (line) => _text(
                                        line,
                                        size: 2.85,
                                        color: Colors.grey.shade700,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              _sideCard(
                                'LANG',
                                _languageLines
                                    .map(
                                      (line) => _text(
                                        line,
                                        size: 2.75,
                                        color: Colors.grey.shade700,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTag('PROFILE'),
                              const SizedBox(height: 2),
                              ..._summaryLines.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: _text(
                                    '> $line',
                                    size: 3.0,
                                    color: Colors.grey.shade700,
                                    maxLines: 2,
                                    align: TextAlign.justify,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              _sectionTag('EXPERIENCE'),
                              const SizedBox(height: 2),
                              _experienceCard(),
                              const SizedBox(height: 2),
                              _sectionTag('SKILL GRID'),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 3,
                                runSpacing: 3,
                                children: _skills
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _skillChip(
                                        entry.value,
                                        chipBackgrounds[
                                            entry.key % chipBackgrounds.length],
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 2),
                              _sectionTag('PROJECTS'),
                              const SizedBox(height: 2),
                              _text(
                                _project.title,
                                size: 3.0,
                                color: _ink,
                                weight: FontWeight.w600,
                              ),
                              const SizedBox(height: 2),
                              _sectionTag('CERTIFICATIONS'),
                              const SizedBox(height: 2),
                              _text(
                                _certification.metaLine.isNotEmpty
                                    ? '${_certification.name} · ${_certification.metaLine}'
                                    : _certification.name,
                                size: 3.0,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 2),
                              _sectionTag('EDUCATION'),
                              const SizedBox(height: 2),
                              _text(
                                _education.degreeLine,
                                size: 4.0,
                                color: _ink,
                                weight: FontWeight.w700,
                              ),
                              _text(
                                _education.metaLine.isNotEmpty
                                    ? '${_education.institutionLine} · ${_education.metaLine}'
                                    : _education.institutionLine,
                                size: 3.0,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 8,
            top: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _mist),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x110F172A),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _text(
                          _name.toUpperCase(),
                          size: 6.9,
                          color: _ink,
                          weight: FontWeight.bold,
                        ),
                        const SizedBox(height: 1),
                        _text(
                          _title,
                          size: 3.8,
                          color: Colors.grey.shade600,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
