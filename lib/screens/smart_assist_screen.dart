import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class SmartAssistScreen extends StatefulWidget {
  const SmartAssistScreen({super.key});

  @override
  State<SmartAssistScreen> createState() => _SmartAssistScreenState();
}

class _SmartAssistScreenState extends State<SmartAssistScreen> {
  final TextEditingController _resumeController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _jdController = TextEditingController();
  bool _analyzing = false;
  SmartAssistResult? _result;

  Future<void> _analyze() async {
    final text = _resumeController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your resume content.')),
      );
      return;
    }
    setState(() {
      _analyzing = true;
      _result = null;
    });
    try {
      final res = await analyzeResume(
        resumeContent: text,
        targetRole: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        jobDescription: _jdController.text.trim().isEmpty
            ? null
            : _jdController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    }
  }

  Future<void> _exportTxt() async {
    if (_result == null) return;
    final f = await exportSmartAssistTxtFromResult(_result!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('TXT exported: ${f.path}')));
  }

  Future<void> _exportPdf() async {
    if (_result == null) return;
    // Use styled export to mirror the formatted preview
    final f = await exportSmartAssistStyledPdfFromResult(_result!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF exported: ${f.path}')));
  }

  Future<void> _exportDocx() async {
    if (_result == null) return;
    final f = await exportSmartAssistDocxFromResult(_result!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('DOCX exported: ${f.path}')));
  }

  void _copyResume() {
    Clipboard.setData(ClipboardData(text: _resumeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Smart Assist')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste your resume content below to get instant tips:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resumeController,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Paste your resume content here...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    labelText: 'Target Role',
                    hintText: 'e.g., Software Engineer',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _jdController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Job Description (optional)',
                    hintText: 'Paste relevant JD to optimize keywords',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _copyResume,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Resume'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _analyzing ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(_analyzing ? 'Analyzing…' : 'Smart Analyze'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Smart Analyze Results
          if (_result != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Formatted Resume Preview (styled like sample) =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _result!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E4F8A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _result!.role,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 20,
                            runSpacing: 4,
                            children: [
                              if (_result!.phone != null)
                                _ContactPill(Icons.phone, _result!.phone!),
                              if (_result!.email != null)
                                _ContactPill(
                                  Icons.email_outlined,
                                  _result!.email!,
                                ),
                              if (_result!.location != null)
                                _ContactPill(
                                  Icons.location_on_outlined,
                                  _result!.location!,
                                ),
                              if (_result!.website != null)
                                _ContactPill(Icons.language, _result!.website!),
                              if (_result!.linkedIn != null)
                                _ContactPill(Icons.link, _result!.linkedIn!),
                              if (_result!.twitter != null)
                                _ContactPill(Icons.link, _result!.twitter!),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _result!.suggestedSummary,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Professional Experience
                          const _SectionHeader('PROFESSIONAL EXPERIENCE'),
                          const SizedBox(height: 8),
                          _ExperienceBlock(
                            bullets: _result!.enhancedBullets,
                            fallbackBlock:
                                _result!.sectionsRaw['experience'] ?? '',
                          ),
                          const SizedBox(height: 16),
                          // Education
                          const _SectionHeader('EDUCATION'),
                          const SizedBox(height: 8),
                          _SimpleTextBlock(
                            _result!.sectionsRaw['education'] ??
                                'Add your education details.',
                          ),
                          const SizedBox(height: 16),
                          // Skills
                          const _SectionHeader('SKILLS'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _result!.coreSkills.isNotEmpty
                                  ? _result!.coreSkills
                                        .map(
                                          (s) => Chip(
                                            label: Text(s),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        )
                                        .toList()
                                  : [
                                      const Text(
                                        'List your core skills to showcase strengths.',
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analysis Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _result!.sections.map((s) {
                        final status = s.status;
                        Color bg;
                        IconData icon;
                        switch (status) {
                          case SectionStatus.good:
                            bg = Colors.green.shade100;
                            icon = Icons.check_circle_outline;
                            break;
                          case SectionStatus.warn:
                            bg = Colors.amber.shade100;
                            icon = Icons.warning_amber_outlined;
                            break;
                          case SectionStatus.missing:
                            bg = Colors.red.shade100;
                            icon = Icons.error_outline;
                            break;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16),
                              const SizedBox(width: 6),
                              Text(s.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    if (_result!.alerts.isNotEmpty) ...[
                      const Text(
                        'Smart Alerts',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ..._result!.alerts.map(
                        (a) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notification_important,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(a)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'Professional Summary',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        border: Border.all(color: Colors.purple.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_result!.suggestedSummary),
                    ),
                    const SizedBox(height: 12),

                    if (_result!.suggestedKeywords.isNotEmpty ||
                        _result!.atsTerms.isNotEmpty) ...[
                      const Text(
                        'Keyword Optimization',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._result!.suggestedKeywords.map(
                            (k) => Chip(label: Text(k)),
                          ),
                          ..._result!.atsTerms.map(
                            (k) => Chip(
                              label: Text(k),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_result!.enhancedBullets.isNotEmpty) ...[
                      const Text(
                        'Enhanced Bullets',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ..._result!.enhancedBullets.map(
                        (b) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(b)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_result!.grammarSuggestions.isNotEmpty) ...[
                      const Text(
                        'Grammar & Clarity',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ..._result!.grammarSuggestions.map(
                        (g) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.spellcheck, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(g)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'Export Improved Resume',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _exportDocx,
                          icon: const Icon(Icons.description),
                          label: const Text('DOCX'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _exportTxt,
                          icon: const Icon(Icons.text_snippet),
                          label: const Text('TXT'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Share',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_result == null) return;
                            try {
                              print('DEBUG: Email button pressed');
                              await shareSmartAssistStyledViaEmail(_result!);
                            } catch (e) {
                              print('DEBUG: Email share error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Email share failed: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_result == null) return;
                            try {
                              print('DEBUG: WhatsApp button pressed');
                              await shareSmartAssistStyledViaWhatsApp(_result!);
                            } catch (e) {
                              print('DEBUG: WhatsApp share error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('WhatsApp share failed: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('WhatsApp'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ContactPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade800),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E4F8A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExperienceBlock extends StatelessWidget {
  final List<String> bullets;
  final String fallbackBlock;
  const _ExperienceBlock({required this.bullets, required this.fallbackBlock});

  @override
  Widget build(BuildContext context) {
    if (bullets.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }
    // Fallback: show raw block while keeping simple bullets
    final lines = fallbackBlock.split(RegExp(r'\r?\n')).map((l) => l.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .where((l) => l.isNotEmpty)
          .map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (l.startsWith('•') ||
                      l.startsWith('-') ||
                      l.startsWith('*'))
                    const Text('• '),
                  Expanded(
                    child: Text(l.replaceFirst(RegExp(r'^[•\-*]\s*'), '')),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SimpleTextBlock extends StatelessWidget {
  final String text;
  const _SimpleTextBlock(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerLeft, child: Text(text));
  }
}
