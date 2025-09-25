import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/saved_resume.dart';
import '../services/resume_storage_service.dart';
import '../services/share_export_service.dart';
import '../services/reminder_service.dart';
import '../services/auth_service.dart';
import '../services/premium_service.dart';
import 'resume_template_selection_screen.dart';
import '../main.dart'; // for loggedInNotifier

// Form screens for editing:
import 'classic_resume_form_screen.dart';
import 'modern_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';
import 'professional_resume_form_screen.dart';
import 'creative_resume_form_screen.dart';

class SavedResumesScreen extends StatefulWidget {
  const SavedResumesScreen({super.key});

  @override
  State<SavedResumesScreen> createState() => _SavedResumesScreenState();
}

class _SavedResumesScreenState extends State<SavedResumesScreen> {
  final df = DateFormat('yMMMd – HH:mm');
  bool _reminderInited = false;

  @override
  void initState() {
    super.initState();
    _initReminder();
    _initResumeStorage();
  }

  Future<void> _initReminder() async {
    await ReminderService.instance.init();
    if (mounted) setState(() => _reminderInited = true);
  }

  Future<void> _initResumeStorage() async {
    // Initialize cloud sync when screen loads
    await ResumeStorageService.instance.initialize();
  }

  void _openEdit(SavedResume r) {
    Widget screen;
    switch (r.template) {
      case 'Classic':
        screen = ClassicResumeFormScreen(existing: r);
        break;
      case 'Modern':
        screen = ModernResumeFormScreen(existingResume: r); // FIXED param name
        break;
      case 'Minimal':
        screen = MinimalResumeFormScreen(existing: r); // Matches constructor
        break;
      case 'Professional':
        screen = ProfessionalResumeFormScreen(existing: r);
        break;
      case 'Creative':
        screen = CreativeResumeFormScreen(existing: r);
        break;
      default:
        screen = ClassicResumeFormScreen(existing: r);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _rename(SavedResume r) async {
    final controller = TextEditingController(text: r.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().isNotEmpty),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ResumeStorageService.instance.renameResume(
        r.id,
        controller.text.trim(),
      );
    }
  }

  Future<void> _delete(SavedResume r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text(
          'Are you sure you want to delete "${r.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ResumeStorageService.instance.deleteResume(r.id);
    }
  }

  Future<void> _export(SavedResume r, String type) async {
    switch (type) {
      case 'pdf':
        await ShareExportService.instance.exportAndOpenPdf(r);
        break;
      case 'doc':
        await ShareExportService.instance.exportAndOpenDoc(r);
        break;
      case 'txt':
        await ShareExportService.instance.exportAndOpenTxt(r);
        break;
    }
  }

  Widget _reminderBanner(List<SavedResume> list) {
    if (!_reminderInited) return const SizedBox.shrink();
    final service = ReminderService.instance;
    if (!service.shouldPrompt(list)) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'It has been over 3 months since your last update. Refresh your resumes to keep them current.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () async {
                await ReminderService.instance.recordPrompt();
                if (mounted) setState(() {});
              },
              child: const Text('Later'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Saved Resumes'),
        actions: [
          // Cloud sync button (Premium only)
          if (PremiumService.hasCloudSync)
            IconButton(
              tooltip: 'Sync with Cloud',
              icon: const Icon(Icons.cloud_sync),
              onPressed: () async {
                await ResumeStorageService.instance.syncWithCloud();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced with cloud!')),
                  );
                }
              },
            ),
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResumeTemplateSelectionScreen(),
                ),
              );
            },
          ),
          ValueListenableBuilder<List<SavedResume>>(
            valueListenable: ResumeStorageService.instance.resumes,
            builder: (_, list, __) {
              final enabled = ReminderService.instance.enabled;
              return IconButton(
                tooltip: enabled
                    ? 'Disable 3‑month reminder'
                    : 'Enable 3‑month reminder',
                icon: Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                ),
                onPressed: () async {
                  await ReminderService.instance.setEnabled(!enabled);
                  if (mounted) setState(() {});
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              loggedInNotifier.value =
                  false; // This will show LoginScreen via main.dart
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<SavedResume>>(
        valueListenable: ResumeStorageService.instance.resumes,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const Center(child: Text('No saved resumes yet'));
          }
          return Column(
            children: [
              _reminderBanner(list),
              _buildResumeLimitBanner(context, list.length),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 12,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(r.title),
                      subtitle: Text(
                        '${r.template} • Updated ${df.format(r.updatedAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _viewResume(context, r),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          switch (v) {
                            case 'view':
                              _viewResume(context, r);
                              break;
                            case 'edit':
                              _openEdit(r);
                              break;
                            case 'rename':
                              _rename(r);
                              break;
                            case 'pdf':
                              _export(r, 'pdf');
                              break;
                            case 'doc':
                              _export(r, 'doc');
                              break;
                            case 'txt':
                              _export(r, 'txt');
                              break;
                            case 'delete':
                              _delete(r);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.visibility_outlined),
                              title: Text('View'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.drive_file_rename_outline),
                              title: Text('Rename'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.picture_as_pdf_outlined),
                              title: Text('Export PDF'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'doc',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.description_outlined),
                              title: Text('Export DOC'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'txt',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.note_outlined),
                              title: Text('Export TXT'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewResume(BuildContext context, SavedResume r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResumeDetailsScreen(resume: r)),
    );
  }

  Widget _buildResumeLimitBanner(BuildContext context, int currentCount) {
    if (PremiumService.isPremium) return const SizedBox.shrink();

    final maxResumes = PremiumService.maxResumes;
    final isNearLimit = currentCount >= maxResumes - 1;
    final isAtLimit = currentCount >= maxResumes;

    if (!isNearLimit) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isAtLimit ? Colors.red.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isAtLimit ? Icons.error_outline : Icons.warning_outlined,
            color: isAtLimit ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAtLimit ? 'Resume Limit Reached' : 'Almost at Limit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAtLimit
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  isAtLimit
                      ? 'You\'ve reached the $maxResumes resume limit. Upgrade to Premium for unlimited resumes!'
                      : 'You have $currentCount/$maxResumes resumes. Upgrade to Premium for unlimited storage!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isAtLimit
                        ? Colors.red.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              PremiumService.showUpgradeDialog(context, 'Unlimited Resumes');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

class ResumeDetailsScreen extends StatelessWidget {
  final SavedResume resume;
  const ResumeDetailsScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yMMMd – HH:mm');
    final String? photoB64 =
        (resume.data['profilePhotoBase64'] is String &&
            (resume.data['profilePhotoBase64'] as String).isNotEmpty)
        ? resume.data['profilePhotoBase64'] as String
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(resume.title),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (photoB64 != null) ...[
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: MemoryImage(base64Decode(photoB64)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _row('Template', resume.template),
                    _row('Created', df.format(resume.createdAt)),
                    _row('Updated', df.format(resume.updatedAt)),
                    _row('Fields', resume.data.length.toString()),
                  ],
                ),
              ),
            ),
          ),
          if (resume.data.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Fields', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...resume.data.entries.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e.key),
                subtitle: Text(
                  e.value.toString(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
