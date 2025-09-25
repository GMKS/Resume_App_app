import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/saved_resume.dart';
import 'pdf_exporter.dart';
import 'word_exporter.dart';
import 'resume_renderer.dart';
import 'premium_service.dart';
import 'cloud_resume_service.dart';

class ShareExportService {
  ShareExportService._();
  static final ShareExportService instance = ShareExportService._();

  Future<File> _writeTemp(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> exportPdf(SavedResume r) async {
    final bytes = await generatePdf(
      r,
      addWatermark: PremiumService.hasWatermark,
    );
    return _writeTemp('${r.title.replaceAll(' ', '_')}.pdf', bytes);
  }

  Future<File> exportDoc(SavedResume r) async {
    if (!PremiumService.canExportFormat('DOCX')) {
      throw Exception('DOCX export requires Premium subscription');
    }
    final bytes = await generateDoc(r);
    return _writeTemp('${r.title.replaceAll(' ', '_')}.doc', bytes);
  }

  Future<File> exportTxt(SavedResume r) async {
    final txt = resumeToPlainText(r);
    return _writeTemp('${r.title.replaceAll(' ', '_')}.txt', txt.codeUnits);
  }

  Future<void> shareEmailClassic(SavedResume r) async {
    final body = resumeToPlainText(r);
    await Share.share(body, subject: r.title);
  }

  Future<void> shareGeneric(SavedResume r) async {
    final body = resumeToPlainText(r);
    await Share.share(body, subject: '${r.title} (${r.template})');
  }

  // Share via WhatsApp
  Future<void> shareViaWhatsApp(SavedResume r) async {
    try {
      final file = await exportPdf(r);
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my resume: ${r.title}',
        subject: r.title,
      );

      // If direct sharing fails, try opening WhatsApp with text
      if (result.status == ShareResultStatus.dismissed) {
        final text = Uri.encodeComponent('Check out my resume: ${r.title}');
        final whatsappUrl = 'whatsapp://send?text=$text';

        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl));
        } else {
          // Fallback to web WhatsApp
          final webWhatsappUrl = 'https://wa.me/?text=$text';
          await launchUrl(Uri.parse(webWhatsappUrl));
        }
      }
    } catch (e) {
      throw Exception('Failed to share via WhatsApp: $e');
    }
  }

  // Share via Email with attachment
  Future<void> shareViaEmail(SavedResume r) async {
    try {
      final file = await exportPdf(r);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Please find my resume attached.',
        subject: '${r.title} - Resume',
      );
    } catch (e) {
      // Fallback to text sharing
      final body = resumeToPlainText(r);
      await Share.share(body, subject: '${r.title} - Resume');
    }
  }

  // Share via LinkedIn (opens LinkedIn app or web)
  Future<void> shareViaLinkedIn(SavedResume r) async {
    try {
      final text = Uri.encodeComponent(
        'Just updated my resume! #JobSearch #Resume #Career',
      );
      final linkedinUrl =
          'linkedin://sharing/share-offsite/?url=https://linkedin.com&text=$text';

      if (await canLaunchUrl(Uri.parse(linkedinUrl))) {
        await launchUrl(Uri.parse(linkedinUrl));
      } else {
        // Fallback to web LinkedIn
        final webLinkedinUrl =
            'https://www.linkedin.com/sharing/share-offsite/?url=https://linkedin.com';
        await launchUrl(Uri.parse(webLinkedinUrl));
      }
    } catch (e) {
      throw Exception('Failed to share via LinkedIn: $e');
    }
  }

  // Save to cloud (premium feature)
  Future<bool> saveToCloud(SavedResume r) async {
    if (!PremiumService.hasCloudSync) {
      throw Exception('Cloud sync is a premium feature');
    }

    try {
      return await CloudResumeService.instance.uploadResume(r);
    } catch (e) {
      throw Exception('Failed to save to cloud: $e');
    }
  }

  // Get cloud resumes (premium feature)
  Stream<List<SavedResume>> getCloudResumes() {
    if (!PremiumService.hasCloudSync) {
      return Stream.value([]);
    }
    return CloudResumeService.instance.resumesStream;
  }

  // Delete from cloud
  Future<bool> deleteFromCloud(String resumeId) async {
    if (!PremiumService.hasCloudSync) {
      return false;
    }

    try {
      return await CloudResumeService.instance.deleteResume(resumeId);
    } catch (e) {
      return false;
    }
  }

  Future<void> exportAndOpenPdf(SavedResume r) async {
    final f = await exportPdf(r);
    await OpenFilex.open(f.path);
  }

  Future<void> exportAndOpenDoc(SavedResume r) async {
    final f = await exportDoc(r);
    await OpenFilex.open(f.path);
  }

  Future<void> exportAndOpenTxt(SavedResume r) async {
    final f = await exportTxt(r);
    await OpenFilex.open(f.path);
  }

  // Show sharing options dialog
  Future<void> showSharingOptions(context, SavedResume resume) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Resume',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.message,
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      shareViaWhatsApp(resume);
                    },
                  ),
                  _ShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      shareViaEmail(resume);
                    },
                  ),
                  _ShareOption(
                    icon: Icons.business,
                    label: 'LinkedIn',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      shareViaLinkedIn(resume);
                    },
                  ),
                  if (PremiumService.hasCloudSync)
                    _ShareOption(
                      icon: Icons.cloud_upload,
                      label: 'Cloud Save',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        saveToCloud(resume);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.share,
                    label: 'More Options',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      shareGeneric(resume);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
