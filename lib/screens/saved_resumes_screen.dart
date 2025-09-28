import 'package:flutter/material.dart';
import '../services/resume_storage_service.dart';
import '../models/saved_resume.dart';
import '../services/premium_service.dart';
import '../services/share_export_service.dart';

class SavedResumesScreen extends StatelessWidget {
  const SavedResumesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<SavedResume>>(
        valueListenable: ResumeStorageService.instance.resumes,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No resumes yet. Save one to see it here.'),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = list[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(r.title),
                subtitle: Text(
                  '${r.template} • Updated ${_formatTime(r.updatedAt)}',
                ),
                onTap: () {
                  // Open editor based on template (lightweight placeholder)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open ${r.template} editor')),
                  );
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit ${r.title}')),
                        );
                        break;
                      case 'save':
                        // Force update timestamp
                        final updated = r.copyWith(updatedAt: DateTime.now());
                        await ResumeStorageService.instance.saveOrUpdate(
                          updated,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved')),
                          );
                        }
                        break;
                      case 'export_pdf':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Export');
                          return;
                        }
                        final f = await ShareExportService.instance
                            .exportAndOpenPdf(r);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('PDF ready: ${f.path}')),
                          );
                        }
                        break;
                      case 'export_docx':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Export');
                          return;
                        }
                        final d = await ShareExportService.instance.exportDoc(
                          r,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('DOCX ready: ${d.path}')),
                          );
                        }
                        break;
                      case 'export_txt':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Export');
                          return;
                        }
                        final t = await ShareExportService.instance.exportTxt(
                          r,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('TXT ready: ${t.path}')),
                          );
                        }
                        break;
                      case 'preview':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Preview');
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preview coming soon')),
                        );
                        break;
                      case 'share_email':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Sharing');
                          return;
                        }
                        await ShareExportService.instance.shareViaEmail(r);
                        break;
                      case 'share_whatsapp':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Sharing');
                          return;
                        }
                        await ShareExportService.instance.shareViaWhatsApp(r);
                        break;
                      case 'print':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Print');
                          return;
                        }
                        // For now, treat print as generating a PDF
                        await ShareExportService.instance.exportAndOpenPdf(r);
                        break;
                      case 'delete':
                        await ResumeStorageService.instance.deleteResume(r.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deleted')),
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: ListTile(
                          leading: Icon(Icons.save_outlined),
                          title: Text('Save'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ];

                    if (PremiumService.isPremium) {
                      items.addAll(const [
                        PopupMenuItem(
                          value: 'export_pdf',
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf),
                            title: Text('Export PDF'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export_docx',
                          child: ListTile(
                            leading: Icon(Icons.description),
                            title: Text('Export DOCX'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export_txt',
                          child: ListTile(
                            leading: Icon(Icons.text_snippet),
                            title: Text('Export TXT'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'preview',
                          child: ListTile(
                            leading: Icon(Icons.visibility_outlined),
                            title: Text('Preview'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share_email',
                          child: ListTile(
                            leading: Icon(Icons.email_outlined),
                            title: Text('Share via Email'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share_whatsapp',
                          child: ListTile(
                            leading: Icon(Icons.share_outlined),
                            title: Text('Share via WhatsApp'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: ListTile(
                            leading: Icon(Icons.print_outlined),
                            title: Text('Print'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ]);
                    }

                    items.add(
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
