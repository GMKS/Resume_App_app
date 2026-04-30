import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/subscription_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/resume_export_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/shareable_export_file.dart';
import '../../../shared/widgets/adaptive_tooltip.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../core/utils/browser_pdf_preview.dart';
import '../services/preview_pdf_service.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const PreviewScreen({super.key, required this.resumeId});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  static const String _previewRendererVersion =
  '2026-04-25-spanish-preview-fix-v186';
  ResumeModel? _resume;
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  Uint8List? _previewBytes;
  String? _previewSignature;

  @override
  void reassemble() {
    super.reassemble();
    final resume = _currentResume();
    if (resume == null) {
      return;
    }

    _previewBytes = null;
    _previewSignature = null;
    _refreshPreview(resume);
  }

  ResumeModel? _currentResume() {
    return StorageService.getResume(widget.resumeId) ?? _resume;
  }

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  void _loadResume() {
    final resume = StorageService.getResume(widget.resumeId);
    setState(() {
      _resume = resume;
      _previewBytes = null;
      _previewSignature = null;
    });
    if (resume != null) {
      _refreshPreview(resume);
    }
  }

  String _customSectionsPreviewSignature(ResumeModel resume) {
    return resume.customSections
        .map((section) {
          final itemSignature = section.items
              .map(
                (item) => [
                  item.id,
                  item.title,
                  item.subtitle ?? '',
                  item.description ?? '',
                  item.date?.millisecondsSinceEpoch.toString() ?? '',
                ].join('~'),
              )
              .join('^');

          return [
            section.id,
            section.title,
            section.order.toString(),
            itemSignature,
          ].join('::');
        })
        .join('||');
  }

  String _resumePreviewSignature(ResumeModel resume) {
    return [
      _previewRendererVersion,
      widget.resumeId,
      resume.templateId,
      resume.colorScheme.toString(),
      resume.writingLanguage,
      resume.updatedAt.millisecondsSinceEpoch.toString(),
      _customSectionsPreviewSignature(resume),
    ].join('|');
  }

  void _syncResumeFromStorageIfNeeded(ResumeModel resume) {
    final current = _resume;
    if (current != null && _resumePreviewSignature(current) == _resumePreviewSignature(resume)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resume = resume;
      });
    });
  }

  Future<Uint8List> _buildPdfBytes(ResumeModel resume) async {
    return PreviewPdfService.generateBytes(resume);
  }

  Future<Uint8List> _pdfBytesForResume(ResumeModel resume) async {
    final signature = _resumePreviewSignature(resume);
    if (_previewSignature == signature && _previewBytes != null) {
      return _previewBytes!;
    }

    return _buildPdfBytes(resume);
  }

  Future<void> _shareBytesFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String subject,
    required String text,
    bool preferPrintingOnWeb = false,
  }) async {
    if (kIsWeb && preferPrintingOnWeb && mimeType == 'application/pdf') {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }

    final file = await buildShareableExportFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    await Share.shareXFiles(
      [file],
      subject: subject,
      text: text,
    );
  }

  String _resumePdfFileName(ResumeModel resume) {
    return '${resume.personalInfo.fullName.replaceAll(' ', '_')}_Resume.pdf';
  }

  Future<void> _refreshPreview(ResumeModel resume) async {
    final signature = _resumePreviewSignature(resume);
    if (_previewSignature == signature && _previewBytes != null) {
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _previewSignature = signature;
      _previewBytes = null;
    });

    try {
      final bytes = await _buildPdfBytes(resume);
      if (!mounted || _previewSignature != signature) return;
      setState(() {
        _previewBytes = bytes;
      });
    } finally {
      if (mounted && _previewSignature == signature) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.canExportResumeTemplate(resume.templateId) ||
        !FreePlanService.canExportPdf) {
      showUpgradePromptSheet(
        context,
        featureName: 'export_pdf',
        message: FreePlanService.exportMessageForTemplate(resume.templateId),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _pdfBytesForResume(resume);
      await _shareBytesFile(
        bytes: bytes,
        fileName: _resumePdfFileName(resume),
        mimeType: 'application/pdf',
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'PDF resume export from Resume Builder',
        preferPrintingOnWeb: true,
      );
      await FreePlanService.recordPdfExport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error generating PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportTxt() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.canExportTxt) {
      showUpgradePromptSheet(
        context,
        featureName: SubscriptionFeatures.exportTxt,
        message: FreePlanService.premiumTxtMessage,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final export = ResumeExportService.buildTxtExport(resume);
      await _shareBytesFile(
        bytes: export.bytes,
        fileName: export.filename,
        mimeType: export.mimeType,
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'TXT resume export from Resume Builder',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting TXT: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportDocx() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.canExportDocx) {
      showUpgradePromptSheet(
        context,
        featureName: SubscriptionFeatures.exportDocx,
        message: FreePlanService.premiumDocxMessage,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final export = ResumeExportService.buildDocxExport(resume);
      await _shareBytesFile(
        bytes: export.bytes,
        fileName: export.filename,
        mimeType: export.mimeType,
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'DOCX resume export from Resume Builder',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting DOCX: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExportSheet() {
    final resume = _currentResume();
    if (resume == null) return;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export Resume',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your file format.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              _ExportOptionTile(
                icon: Iconsax.document_download,
                title: 'PDF',
                subtitle: FreePlanService.isPremium
                    ? 'Share a polished PDF resume'
                    : FreePlanService.exportMessageForTemplate(
                        resume.templateId,
                      ),
                locked: !FreePlanService.canExportResumeTemplate(
                      resume.templateId,
                    ) ||
                    !FreePlanService.canExportPdf,
                onTap: () {
                  Navigator.pop(context);
                  _exportPdf();
                },
              ),
              _ExportOptionTile(
                icon: Iconsax.document_text,
                title: 'TXT',
                subtitle: FreePlanService.canExportTxt
                    ? 'Plain text export for forms and portals'
                    : 'Premium format for ATS form copy-paste',
                locked: !FreePlanService.canExportTxt,
                onTap: () {
                  Navigator.pop(context);
                  _exportTxt();
                },
              ),
              _ExportOptionTile(
                icon: Iconsax.document,
                title: 'DOCX',
                subtitle: FreePlanService.canExportDocx
                    ? 'Microsoft Word compatible resume file'
                    : 'Premium Word export for editable resumes',
                locked: !FreePlanService.canExportDocx,
                onTap: () {
                  Navigator.pop(context);
                  _exportDocx();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printPdf() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.isPremium) {
      showUpgradePromptSheet(
        context,
        featureName: 'unlimited_exports',
        message: FreePlanService.advancedExportMessage,
      );
      return;
    }

    final browserPreview = kIsWeb
        ? openBrowserPdfPreview(
            title: '${resume.personalInfo.fullName} Resume Preview',
          )
        : null;

    setState(() => _isLoading = true);
    try {
      final bytes = await _pdfBytesForResume(resume);

      if (kIsWeb) {
        if (browserPreview != null) {
          await browserPreview.showPdf(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Print preview opened from a dedicated PDF tab.',
                ),
              ),
            );
          }
        } else {
          await Printing.sharePdf(
            bytes: bytes,
            filename: _resumePdfFileName(resume),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Popup blocked. The PDF was downloaded instead for printing.',
                ),
              ),
            );
          }
        }
      } else {
        await Printing.layoutPdf(onLayout: (format) async => bytes);
      }
    } catch (e) {
      browserPreview?.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _emailPdf() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.isPremium) {
      showUpgradePromptSheet(
        context,
        featureName: 'unlimited_exports',
        message: FreePlanService.advancedExportMessage,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _pdfBytesForResume(resume);
      final fileName = _resumePdfFileName(resume);

      await _shareBytesFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        subject: '${resume.personalInfo.fullName} - Resume',
        text: 'Please find my resume attached.',
        preferPrintingOnWeb: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error emailing PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePdf() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.isPremium) {
      showUpgradePromptSheet(
        context,
        featureName: 'unlimited_exports',
        message: FreePlanService.advancedExportMessage,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _pdfBytesForResume(resume);
      final fileName = _resumePdfFileName(resume);
      await _shareBytesFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'Resume PDF from Resume Builder',
        preferPrintingOnWeb: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error sharing PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = _currentResume();
    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _syncResumeFromStorageIfNeeded(resume);
    final previewSignature = _resumePreviewSignature(resume);
    if (_previewSignature != previewSignature && !_isPreviewLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshPreview(resume);
        }
      });
    }
    final previewKey = ValueKey(previewSignature);

    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveTooltip(
          message: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left),
          ),
        ),
        title: const Text('Preview'),
        actions: [
          if (!FreePlanService.isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  FreePlanService.trialStatusMessage,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          AdaptiveTooltip(
            message: 'Refresh preview',
            button: true,
            child: IconButton(
              onPressed: () {
                final resume = _currentResume();
                if (resume == null) return;
                setState(() {
                  _previewBytes = null;
                  _previewSignature = null;
                  _isPreviewLoading = false;
                });
                _refreshPreview(resume);
              },
              icon: const Icon(Iconsax.refresh),
            ),
          ),
          AdaptiveTooltip(
            message: 'Change template',
            button: true,
            child: IconButton(
              onPressed: () async {
                await context.push('/templates/${widget.resumeId}');
                if (mounted) {
                  _loadResume();
                }
              },
              icon: const Icon(Iconsax.brush_2),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Stack(
              children: [
                if (_previewBytes == null)
                  const Center(child: CircularProgressIndicator())
                else
                  PdfPreview(
                    key: previewKey,
                    build: (format) async => _previewBytes!,
                    actions: const [],
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: false,
                    allowSharing: false,
                    pdfPreviewPageDecoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                if (FreePlanService.shouldShowWatermark)
                  IgnorePointer(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Created with Resume Builder App\nUpgrade for watermark-free resumes',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      resume.writingLanguage != 'English'
                          ? 'Translating to ${resume.writingLanguage}...'
                          : 'Generating PDF...',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            AdaptiveTooltip(
              message: kIsWeb
                  ? 'Open a print-ready PDF in a new tab'
                  : 'Print your resume',
              button: true,
              child: IconButton(
                onPressed: _printPdf,
                icon: const Icon(Iconsax.printer),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AdaptiveTooltip(
              message: 'Email resume',
              button: true,
              child: IconButton(
                onPressed: _emailPdf,
                icon: const Icon(Iconsax.sms),
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEC4899).withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AdaptiveTooltip(
              message: 'Share resume',
              button: true,
              child: IconButton(
                onPressed: _sharePdf,
                icon: const Icon(Iconsax.share),
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showExportSheet,
                icon: const Icon(Iconsax.document_download),
                label: const Text('Export Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (locked ? AppColors.warning : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            locked ? Iconsax.lock_1 : icon,
            color: locked ? AppColors.warning : AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (locked) const PremiumBadge(locked: true),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
