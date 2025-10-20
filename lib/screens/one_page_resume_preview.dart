import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';

class OnePageResumePreview extends StatelessWidget {
  final SavedResume resume;
  const OnePageResumePreview({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final d = resume.data;
    final name = (d['name'] ?? '').toString().trim();
    final title = (d['title'] ?? '').toString().trim();
    final email = (d['email'] ?? '').toString().trim();
    final phone = (d['phone'] ?? '').toString().trim();
    final linkedIn = (d['linkedIn'] ?? d['linkedin'] ?? '').toString().trim();
    final portfolio = (d['portfolio'] ?? '').toString().trim();
    final summary = (d['summary'] ?? '').toString().trim();
    final photoB64 = (d['profilePhotoBase64'] ?? '').toString();
    final skills = (d['coreSkills'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final awards = (d['awards'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<Map<String, dynamic>> work = [];
    if ((d['workExperiencesJson'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['workExperiencesJson']) as List<dynamic>;
        work = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    List<Map<String, dynamic>> edu = [];
    if ((d['educationsJson'] ?? '').toString().isNotEmpty) {
      try {
        final list = jsonDecode(d['educationsJson']) as List<dynamic>;
        edu = list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } catch (_) {}
    }

    String range(String? s, String? e) {
      String fmt(String? iso) {
        if (iso == null || iso.isEmpty) return '';
        try {
          final dt = DateTime.tryParse(iso);
          if (dt == null) return '';
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        } catch (_) {
          return '';
        }
      }

      final a = fmt(s);
      final b = fmt(e);
      if (a.isEmpty && b.isEmpty) return '';
      return b.isEmpty ? '$a - Present' : '$a - $b';
    }

    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('One Page Preview')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 595, // A4 width in logical pixels
            maxHeight: 842, // A4 height in logical pixels
          ),
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const railW = 220.0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Sidebar
                        Container(
                          width: railW,
                          color: Colors.grey.shade100,
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo
                              if (photoB64.isNotEmpty)
                                CircleAvatar(
                                  radius: 38,
                                  backgroundImage: MemoryImage(
                                    base64Decode(
                                      photoB64.contains(',')
                                          ? photoB64.split(',').last
                                          : photoB64,
                                    ),
                                  ),
                                ),
                              section('CONTACT'),
                              if (phone.isNotEmpty)
                                _iconRow(Icons.phone, phone),
                              if (email.isNotEmpty)
                                _iconRow(Icons.email, email),
                              if (linkedIn.isNotEmpty)
                                _iconRow(Icons.link, linkedIn),
                              if (portfolio.isNotEmpty)
                                _iconRow(Icons.language, portfolio),

                              if (edu.isNotEmpty) ...[
                                section('EDUCATION'),
                                ...edu.map((e) {
                                  final degree = (e['degree'] ?? '').toString();
                                  final inst = (e['institution'] ?? '')
                                      .toString();
                                  final s = (e['startDate'] ?? '').toString();
                                  final n = (e['endDate'] ?? '').toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          degree,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (inst.isNotEmpty) Text(inst),
                                        Text(range(s, n)),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              if (skills.isNotEmpty) ...[
                                section('SKILLS'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: skills
                                      .map((s) => Chip(label: Text(s)))
                                      .toList(),
                                ),
                              ],

                              if (awards.isNotEmpty) ...[
                                section('AWARDS'),
                                ...awards.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('• $a'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Right Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top banner with name/title
                              Container(
                                width: double.infinity,
                                color: Colors.blue.shade50,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  18,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty
                                          ? resume.title
                                          : name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    if (title.isNotEmpty)
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (summary.isNotEmpty) ...[
                                      Text(
                                        'PROFILE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(summary),
                                      const SizedBox(height: 16),
                                    ],
                                    if (work.isNotEmpty) ...[
                                      Text(
                                        'PROFESSIONAL EXPERIENCE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...work.map((w) {
                                        final role = (w['jobTitle'] ?? '')
                                            .toString();
                                        final company = (w['company'] ?? '')
                                            .toString();
                                        final city = (w['location'] ?? '')
                                            .toString();
                                        final start = (w['startDate'] ?? '')
                                            .toString();
                                        final end = (w['endDate'] ?? '')
                                            .toString();
                                        final desc = (w['description'] ?? '')
                                            .toString();
                                        final bullets =
                                            (w['achievements'] is List)
                                            ? List.from(w['achievements'])
                                                  .map((e) => e.toString())
                                                  .where(
                                                    (s) => s.trim().isNotEmpty,
                                                  )
                                                  .toList()
                                            : <String>[];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                role,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                [
                                                      if (company.isNotEmpty)
                                                        company,
                                                      if (city.isNotEmpty) city,
                                                      if (range(
                                                        start,
                                                        end,
                                                      ).isNotEmpty)
                                                        range(start, end),
                                                    ]
                                                    .where((e) => e.isNotEmpty)
                                                    .join(' • '),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              if (desc.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(desc),
                                              ],
                                              if (bullets.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                ...bullets.map(
                                                  (b) => Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text('• '),
                                                      Expanded(child: Text(b)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconRow(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(i, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(t)),
      ],
    ),
  );
}
