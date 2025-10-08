import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';

class ClassicResumePreview extends StatelessWidget {
  final SavedResume resume;
  const ClassicResumePreview({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final d = resume.data;

    String name = (d['name'] ?? '').toString().trim();
    String email = (d['email'] ?? '').toString().trim();
    String phone = (d['phone'] ?? '').toString().trim();
    String summary = (d['summary'] ?? '').toString().trim();
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

    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Classic Preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + contact
            Text(
              name.isEmpty ? resume.title : name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (email.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14),
                      const SizedBox(width: 4),
                      Text(email),
                    ],
                  ),
                if (phone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14),
                      const SizedBox(width: 4),
                      Text(phone),
                    ],
                  ),
              ],
            ),

            if (summary.isNotEmpty) ...[
              sectionTitle('Professional Summary'),
              Text(summary),
            ],

            if (skills.isNotEmpty) ...[
              sectionTitle('Skills'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((s) => Chip(label: Text(s))).toList(),
              ),
            ],

            if (work.isNotEmpty) ...[
              sectionTitle('Work Experience'),
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
                          fontWeight: FontWeight.w600,
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
                        Text(desc),
                      ],
                      if (ach.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...ach.map(
                          (a) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(a)),
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
              sectionTitle('Education'),
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
                          fontWeight: FontWeight.w600,
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
                        Text(desc),
                      ],
                    ],
                  ),
                );
              }),
            ],

            if (certs.isNotEmpty) ...[
              sectionTitle('Certifications'),
              ...certs.map(
                (c) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(c)),
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
