import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_resume.dart';
import '../services/share_export_service.dart';
import '../services/premium_service.dart';

class CreativeResumePreview extends StatelessWidget {
  final SavedResume resume;
  final String? templateId;

  const CreativeResumePreview({
    super.key,
    required this.resume,
    this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    final data = resume.data;
    // Top-level plain fields used by Creative form
    final name = (data['name'] ?? data['full_name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final portfolio = (data['portfolio'] ?? '').toString();
    final social = (data['socialLinks'] ?? '').toString();
    final summary = (data['creativeSummary'] ?? '').toString();
    final skillsCsv = (data['skills'] ?? '').toString();
    final tools = (data['tools'] ?? '').toString();
    final languages = (data['languages'] ?? '').toString();
    final hobbies = (data['hobbies'] ?? '').toString();
    final references = (data['references'] ?? '').toString();
    final photoB64 = (data['profilePhotoBase64'] ?? '').toString();

    final work = _parseWork(data['workExperiences']);
    final edus = _parseEducation(data['educations']);

    const accent = Colors.indigo;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Creative Preview'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_outlined),
            onSelected: (v) async {
              if (!await PremiumService.isPremiumWithDialog(context)) return;
              if (v == 'EMAIL') {
                await ShareExportService(context).shareViaEmail(resume);
              } else if (v == 'WHATSAPP') {
                await ShareExportService(context).shareViaWhatsApp(resume);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'EMAIL',
                child: ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'WHATSAPP',
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 595, // A4 width in logical pixels
            maxHeight: 842, // A4 height in logical pixels
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 700;
                      final header = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photoB64.isNotEmpty) ...[
                            _buildPhoto(photoB64) ?? const SizedBox.shrink(),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? resume.title : name,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: accent.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (email.isNotEmpty)
                                      _contactRow(Icons.email_outlined, email),
                                    if (phone.isNotEmpty)
                                      _contactRow(Icons.phone_outlined, phone),
                                    if (portfolio.isNotEmpty)
                                      _contactRow(Icons.public, portfolio),
                                    if (social.isNotEmpty)
                                      _contactRow(Icons.link, social),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      Widget left() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (summary.isNotEmpty) ...[
                            _sectionTitle('CREATIVE SUMMARY'),
                            Text(summary),
                            const SizedBox(height: 12),
                          ],
                          _sectionTitle('WORK EXPERIENCE'),
                          for (final w in work) ...[
                            _jobBlock(w),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 10),
                          _sectionTitle('PROJECTS'),
                          if ((data['projects'] ?? '').toString().isNotEmpty)
                            _bulletsFromCsv(
                              (data['projects'] ?? '').toString(),
                            ),
                        ],
                      );

                      Widget right() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('EDUCATION'),
                          for (final e in edus) ...[
                            _eduBlock(e),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 10),
                          if (skillsCsv.isNotEmpty) ...[
                            _sectionTitle('SKILLS'),
                            _bulletsFromCsv(skillsCsv),
                            const SizedBox(height: 10),
                          ],
                          if (tools.isNotEmpty) ...[
                            _sectionTitle('TOOLS & SOFTWARE'),
                            _bulletsFromCsv(tools),
                            const SizedBox(height: 10),
                          ],
                          if (languages.isNotEmpty) ...[
                            _sectionTitle('LANGUAGES'),
                            _bulletsFromCsv(languages),
                            const SizedBox(height: 10),
                          ],
                          if (hobbies.isNotEmpty) ...[
                            _sectionTitle('HOBBIES'),
                            _bulletsFromCsv(hobbies),
                            const SizedBox(height: 10),
                          ],
                          if (references.isNotEmpty) ...[
                            _sectionTitle('REFERENCES'),
                            Text(references),
                          ],
                        ],
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          const SizedBox(height: 16),
                          if (isNarrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                left(),
                                const SizedBox(height: 16),
                                right(),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: left()),
                                const SizedBox(width: 24),
                                Expanded(flex: 1, child: right()),
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
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.indigo),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text, softWrap: true, overflow: TextOverflow.visible),
      ),
    ],
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
        color: Colors.indigo,
      ),
    ),
  );

  Widget? _buildPhoto(String b64) {
    try {
      final comma = b64.indexOf(',');
      final raw = comma > 0 ? b64.substring(comma + 1) : b64;
      final bytes = base64Decode(raw);
      return CircleAvatar(radius: 36, backgroundImage: MemoryImage(bytes));
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _parseWork(dynamic raw) {
    if (raw == null) return const [];
    try {
      if (raw is String) {
        final arr = jsonDecode(raw);
        return List<Map<String, dynamic>>.from(arr);
      }
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
    } catch (_) {}
    return const [];
  }

  List<Map<String, dynamic>> _parseEducation(dynamic raw) {
    if (raw == null) return const [];
    try {
      if (raw is String) {
        final arr = jsonDecode(raw);
        return List<Map<String, dynamic>>.from(arr);
      }
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
    } catch (_) {}
    return const [];
  }

  Widget _jobBlock(Map<String, dynamic> w) {
    final title = (w['jobTitle'] ?? '').toString();
    final company = (w['company'] ?? '').toString();
    final location = (w['location'] ?? '').toString();
    final start = (w['startDate'] ?? '').toString();
    final end = (w['endDate'] ?? '').toString();
    final desc = (w['description'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (company.isNotEmpty) Text(company),
        Row(
          children: [
            if (start.isNotEmpty || end.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12),
                  const SizedBox(width: 6),
                  Text(_range(start, end)),
                ],
              ),
            if (location.isNotEmpty) ...[
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 12),
              const SizedBox(width: 4),
              Text(location),
            ],
          ],
        ),
        if (desc.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(desc)),
      ],
    );
  }

  Widget _eduBlock(Map<String, dynamic> e) {
    final degree = (e['degree'] ?? '').toString();
    final school = (e['institution'] ?? e['school'] ?? '').toString();
    final location = (e['location'] ?? '').toString();
    final start = (e['startDate'] ?? '').toString();
    final end = (e['endDate'] ?? '').toString();
    final desc = (e['description'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (degree.isNotEmpty)
          Text(degree, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (school.isNotEmpty) Text(school),
        Row(
          children: [
            if (start.isNotEmpty || end.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12),
                  const SizedBox(width: 6),
                  Text(_range(start, end)),
                ],
              ),
            if (location.isNotEmpty) ...[
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 12),
              const SizedBox(width: 4),
              Text(location),
            ],
          ],
        ),
        if (desc.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(desc)),
      ],
    );
  }

  Widget _bulletsFromCsv(String csv) {
    final items = csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(s)),
              ],
            ),
          ),
      ],
    );
  }

  String _range(String startIso, String endIso) {
    String fmt(String iso) {
      if (iso.isEmpty) return '';
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
}
