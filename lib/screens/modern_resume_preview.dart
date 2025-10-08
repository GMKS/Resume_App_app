import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/saved_resume.dart';

class ModernResumePreview extends StatelessWidget {
  final SavedResume resume;
  const ModernResumePreview({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final data = resume.data;
    final info = Map<String, dynamic>.from(data['personalInfo'] ?? {});
    final name = (info['name'] ?? '').toString();
    final email = (info['email'] ?? '').toString();
    final phone = (info['phone'] ?? '').toString();
    final location = (info['location'] ?? '').toString();
    final linkedIn = (info['linkedin'] ?? '').toString();
    final photoB64 = (info['profilePhotoBase64'] ?? '').toString();
    final summary = (data['summary'] ?? '').toString();
    final skills = _extractSkills(data);
    final certifications = (data['certifications'] ?? '').toString();
    final achievements = (data['achievements'] ?? '').toString();
    final hobbies = (data['hobbies'] ?? '').toString();
    final work = List<Map<String, dynamic>>.from(
      data['workExperience'] ?? const [],
    );
    final education = List<Map<String, dynamic>>.from(
      data['education'] ?? const [],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Modern Preview')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  final photo = _buildPhoto(photoB64);
                  final header = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photo != null) ...[
                            photo,
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty
                                      ? resume.title
                                      : name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (summary.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _sectionTitle('PROFESSIONAL SUMMARY'),
                                  const SizedBox(height: 6),
                                  Text(
                                    summary,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (email.isNotEmpty)
                            _contactChip(Icons.email_outlined, email),
                          if (phone.isNotEmpty)
                            _contactChip(Icons.phone_outlined, phone),
                          if (location.isNotEmpty)
                            _contactChip(Icons.location_on_outlined, location),
                          if (linkedIn.isNotEmpty)
                            _contactChip(Icons.link, linkedIn),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  );

                  Widget buildLeftColumn() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('WORK EXPERIENCE'),
                      for (final w in work) ...[
                        _jobBlock(
                          title: (w['role'] ?? '').toString(),
                          company: (w['company'] ?? '').toString(),
                          dateRange: _dateRange(w['start'], w['end']),
                          location: (w['location'] ?? '').toString(),
                          bullets: const [],
                        ),
                      ],
                    ],
                  );

                  Widget buildRightColumn() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('EDUCATION'),
                      for (final e in education) ...[
                        _eduBlock(
                          degree: (e['degree'] ?? '').toString(),
                          school: (e['school'] ?? '').toString(),
                          dateRange: _dateRange(e['start'], e['end']),
                          location: (e['location'] ?? '').toString(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                      _sectionTitle('SKILLS'),
                      if (skills.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: skills
                                .map((s) => _bulletText(s))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (certifications.isNotEmpty) ...[
                        _sectionTitle('CERTIFICATIONS'),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: certifications
                                .split(',')
                                .map((c) => c.trim())
                                .where((c) => c.isNotEmpty)
                                .map(_bulletText)
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (achievements.isNotEmpty)
                        _sectionTitle('ACHIEVEMENTS'),
                      if (achievements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: achievements
                                .split(',')
                                .map((a) => a.trim())
                                .where((a) => a.isNotEmpty)
                                .map(_bulletText)
                                .toList(),
                          ),
                        ),
                      if (hobbies.isNotEmpty) ...[
                        _sectionTitle('HOBBIES'),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: hobbies
                                .split(',')
                                .map((h) => h.trim())
                                .where((h) => h.isNotEmpty)
                                .map(_bulletText)
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      if (isNarrow)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildLeftColumn(),
                            const SizedBox(height: 16),
                            buildRightColumn(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: buildLeftColumn()),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: buildRightColumn()),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        decoration: TextDecoration.underline,
      ),
    ),
  );

  Widget _jobBlock({
    required String title,
    required String company,
    required String dateRange,
    required String location,
    required List<String> bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (company.isNotEmpty)
            Text(
              company,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          Row(
            children: [
              if (dateRange.isNotEmpty) ...[
                const Icon(Icons.calendar_today, size: 12),
                const SizedBox(width: 6),
                Text(dateRange, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
              ],
              if (location.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined, size: 12),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets.map(_bulletText).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _eduBlock({
    required String degree,
    required String school,
    required String dateRange,
    required String location,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (degree.isNotEmpty)
          Text(
            degree,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        if (school.isNotEmpty)
          Text(
            school,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        Row(
          children: [
            if (dateRange.isNotEmpty) ...[
              const Icon(Icons.calendar_today, size: 12),
              const SizedBox(width: 6),
              Text(dateRange, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
            ],
            if (location.isNotEmpty) ...[
              const Icon(Icons.location_on_outlined, size: 12),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _dateRange(dynamic startIso, dynamic endIso) {
    String fmt(dynamic iso) {
      if (iso == null) return '';
      try {
        final dt = DateTime.tryParse(iso.toString());
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

  // If summary is empty but work exists, you can choose to display first role under name.
  // This is already visually covered by the summary area, but kept for extensibility.

  // Build a circular photo from base64 if present
  Widget? _buildPhoto(String b64) {
    if (b64.isEmpty) return null;
    try {
      // strip possible data url prefix
      final comma = b64.indexOf(',');
      final raw = comma > 0 ? b64.substring(comma + 1) : b64;
      final bytes = base64Decode(raw);
      return CircleAvatar(radius: 36, backgroundImage: MemoryImage(bytes));
    } catch (_) {
      return null;
    }
  }

  // Accept multiple shapes for skills: List<String>, List<Map>, csv fallback
  List<String> _extractSkills(Map<String, dynamic> data) {
    final v = data['skills'];
    if (v is List) {
      if (v.isEmpty) return _skillsFromCsv(data);
      if (v.first is String) {
        return v.cast<String>();
      }
      if (v.first is Map) {
        return v
            .map((e) => (e['label'] ?? e['name'] ?? e.toString()).toString())
            .cast<String>()
            .toList();
      }
      return v.map((e) => e.toString()).cast<String>().toList();
    }
    return _skillsFromCsv(data);
  }

  List<String> _skillsFromCsv(Map<String, dynamic> data) {
    final csv = (data['skillsCsv'] ?? '').toString();
    if (csv.isEmpty) return const [];
    return csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
