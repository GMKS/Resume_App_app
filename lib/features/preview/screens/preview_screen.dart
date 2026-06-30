import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_info.dart';
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
import '../services/preview_image_service.dart';
import '../services/preview_media_service.dart';
import '../services/preview_pdf_service.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String resumeId;
  final ResumeModel? initialResume;

  const PreviewScreen({
    super.key,
    required this.resumeId,
    this.initialResume,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  static const String _previewRendererVersion =
      '2026-05-31-business-management-curved-header-v196';
  static const double _gifExportDpi = 170;
  static const double _readingMinZoom = 1.0;
  static const double _readingMaxZoom = 2.5;
  static const double _readingZoomStep = 0.2;
  ResumeModel? _resume;
  bool _isLoading = false;
  String? _activeExportLabel;
  bool _isPreviewLoading = false;
  Uint8List? _previewBytes;
  List<Uint8List> _previewPageImages = const [];
  String? _previewSignature;
  bool _isReadingMode = false;
  double _readingZoom = _readingMinZoom;
  double _readingZoomStart = _readingMinZoom;

  bool get _usesRasterizedPreview =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _hasResolvedPreview =>
      _previewBytes != null &&
      (!_usesRasterizedPreview || _previewPageImages.isNotEmpty);

  void _logLifecycle(String phase, {ResumeModel? resume, Object? error}) {
    debugPrint(
      '[PreviewScreen][$phase] '
      'resumeId=${widget.resumeId} '
      'mounted=$mounted '
      'hasResume=${resume != null} '
      'previewLoading=$_isPreviewLoading '
      'hasPreviewBytes=${_previewBytes != null} '
      'previewPages=${_previewPageImages.length} '
      'previewSignature=${_previewSignature ?? 'null'} '
      '${error == null ? '' : 'error=$error'}',
    );
  }

  void _setExportLoadingState({
    required bool isLoading,
    String? exportLabel,
  }) {
    if (!mounted) return;
    setState(() {
      _isLoading = isLoading;
      _activeExportLabel = isLoading ? exportLabel : null;
    });
  }

  void _toggleReadingMode() {
    if (!mounted) return;
    setState(() {
      _isReadingMode = !_isReadingMode;
      if (!_isReadingMode) {
        _readingZoom = _readingMinZoom;
      }
    });
  }

  void _setReadingZoom(double value) {
    final clamped = value.clamp(_readingMinZoom, _readingMaxZoom);
    if ((_readingZoom - clamped).abs() < 0.01 || !mounted) {
      return;
    }
    setState(() {
      _readingZoom = clamped;
    });
  }

  void _handleReadingScaleStart(ScaleStartDetails details) {
    if (!_isReadingMode) {
      return;
    }
    _readingZoomStart = _readingZoom;
  }

  void _handleReadingScaleUpdate(ScaleUpdateDetails details) {
    if (!_isReadingMode || details.pointerCount < 2) {
      return;
    }
    _setReadingZoom(_readingZoomStart * details.scale);
  }

  @override
  void reassemble() {
    super.reassemble();
    _logLifecycle('reassemble', resume: _resume);
    final resume = _currentResume();
    if (resume == null) {
      return;
    }

    _previewBytes = null;
    _previewPageImages = const [];
    _previewSignature = null;
    _refreshPreview(resume);
  }

  ResumeModel? _currentResume() {
    return _resume ?? StorageService.getResume(widget.resumeId);
  }

  @override
  void initState() {
    super.initState();
    _logLifecycle('initState:start');
    _loadResume();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logLifecycle('didChangeDependencies', resume: _resume);
  }

  void _loadResume() {
    final resume = widget.initialResume ?? StorageService.getResume(widget.resumeId);
    _logLifecycle('loadResume:start', resume: resume);
    if (!mounted) {
      return;
    }
    setState(() {
      _resume = resume;
      _previewBytes = null;
      _previewPageImages = const [];
      _previewSignature = null;
    });
    if (resume != null) {
      _refreshPreview(resume);
    }
  }

  String _customSectionsPreviewSignature(ResumeModel resume) {
    return resume.customSections.map((section) {
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
    }).join('||');
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

  Future<Uint8List> _buildPdfBytes(ResumeModel resume) async {
    return PreviewPdfService.generatePreviewBytes(resume);
  }

  Future<Uint8List> _pdfBytesForResume(ResumeModel resume) async {
    return PreviewPdfService.generateBytes(resume);
  }

  Future<void> _shareBytesFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String subject,
    required String text,
    bool preferPrintingOnWeb = false,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
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
        return;
      } catch (error) {
        lastError = error;
        if (attempt == 1) {
          rethrow;
        }
      }
    }

    throw StateError('Unable to prepare the export for sharing: $lastError');
  }

  void _showExportSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showExportError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _resumeFileStem(ResumeModel resume) {
    final rawName = resume.personalInfo.fullName.trim();
    final baseName = rawName.isEmpty ? 'Resume' : rawName;
    return baseName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _resumePdfFileName(ResumeModel resume) {
    return '${_resumeFileStem(resume)}_Resume.pdf';
  }

  String _resumeGifFileName(ResumeModel resume) {
    return '${_resumeFileStem(resume)}_Resume_Pages.gif';
  }

  Future<void> _refreshPreview(ResumeModel resume) async {
    final signature = _resumePreviewSignature(resume);
    if (_previewSignature == signature && _hasResolvedPreview) {
      _logLifecycle('refreshPreview:skip-cached', resume: resume);
      return;
    }

    _logLifecycle('refreshPreview:start', resume: resume);
    setState(() {
      _isPreviewLoading = true;
      _previewSignature = signature;
      _previewBytes = null;
      _previewPageImages = const [];
    });

    try {
      final bytes = await _buildPdfBytes(resume);
      if (!mounted || _previewSignature != signature) return;

      var pageImages = const <Uint8List>[];
      if (_usesRasterizedPreview) {
        pageImages = await PreviewImageService.generatePagesFromPdfBytes(bytes);
        if (!mounted || _previewSignature != signature) return;
      }

      setState(() {
        _previewBytes = bytes;
        _previewPageImages = pageImages;
        _resume = resume;
      });
      _logLifecycle('refreshPreview:success', resume: resume);
    } catch (error) {
      _logLifecycle('refreshPreview:error', resume: resume, error: error);
      rethrow;
    } finally {
      if (mounted && _previewSignature == signature) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
      _logLifecycle('refreshPreview:finally', resume: resume);
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

    _setExportLoadingState(
      isLoading: true,
      exportLabel: 'Generating PDF...',
    );
    try {
      final bytes = await _pdfBytesForResume(resume);
      await _shareBytesFile(
        bytes: bytes,
        fileName: _resumePdfFileName(resume),
        mimeType: 'application/pdf',
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'PDF resume export from ${AppInfo.appName}',
        preferPrintingOnWeb: true,
      );
      await FreePlanService.recordPdfExport();
      _showExportSuccess('PDF export ready to share.');
    } catch (e) {
      _showExportError('Error generating PDF: $e');
    } finally {
      _setExportLoadingState(isLoading: false);
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

    _setExportLoadingState(
      isLoading: true,
      exportLabel: 'Generating TXT...',
    );
    try {
      final export = ResumeExportService.buildTxtExport(resume);
      await _shareBytesFile(
        bytes: export.bytes,
        fileName: export.filename,
        mimeType: export.mimeType,
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'TXT resume export from ${AppInfo.appName}',
      );
      _showExportSuccess('TXT export ready to share.');
    } catch (e) {
      _showExportError('Error exporting TXT: $e');
    } finally {
      _setExportLoadingState(isLoading: false);
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

    _setExportLoadingState(
      isLoading: true,
      exportLabel: 'Generating DOCX...',
    );
    try {
      final export = ResumeExportService.buildDocxExport(resume);
      await _shareBytesFile(
        bytes: export.bytes,
        fileName: export.filename,
        mimeType: export.mimeType,
        subject: '${resume.personalInfo.fullName} Resume',
        text: 'DOCX resume export from ${AppInfo.appName}',
      );
      _showExportSuccess('DOCX export ready to share.');
    } catch (e) {
      _showExportError('Error exporting DOCX: $e');
    } finally {
      _setExportLoadingState(isLoading: false);
    }
  }

  Future<void> _exportGif() async {
    final resume = _currentResume();
    if (resume == null) return;
    if (!FreePlanService.canExportResumeTemplate(resume.templateId) ||
        !FreePlanService.canExportPdf) {
      showUpgradePromptSheet(
        context,
        featureName: 'export_gif',
        message: FreePlanService.exportMessageForTemplate(resume.templateId),
      );
      return;
    }

    _setExportLoadingState(
      isLoading: true,
      exportLabel: 'Generating GIF...',
    );
    try {
      final pdfBytes = await _pdfBytesForResume(resume);
      final bytes = await PreviewMediaService.generateGifFromPdfBytes(
        pdfBytes,
        dpi: _gifExportDpi,
      );
      await _shareBytesFile(
        bytes: bytes,
        fileName: _resumeGifFileName(resume),
        mimeType: 'image/gif',
        subject: '${resume.personalInfo.fullName} Resume Slideshow',
        text: 'Animated resume page slideshow from ${AppInfo.appName}',
      );
      _showExportSuccess('GIF export verified and ready to share.');
    } catch (e) {
      _showExportError('Error exporting GIF: $e');
    } finally {
      _setExportLoadingState(isLoading: false);
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
        child: SingleChildScrollView(
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
                icon: Iconsax.video_play,
                title: 'GIF',
                subtitle: 'Animated slideshow of all resume pages',
                locked: !FreePlanService.canExportResumeTemplate(
                      resume.templateId,
                    ) ||
                    !FreePlanService.canExportPdf,
                onTap: () {
                  Navigator.pop(context);
                  _exportGif();
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

  Widget _buildRasterPreview() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        _isReadingMode ? 4 : 16,
        0,
        _isReadingMode ? 4 : 16,
        _isReadingMode ? 8 : 24,
      ),
      itemCount: _previewPageImages.length,
      separatorBuilder: (_, __) => SizedBox(height: _isReadingMode ? 8 : 18),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Image.memory(
            _previewPageImages[index],
            fit: BoxFit.fitWidth,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }

  Widget _wrapPreviewWithReadingZoom(Widget child) {
    if (!_isReadingMode) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: constraints.maxWidth * _readingZoom,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildReadingModeControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _readingZoom <= _readingMinZoom
                      ? null
                      : () => _setReadingZoom(_readingZoom - _readingZoomStep),
                  tooltip: 'Zoom out',
                  icon: const Icon(Icons.remove),
                  color: Colors.white,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${(_readingZoom * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: (_readingZoom - _readingMinZoom).abs() < 0.01
                      ? null
                      : () => _setReadingZoom(_readingMinZoom),
                  tooltip: 'Reset zoom',
                  icon: const Icon(Icons.center_focus_strong),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: _readingZoom >= _readingMaxZoom
                      ? null
                      : () => _setReadingZoom(_readingZoom + _readingZoomStep),
                  tooltip: 'Zoom in',
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _toggleReadingMode,
      onScaleStart: _handleReadingScaleStart,
      onScaleUpdate: _handleReadingScaleUpdate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: _isReadingMode ? Colors.black : Colors.transparent,
        padding: EdgeInsets.only(top: _isReadingMode ? 0 : 18),
        child: Stack(
          children: [
            if (_previewBytes == null)
              const Center(child: CircularProgressIndicator())
            else
              _wrapPreviewWithReadingZoom(
                _usesRasterizedPreview
                    ? Stack(
                        children: [
                          _buildRasterPreview(),
                          if (FreePlanService.shouldShowWatermark)
                            _buildPreviewWatermarkOverlay(),
                        ],
                      )
                    : Stack(
                        children: [
                          PdfPreview(
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
                            _buildPreviewWatermarkOverlay(),
                        ],
                      ),
              ),
            if (_isReadingMode)
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  bottom: false,
                  child: IconButton(
                    onPressed: _toggleReadingMode,
                    icon: const Icon(Iconsax.close_circle),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            if (_isReadingMode) _buildReadingModeControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWatermarkOverlay() {
    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: -0.5,
          child: Text(
            'Generated with ${AppInfo.appName}\nUpgrade to remove watermark',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
    );
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
        text: 'Resume PDF from ${AppInfo.appName}',
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
    _logLifecycle('build', resume: resume);
    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appBar = _isReadingMode
        ? null
        : AppBar(
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
          );

    return Scaffold(
      backgroundColor: _isReadingMode
          ? Colors.black
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      body: Stack(
        children: [
          _buildPreviewContent(),
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
                      _activeExportLabel ??
                          (resume.writingLanguage != 'English'
                              ? 'Translating to ${resume.writingLanguage}...'
                              : 'Preparing export...'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isReadingMode
          ? null
          : SafeArea(
              top: false,
              child: Container(
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
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
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
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
    );
  }

  @override
  void deactivate() {
    _logLifecycle('deactivate', resume: _resume);
    super.deactivate();
  }

  @override
  void dispose() {
    _logLifecycle('dispose:start', resume: _resume);
    _previewBytes = null;
    _previewPageImages = const [];
    _previewSignature = null;
    super.dispose();
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
