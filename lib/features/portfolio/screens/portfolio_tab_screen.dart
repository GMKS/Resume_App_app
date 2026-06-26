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

import '../../../core/models/resume_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shareable_export_file.dart';
import '../../home/screens/home_screen.dart' show resumesProvider;
import '../services/portfolio_profile_service.dart';
import '../services/resume_share_service.dart';
import '../../../shared/widgets/feature_gate.dart';

const XTypeGroup _certificateFileGroup = XTypeGroup(
  label: 'Certificate Files',
  extensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
);

class PortfolioTabScreen extends ConsumerStatefulWidget {
  const PortfolioTabScreen({super.key});

  @override
  ConsumerState<PortfolioTabScreen> createState() => _PortfolioTabScreenState();
}

class _PortfolioTabScreenState extends ConsumerState<PortfolioTabScreen> {
  static const String _projectsKey = 'portfolio_projects';
  static const String _certificatesKey = 'portfolio_certificates';
  static const String _selectedResumeIdKey = 'portfolio_selected_resume_id';

  final GlobalKey _qrBoundaryKey = GlobalKey();

  late List<_PortfolioProject> _projects;
  late List<_PortfolioCertificate> _certificates;
  String? _selectedResumeId;
  String? _shareUrl;
  String? _shareResumeId;
  String? _shareResumeVersion;
  bool _isGeneratingShareLink = false;
  bool _isCopyingLink = false;
  bool _isSharingPortfolio = false;
  bool _isExportingQr = false;

  @override
  void initState() {
    super.initState();
    _projects = _readProjects();
    _certificates = _readCertificates();
    _selectedResumeId = _readSelectedResumeId();
  }

  String? _readSelectedResumeId() {
    final raw = StorageService.prefs.getString(_selectedResumeIdKey)?.trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  List<_PortfolioProject> _readProjects() {
    final raw = StorageService.prefs.getString(_projectsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <_PortfolioProject>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_PortfolioProject>[];
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

      return loaded;
    } catch (_) {
      return <_PortfolioProject>[];
    }
  }

  List<_PortfolioCertificate> _readCertificates() {
    final raw = StorageService.prefs.getString(_certificatesKey);
    if (raw == null || raw.trim().isEmpty) {
      return <_PortfolioCertificate>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_PortfolioCertificate>[];
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

      return loaded;
    } catch (_) {
      return <_PortfolioCertificate>[];
    }
  }

  Future<void> _persistPortfolio() async {
    final projectPayload =
        _projects.map((project) => project.toMap()).toList(growable: false);
    final certificatePayload = _certificates
        .map((certificate) => certificate.toMap())
        .toList(growable: false);

    await StorageService.prefs
        .setString(_projectsKey, jsonEncode(projectPayload));
    await StorageService.prefs.setString(
      _certificatesKey,
      jsonEncode(certificatePayload),
    );
  }

  Future<void> _persistSelectedResumeId(String? resumeId) async {
    final normalized = resumeId?.trim() ?? '';
    if (normalized.isEmpty) {
      await StorageService.prefs.remove(_selectedResumeIdKey);
      return;
    }
    await StorageService.prefs.setString(_selectedResumeIdKey, normalized);
  }

  ResumeModel? _currentSourceResume() {
    final resumes = ref.read(resumesProvider);
    return PortfolioProfileService.selectSourceResume(
      resumes,
      preferredResumeId: _selectedResumeId,
    );
  }

  String _portfolioUrlUnavailableMessage({required String action}) {
    return 'Select a saved resume before $action.';
  }

  Future<void> _handleSourceResumeChanged(String? resumeId) async {
    setState(() {
      _selectedResumeId = resumeId;
    });
    await _persistSelectedResumeId(resumeId);
    await _refreshShareLink(force: true);
  }

  Future<void> _refreshShareLink({bool force = false}) async {
    final resume = _currentSourceResume();
    final resumeId = resume?.id;
    final resumeVersion = resume?.updatedAt.toIso8601String();

    debugPrint('Resume ID: ${resumeId ?? ''}');
    debugPrint('Selected Resume ID: ${_selectedResumeId ?? ''}');

    if (resume == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _shareUrl = null;
        _shareResumeId = null;
        _shareResumeVersion = null;
        _isGeneratingShareLink = false;
      });
      return;
    }

    if (!force &&
        !_isGeneratingShareLink &&
        _shareUrl != null &&
        _shareResumeId == resumeId &&
        _shareResumeVersion == resumeVersion) {
      return;
    }

    if (mounted) {
      setState(() => _isGeneratingShareLink = true);
    }

    try {
      final record = await ResumeShareService.ensureShareRecord(resume);
      final portfolioUrl = record?.publicUrl.trim() ?? '';
      if (!mounted) {
        return;
      }
      setState(() {
        _shareUrl = portfolioUrl.isEmpty ? null : portfolioUrl;
        _shareResumeId = resumeId;
        _shareResumeVersion = resumeVersion;
        _isGeneratingShareLink = false;
      });
      debugPrint('Portfolio URL: ${_shareUrl ?? ''}');
      debugPrint('Portfolio URL length: ${(_shareUrl ?? '').length}');
      if ((_shareUrl ?? '').isNotEmpty) {
        debugPrint('QR Generated');
        debugPrint('Copy Enabled');
        debugPrint('Share Enabled');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _shareUrl = null;
        _shareResumeId = resumeId;
        _shareResumeVersion = resumeVersion;
        _isGeneratingShareLink = false;
      });
    }
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
    if (_isSharingPortfolio) {
      return;
    }

    await _refreshShareLink(force: true);
    final shareUrl = _shareUrl;
    if (shareUrl == null || shareUrl.isEmpty) {
      _showSnackBar(
        _portfolioUrlUnavailableMessage(action: 'sharing'),
        isError: true,
      );
      return;
    }

    setState(() => _isSharingPortfolio = true);
    debugPrint('Share Enabled');
    debugPrint('Portfolio URL: $shareUrl');
    debugPrint('Share URL length: ${shareUrl.length}');
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareUrl,
          subject: 'My Resume',
        ),
      );
    } catch (error) {
      _showSnackBar('Unable to share resume link: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSharingPortfolio = false);
      }
    }
  }

  Future<void> _copyPortfolioLink() async {
    if (_isCopyingLink) {
      return;
    }

    await _refreshShareLink(force: true);
    final shareUrl = _shareUrl;
    if (shareUrl == null || shareUrl.isEmpty) {
      _showSnackBar(
        _portfolioUrlUnavailableMessage(action: 'copying'),
        isError: true,
      );
      return;
    }

    setState(() => _isCopyingLink = true);
    debugPrint('Copy Enabled');
    debugPrint('Portfolio URL: $shareUrl');
    debugPrint('Copy URL length: ${shareUrl.length}');
    try {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      _showSnackBar('Link copied to clipboard');
    } catch (error) {
      _showSnackBar('Unable to copy resume link: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCopyingLink = false);
      }
    }
  }

  Future<void> _openPortfolioLink() async {
    await _refreshShareLink(force: true);
    final shareUrl = _shareUrl;
    if (shareUrl == null || shareUrl.isEmpty) {
      _showSnackBar(
        _portfolioUrlUnavailableMessage(action: 'opening it'),
        isError: true,
      );
      return;
    }

    final uri = Uri.tryParse(shareUrl);
    if (uri == null) {
      _showSnackBar('Resume share link is invalid.', isError: true);
      return;
    }

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

    await _refreshShareLink(force: true);
    final shareUrl = _shareUrl;
    if (shareUrl == null || shareUrl.isEmpty) {
      _showSnackBar(
        _portfolioUrlUnavailableMessage(action: 'exporting a QR code'),
        isError: true,
      );
      return;
    }

    setState(() => _isExportingQr = true);
    try {
      debugPrint('QR URL: $shareUrl');
      debugPrint('QR URL length: ${shareUrl.length}');
      final bytes = await _captureQrCodeBytes();
      final file = await buildShareableExportFile(
        bytes: bytes,
        fileName: 'portfolio_qr_code.png',
        mimeType: 'image/png',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[file],
          subject: 'Resume QR Code',
          text: 'Save or share this QR code for $shareUrl',
        ),
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
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(
              certificate.filePath!,
              name: certificate.fileName,
            ),
          ],
          subject: certificate.title,
          text: '${certificate.title} by ${certificate.issuer}',
        ),
      );
    } catch (error) {
      _showSnackBar('Unable to open certificate file: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumes = ref.watch(resumesProvider);
    final sourceResume = _currentSourceResume();
    final shareUrl = _shareUrl ?? '';
    final hasPortfolioUrl = shareUrl.isNotEmpty;
    final emptyPortfolioMessage = resumes.isEmpty
        ? 'Create a resume to enable sharing.'
        : _isGeneratingShareLink
            ? 'Generating a shareable resume link...'
            : 'Resume sharing is temporarily unavailable. Try again.';
    final sourceResumeVersion = sourceResume?.updatedAt.toIso8601String();
    if (sourceResume != null &&
        !_isGeneratingShareLink &&
        (_shareResumeId != sourceResume.id ||
            _shareResumeVersion != sourceResumeVersion)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshShareLink();
      });
    }
    final fullName = sourceResume?.personalInfo.fullName.trim() ?? '';
    final jobTitle = sourceResume?.personalInfo.jobTitle?.trim() ?? '';
    final summary = sourceResume?.objective?.trim() ?? '';
    final contactItems = <String>[
      sourceResume?.personalInfo.email.trim() ?? '',
      sourceResume?.personalInfo.phone.trim() ?? '',
      sourceResume?.personalInfo.address.trim() ?? '',
      sourceResume?.personalInfo.linkedIn?.trim() ?? '',
      sourceResume?.personalInfo.github?.trim() ?? '',
    ].where((item) => item.isNotEmpty).toList(growable: false);
    final resumeProjects = sourceResume?.projects ?? const <Project>[];
    final resumeCertifications =
        sourceResume?.certifications ?? const <Certification>[];
    final experienceItems = sourceResume?.experience ?? const <Experience>[];
    final educationItems = sourceResume?.education ?? const <Education>[];
    final customSections =
        sourceResume?.customSections ?? const <CustomSection>[];
    final achievementItems = experienceItems
        .expand((experience) => experience.achievements)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final skills = sourceResume?.skills
            .map((skill) => skill.name.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

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
              if (resumes.isEmpty)
                const _PortfolioEmptyState(
                  title: 'No resume selected yet',
                  message:
                      'Create or update a resume first. Your portfolio will automatically sync the latest resume details here.',
                )
              else ...[
                if (resumes.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Source',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: sourceResume?.id,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: resumes
                            .map(
                              (resume) => DropdownMenuItem<String>(
                                value: resume.id,
                                child: Text(
                                  resume.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _handleSourceResumeChanged,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty
                              ? fullName
                              : sourceResume?.title ?? 'Portfolio',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (jobTitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            jobTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                        if (contactItems.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: contactItems
                                .map((item) => _InfoChip(label: item))
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 16),
              ],
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
                                  hasPortfolioUrl
                                    ? shareUrl
                                      : emptyPortfolioMessage,
                                  onTap: hasPortfolioUrl
                                      ? _openPortfolioLink
                                      : null,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: hasPortfolioUrl
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        decoration: hasPortfolioUrl
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                      ),
                                  maxLines: hasPortfolioUrl ? 1 : 3,
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
                              onPressed: hasPortfolioUrl && !_isCopyingLink
                                  ? _copyPortfolioLink
                                  : null,
                              icon: _isCopyingLink
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Iconsax.copy, size: 18),
                              label: const Text('Copy Link'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: hasPortfolioUrl && !_isSharingPortfolio
                                  ? _sharePortfolio
                                  : null,
                              icon: _isSharingPortfolio
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Iconsax.share, size: 18),
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
                            child: hasPortfolioUrl
                                ? QrImageView(
                                    data: shareUrl,
                                    version: QrVersions.auto,
                                    size: 200,
                                    backgroundColor: Colors.white,
                                  )
                                : SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Iconsax.scan_barcode,
                                          size: 36,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          emptyPortfolioMessage,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _isExportingQr || !hasPortfolioUrl
                              ? null
                              : _downloadQrCode,
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
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 24),
                _PortfolioSectionCard(
                  title: 'Professional Summary',
                  child: Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 24),
                _PortfolioSectionCard(
                  title: 'Skills',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((skill) => _InfoChip(label: skill))
                        .toList(growable: false),
                  ),
                ),
              ],
              if (experienceItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Work Experience',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...experienceItems.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              entry.key == experienceItems.length - 1 ? 0 : 12,
                        ),
                        child: _ExperienceCard(experience: entry.value),
                      ),
                    ),
              ],
              if (achievementItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                _PortfolioSectionCard(
                  title: 'Key Achievements',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: achievementItems
                        .map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $achievement'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              if (educationItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Education',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...educationItems.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              entry.key == educationItems.length - 1 ? 0 : 12,
                        ),
                        child: _EducationCard(education: entry.value),
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projects from Resume',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resumeProjects.isEmpty)
                const _PortfolioEmptyState(
                  title: 'No resume projects yet',
                  message:
                      'Add projects to the selected resume and they will appear here automatically.',
                )
              else
                ...resumeProjects.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final project = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == resumeProjects.length - 1 ? 0 : 12,
                      ),
                      child: _ResumeProjectCard(
                        project: project,
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
                    'Portfolio Highlights',
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
                  title: 'No extra highlights yet',
                  message:
                      'Add optional showcase items if you want more portfolio-specific project highlights beyond the resume.',
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
                          .fadeIn(delay: (360 + index * 80).ms)
                          .slideX(begin: -0.1, end: 0),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Certifications from Resume',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resumeCertifications.isEmpty)
                const _PortfolioEmptyState(
                  title: 'No resume certifications yet',
                  message:
                      'Add certifications to the selected resume and they will appear here automatically.',
                )
              else
                ...resumeCertifications.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final certificate = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index == resumeCertifications.length - 1 ? 0 : 12,
                      ),
                      child: _ResumeCertificationCard(
                        certification: certificate,
                      )
                          .animate()
                          .fadeIn(delay: (450 + index * 80).ms)
                          .slideX(begin: -0.1, end: 0),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uploaded Certificates',
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
                  title: 'No uploaded certificates yet',
                  message:
                      'Upload an attachment here if you want a portfolio-specific certificate file to share.',
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
                          .fadeIn(delay: (520 + index * 80).ms)
                          .slideX(begin: -0.1, end: 0),
                    );
                  },
                ),
              if (customSections.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Additional Sections',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...customSections.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              entry.key == customSections.length - 1 ? 0 : 12,
                        ),
                        child: _CustomSectionCard(section: entry.value),
                      ),
                    ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _PortfolioSectionCard extends StatelessWidget {
  const _PortfolioSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});

  final Experience experience;

  @override
  Widget build(BuildContext context) {
    final achievements = experience.achievements
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience.position.trim().isNotEmpty
                  ? experience.position.trim()
                  : 'Role',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              experience.company.trim().isNotEmpty
                  ? experience.company.trim()
                  : 'Company',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.primary),
            ),
            if (experience.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(experience.description.trim()),
            ],
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...achievements.map(
                (achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $achievement'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.education});

  final Education education;

  @override
  Widget build(BuildContext context) {
    final degree =
        '${education.degree.trim()} ${education.fieldOfStudy.trim()}'.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (degree.isNotEmpty)
              Text(
                degree,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            if (education.institution.trim().isNotEmpty) ...[
              if (degree.isNotEmpty) const SizedBox(height: 4),
              Text(
                education.institution.trim(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
            if ((education.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text((education.description ?? '').trim()),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumeProjectCard extends StatelessWidget {
  const _ResumeProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final technologies = project.technologies
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title.trim().isNotEmpty
                  ? project.title.trim()
                  : 'Project',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (project.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(project.description.trim()),
            ],
            if (technologies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Technologies: $technologies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if ((project.url ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                (project.url ?? '').trim(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumeCertificationCard extends StatelessWidget {
  const _ResumeCertificationCard({required this.certification});

  final Certification certification;

  @override
  Widget build(BuildContext context) {
    final credentialParts = <String>[
      certification.issuer.trim(),
      (certification.credentialId ?? '').trim(),
      (certification.credentialUrl ?? '').trim(),
    ].where((item) => item.isNotEmpty).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              certification.name.trim().isNotEmpty
                  ? certification.name.trim()
                  : 'Certification',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (credentialParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...credentialParts.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomSectionCard extends StatelessWidget {
  const _CustomSectionCard({required this.section});

  final CustomSection section;

  @override
  Widget build(BuildContext context) {
    final items = section.items.where((item) {
      return item.title.trim().isNotEmpty ||
          (item.subtitle ?? '').trim().isNotEmpty ||
          (item.description ?? '').trim().isNotEmpty;
    }).toList(growable: false);

    return _PortfolioSectionCard(
      title: section.title.trim().isNotEmpty
          ? section.title.trim()
          : 'Additional Section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title.trim().isNotEmpty)
                      Text(
                        item.title.trim(),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        (item.subtitle ?? '').trim(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                    if ((item.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text((item.description ?? '').trim()),
                    ],
                  ],
                ),
              ),
            )
            .toList(growable: false),
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
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
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
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
          child:
              Text(widget.existing == null ? 'Save Project' : 'Update Project'),
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
