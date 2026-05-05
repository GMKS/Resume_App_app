import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shareable_export_file.dart';
import '../../../shared/widgets/feature_gate.dart';

const List<_PortfolioProject> _defaultProjects = <_PortfolioProject>[
  _PortfolioProject(
    id: 'project-1',
    title: 'E-Commerce Platform',
    description: 'Built with Flutter & Firebase',
  ),
  _PortfolioProject(
    id: 'project-2',
    title: 'AI-Powered Chat App',
    description: 'Real-time messaging application',
  ),
];

const List<_PortfolioCertificate> _defaultCertificates =
    <_PortfolioCertificate>[
      _PortfolioCertificate(
        id: 'certificate-1',
        title: 'Flutter Developer Certification',
        issuer: 'Google',
        date: 'Jan 2026',
      ),
    ];

const XTypeGroup _certificateFileGroup = XTypeGroup(
  label: 'Certificate Files',
  extensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
);

class PortfolioTabScreen extends ConsumerStatefulWidget {
  const PortfolioTabScreen({super.key});

  @override
  ConsumerState<PortfolioTabScreen> createState() =>
      _PortfolioTabScreenState();
}

class _PortfolioTabScreenState extends ConsumerState<PortfolioTabScreen> {
  static const String _projectsKey = 'portfolio_projects';
  static const String _certificatesKey = 'portfolio_certificates';
  static const String _portfolioUrl =
      'https://myportfolio.resumebuilder.app/johndoe';

  final GlobalKey _qrBoundaryKey = GlobalKey();

  late List<_PortfolioProject> _projects;
  late List<_PortfolioCertificate> _certificates;
  bool _isExportingQr = false;

  @override
  void initState() {
    super.initState();
    _projects = _readProjects();
    _certificates = _readCertificates();
  }

  List<_PortfolioProject> _readProjects() {
    final raw = StorageService.prefs.getString(_projectsKey);
    if (raw == null || raw.trim().isEmpty) {
      return List<_PortfolioProject>.from(_defaultProjects);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return List<_PortfolioProject>.from(_defaultProjects);
      }

      final loaded = decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .map(_PortfolioProject.fromMap)
          .toList(growable: false);

      return loaded.isEmpty
          ? List<_PortfolioProject>.from(_defaultProjects)
          : loaded;
    } catch (_) {
      return List<_PortfolioProject>.from(_defaultProjects);
    }
  }

  List<_PortfolioCertificate> _readCertificates() {
    final raw = StorageService.prefs.getString(_certificatesKey);
    if (raw == null || raw.trim().isEmpty) {
      return List<_PortfolioCertificate>.from(_defaultCertificates);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return List<_PortfolioCertificate>.from(_defaultCertificates);
      }

      final loaded = decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .map(_PortfolioCertificate.fromMap)
          .toList(growable: false);

      return loaded.isEmpty
          ? List<_PortfolioCertificate>.from(_defaultCertificates)
          : loaded;
    } catch (_) {
      return List<_PortfolioCertificate>.from(_defaultCertificates);
    }
  }

  Future<void> _persistPortfolio() async {
    final projectPayload =
        _projects.map((project) => project.toMap()).toList(growable: false);
    final certificatePayload = _certificates
        .map((certificate) => certificate.toMap())
        .toList(growable: false);

    await StorageService.prefs.setString(_projectsKey, jsonEncode(projectPayload));
    await StorageService.prefs.setString(
      _certificatesKey,
      jsonEncode(certificatePayload),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _sharePortfolio() async {
    try {
      await Share.share(
        _portfolioUrl,
        subject: 'My Portfolio',
      );
    } catch (error) {
      _showSnackBar('Unable to share portfolio link: $error', isError: true);
    }
  }

  Future<void> _copyPortfolioLink() async {
    await Clipboard.setData(const ClipboardData(text: _portfolioUrl));
    _showSnackBar('Link copied to clipboard');
  }

  Future<void> _openPortfolioLink() async {
    final uri = Uri.parse(_portfolioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return;
    }

    _showSnackBar('Unable to open portfolio link.', isError: true);
  }

  Future<void> _downloadQrCode() async {
    if (_isExportingQr) {
      return;
    }

    setState(() => _isExportingQr = true);
    try {
      final bytes = await _captureQrCodeBytes();
      final file = await buildShareableExportFile(
        bytes: bytes,
        fileName: 'portfolio_qr_code.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles(
        <XFile>[file],
        subject: 'Portfolio QR Code',
        text: 'Save or share this QR code for $_portfolioUrl',
      );

      if (!mounted) {
        return;
      }
      _showSnackBar('QR code is ready to save or share.');
    } catch (error) {
      _showSnackBar('Unable to export QR code: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExportingQr = false);
      }
    }
  }

  Future<Uint8List> _captureQrCodeBytes() async {
    final boundary = _qrBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('QR code is not ready yet.');
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to render QR code image.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _saveProject({_PortfolioProject? existing}) async {
    final result = await showDialog<_PortfolioProject>(
      context: context,
      builder: (context) => _ProjectEditorDialog(existing: existing),
    );

    if (result == null) {
      return;
    }

    setState(() {
      if (existing == null) {
        _projects = <_PortfolioProject>[result, ..._projects];
      } else {
        _projects = _projects
            .map((project) => project.id == result.id ? result : project)
            .toList(growable: false);
      }
    });

    await _persistPortfolio();
    _showSnackBar(existing == null ? 'Project added.' : 'Project updated.');
  }

  Future<void> _saveCertificate() async {
    final result = await showDialog<_PortfolioCertificate>(
      context: context,
      builder: (context) => const _CertificateEditorDialog(),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _certificates = <_PortfolioCertificate>[result, ..._certificates];
    });

    await _persistPortfolio();
    _showSnackBar('Certificate added.');
  }

  Future<void> _viewCertificate(_PortfolioCertificate certificate) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CertificateDetailsSheet(
          certificate: certificate,
          onShareFile: certificate.hasAttachment
              ? () {
                  Navigator.of(sheetContext).pop();
                  _shareCertificateFile(certificate);
                }
              : null,
        );
      },
    );
  }

  Future<void> _shareCertificateFile(
    _PortfolioCertificate certificate,
  ) async {
    if (!certificate.hasAttachment) {
      _showSnackBar('No file is attached to this certificate.', isError: true);
      return;
    }

    try {
      await Share.shareXFiles(
        <XFile>[
          XFile(
            certificate.filePath!,
            name: certificate.fileName,
          ),
        ],
        subject: certificate.title,
        text: '${certificate.title} by ${certificate.issuer}',
      );
    } catch (error) {
      _showSnackBar('Unable to open certificate file: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: FeatureGate(
        featureName: 'portfolio',
        upgradeMessage:
            'Create a stunning online portfolio to showcase your work',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.link,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Portfolio Link',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  _portfolioUrl,
                                  onTap: _openPortfolioLink,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyPortfolioLink,
                              icon: const Icon(Iconsax.copy, size: 18),
                              label: const Text('Copy Link'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sharePortfolio,
                              icon: const Icon(Iconsax.share, size: 18),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Portfolio QR Code',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: _qrBoundaryKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: _portfolioUrl,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _isExportingQr ? null : _downloadQrCode,
                          icon: _isExportingQr
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Iconsax.document_download),
                          label: Text(
                            _isExportingQr
                                ? 'Preparing QR Code...'
                                : 'Download QR Code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => _saveProject(),
                    icon: const Icon(Iconsax.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_projects.isEmpty)
                const _PortfolioEmptyState(
                  title: 'No projects yet',
                  message: 'Add a project so your portfolio shows recent work.',
                )
              else
                ..._projects.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final project = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _projects.length - 1 ? 0 : 12,
                      ),
                      child: _ProjectCard(
                        title: project.title,
                        description: project.description,
                        onEdit: () => _saveProject(existing: project),
                      )
                          .animate()
                          .fadeIn(delay: (300 + index * 80).ms)
                          .slideX(begin: -0.1, end: 0),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Certificates',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: _saveCertificate,
                    icon: const Icon(Iconsax.document_upload, size: 18),
                    label: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_certificates.isEmpty)
                const _PortfolioEmptyState(
                  title: 'No certificates yet',
                  message: 'Upload a certificate to add proof of your skills.',
                )
              else
                ..._certificates.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final certificate = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _certificates.length - 1 ? 0 : 12,
                      ),
                      child: _CertificateCard(
                        title: certificate.title,
                        issuer: certificate.issuer,
                        date: certificate.date,
                        onView: () => _viewCertificate(certificate),
                      )
                          .animate()
                          .fadeIn(delay: (450 + index * 80).ms)
                          .slideX(begin: -0.1, end: 0),
                    );
                  },
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.description,
    required this.onEdit,
  });

  final String title;
  final String description;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.folder_open,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Iconsax.edit),
              tooltip: 'Edit project',
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.title,
    required this.issuer,
    required this.date,
    required this.onView,
  });

  final String title;
  final String issuer;
  final String date;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.award,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$issuer • $date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onView,
              icon: const Icon(Iconsax.eye),
              tooltip: 'View certificate',
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioEmptyState extends StatelessWidget {
  const _PortfolioEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Iconsax.folder_cross,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectEditorDialog extends StatefulWidget {
  const _ProjectEditorDialog({this.existing});

  final _PortfolioProject? existing;

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project title and description are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _PortfolioProject(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Project' : 'Edit Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'e.g. Resumix AI App',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Summarize what the project does and what you built.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.existing == null ? 'Save Project' : 'Update Project'),
        ),
      ],
    );
  }
}

class _CertificateEditorDialog extends StatefulWidget {
  const _CertificateEditorDialog();

  @override
  State<_CertificateEditorDialog> createState() =>
      _CertificateEditorDialogState();
}

class _CertificateEditorDialogState extends State<_CertificateEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _issuerController;
  late final TextEditingController _dateController;

  String? _fileName;
  String? _filePath;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _issuerController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPickingFile = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[_certificateFileGroup],
        confirmButtonText: 'Attach Certificate',
      );

      if (file == null || !mounted) {
        return;
      }

      setState(() {
        _fileName = file.name;
        _filePath = file.path;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick certificate file: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final issuer = _issuerController.text.trim();
    final date = _dateController.text.trim();

    if (title.isEmpty || issuer.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate title, issuer, and date are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _PortfolioCertificate(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        issuer: issuer,
        date: date,
        fileName: _fileName,
        filePath: _filePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Certificate'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Certificate Title',
                hintText: 'e.g. AWS Certified Cloud Practitioner',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _issuerController,
              decoration: const InputDecoration(
                labelText: 'Issuer',
                hintText: 'e.g. Amazon Web Services',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'e.g. Jan 2026',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isPickingFile ? null : _pickFile,
              icon: _isPickingFile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.document_upload),
              label: Text(
                _fileName == null ? 'Attach file (optional)' : 'Replace file',
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 10),
              Text(
                _fileName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save Certificate'),
        ),
      ],
    );
  }
}

class _CertificateDetailsSheet extends StatelessWidget {
  const _CertificateDetailsSheet({
    required this.certificate,
    this.onShareFile,
  });

  final _PortfolioCertificate certificate;
  final VoidCallback? onShareFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              certificate.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _CertificateDetailRow(label: 'Issuer', value: certificate.issuer),
            const SizedBox(height: 12),
            _CertificateDetailRow(label: 'Date', value: certificate.date),
            const SizedBox(height: 12),
            _CertificateDetailRow(
              label: 'Attached file',
              value: certificate.fileName ?? 'No file attached',
            ),
            const SizedBox(height: 20),
            if (onShareFile != null)
              FilledButton.icon(
                onPressed: onShareFile,
                icon: const Icon(Iconsax.share),
                label: const Text('Open or Share File'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else
              Text(
                'This certificate currently stores the details only. Upload a file next time if you want to share the document from here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CertificateDetailRow extends StatelessWidget {
  const _CertificateDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioProject {
  const _PortfolioProject({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory _PortfolioProject.fromMap(Map<String, dynamic> map) {
    return _PortfolioProject(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }
}

class _PortfolioCertificate {
  const _PortfolioCertificate({
    required this.id,
    required this.title,
    required this.issuer,
    required this.date,
    this.fileName,
    this.filePath,
  });

  final String id;
  final String title;
  final String issuer;
  final String date;
  final String? fileName;
  final String? filePath;

  bool get hasAttachment =>
      fileName != null &&
      fileName!.trim().isNotEmpty &&
      filePath != null &&
      filePath!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'issuer': issuer,
      'date': date,
      'fileName': fileName,
      'filePath': filePath,
    };
  }

  factory _PortfolioCertificate.fromMap(Map<String, dynamic> map) {
    return _PortfolioCertificate(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      issuer: map['issuer']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      fileName: map['fileName']?.toString(),
      filePath: map['filePath']?.toString(),
    );
  }
}
