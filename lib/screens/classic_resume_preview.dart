import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../models/branding.dart';

class ClassicResumePreview extends StatelessWidget {
  final SavedResume resume;
  const ClassicResumePreview({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final d = resume.data;

    String name = (d['name'] ?? '').toString().trim();
    String title = (d['title'] ?? d['professionalTitle'] ?? '')
        .toString()
        .trim();
    String email = (d['email'] ?? '').toString().trim();
    String phone = (d['phone'] ?? '').toString().trim();
    String linkedin = (d['linkedIn'] ?? d['linkedin'] ?? '').toString().trim();
    String portfolio = (d['portfolio'] ?? d['website'] ?? '').toString().trim();
    String summary = (d['summary'] ?? '').toString().trim();
    // Strengths can be a comma/newline separated string
    final strengthsRaw = (d['strengths'] ?? '').toString();
    final strengths = strengthsRaw
        .split(RegExp('[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final skillsCsv = (d['skills'] ?? '').toString();
    final skills = skillsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final certificationsCsv = (d['certifications'] ?? '').toString();
    final certs = certificationsCsv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<Map<String, dynamic>> work = [];
    if ((d['workExperiences'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['workExperiences']) as List<dynamic>;
        work = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    List<Map<String, dynamic>> edu = [];
    if ((d['educations'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['educations']) as List<dynamic>;
        edu = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    Widget sectionHeader(String t) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            t.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );

    String fmtRange(String? startIso, String? endIso) {
      String fmt(String? iso) {
        if (iso == null || iso.isEmpty) return '';
        try {
          final dt = DateTime.tryParse(iso);
          if (dt == null) return '';
          final m = dt.month.toString().padLeft(2, '0');
          return '${dt.year}-$m';
        } catch (_) {
          return '';
        }
      }

      final s = fmt(startIso);
      final e = fmt(endIso);
      if (s.isEmpty && e.isEmpty) return '';
      return e.isEmpty ? '$s - Present' : '$s - $e';
    }

    // Branding-driven accent color for subtitle and accents
    Color accent = const Color(0xFF1976D2);
    try {
      final brandingJson = d['branding'];
      if (brandingJson != null && brandingJson.toString().isNotEmpty) {
        final theme = BrandingTheme.fromJson(
          jsonDecode(brandingJson.toString()) as Map<String, dynamic>,
        );
        final h = theme.accentColor.replaceAll('#', '');
        if (h.length == 6) {
          final r = int.parse(h.substring(0, 2), radix: 16);
          final g = int.parse(h.substring(2, 4), radix: 16);
          final b = int.parse(h.substring(4, 6), radix: 16);
          accent = Color.fromARGB(0xFF, r, g, b);
        }
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('Classic Preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + contact
            Text(
              name.isEmpty ? resume.title : name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  title,
                  style: TextStyle(color: accent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (phone.isNotEmpty) Text(phone),
                if (phone.isNotEmpty && email.isNotEmpty) const Text('•'),
                if (email.isNotEmpty) Text(email),
                if ((email.isNotEmpty || phone.isNotEmpty) &&
                    (portfolio.isNotEmpty || linkedin.isNotEmpty))
                  const Text('•'),
                if (portfolio.isNotEmpty) Text(portfolio),
                if (portfolio.isNotEmpty && linkedin.isNotEmpty)
                  const Text('•'),
                if (linkedin.isNotEmpty) Text(linkedin),
              ],
            ),

            if (summary.isNotEmpty) ...[
              sectionHeader('Summary'),
              const SizedBox(height: 6),
              const SizedBox(height: 2),
              Text(summary, style: const TextStyle(height: 1.35)),
            ],

            if (strengths.isNotEmpty) ...[
              sectionHeader('Strengths'),
              const SizedBox(height: 6),
              ...strengths.map(
                (s) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(s, style: const TextStyle(height: 1.3)),
                    ),
                  ],
                ),
              ),
            ],

            if (skills.isNotEmpty) ...[
              sectionHeader('Skills'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (work.isNotEmpty) ...[
              sectionHeader('Experience'),
              const SizedBox(height: 6),
              ...work.map((w) {
                final title = (w['jobTitle'] ?? '').toString();
                final company = (w['company'] ?? '').toString();
                final loc = (w['location'] ?? '').toString();
                final desc = (w['description'] ?? '').toString();
                final start = (w['startDate'] ?? '').toString();
                final end = (w['endDate'] ?? '').toString();
                final dr = fmtRange(start, end);
                final ach = (w['achievements'] is List)
                    ? List.from(w['achievements'])
                          .map((e) => e.toString())
                          .where((e) => e.trim().isNotEmpty)
                          .toList()
                    : const <String>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (company.isNotEmpty) Text(company),
                      Row(
                        children: [
                          if (dr.isNotEmpty) Text(dr),
                          if (dr.isNotEmpty && loc.isNotEmpty)
                            const SizedBox(width: 12),
                          if (loc.isNotEmpty) Text(loc),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(desc, style: const TextStyle(height: 1.35)),
                      ],
                      if (ach.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...ach.map(
                          (a) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  a,
                                  style: const TextStyle(height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],

            if (edu.isNotEmpty) ...[
              sectionHeader('Education'),
              const SizedBox(height: 6),
              ...edu.map((e) {
                final degree = (e['degree'] ?? '').toString();
                final inst = (e['institution'] ?? '').toString();
                final loc = (e['location'] ?? '').toString();
                final gpa = (e['gpa'] ?? '').toString();
                final desc = (e['description'] ?? '').toString();
                final start = (e['startDate'] ?? '').toString();
                final end = (e['endDate'] ?? '').toString();
                final dr = fmtRange(start, end);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        degree,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (inst.isNotEmpty) Text(inst),
                      Row(
                        children: [
                          if (dr.isNotEmpty) Text(dr),
                          if (dr.isNotEmpty && loc.isNotEmpty)
                            const SizedBox(width: 12),
                          if (loc.isNotEmpty) Text(loc),
                        ],
                      ),
                      if (gpa.isNotEmpty) Text('GPA: $gpa'),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(desc, style: const TextStyle(height: 1.35)),
                      ],
                    ],
                  ),
                );
              }),
            ],

            if (certs.isNotEmpty) ...[
              sectionHeader('Certifications'),
              const SizedBox(height: 6),
              ...certs.map(
                (c) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(c, style: const TextStyle(height: 1.3)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
