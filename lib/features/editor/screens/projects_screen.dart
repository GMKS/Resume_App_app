import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/free_plan_service.dart';
import '../../../core/services/resume_quality_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../shared/widgets/feature_gate.dart';
import '../../../shared/widgets/resume_quality_panel.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/editor_intro_card.dart';
import 'resume_editor_screen.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const ProjectsScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  Future<void> _handleQualitySuggestion(
    ResumeQualitySuggestion suggestion,
  ) async {
    String? route;
    switch (suggestion.sectionKey) {
      case 'personal':
        route = '/editor/${widget.resumeId}/personal';
        break;
      case 'summary':
        route = '/editor/${widget.resumeId}/summary';
        break;
      case 'experience':
        route = '/editor/${widget.resumeId}/experience';
        break;
      case 'projects':
        return;
      case 'skills':
        route = '/editor/${widget.resumeId}/skills';
        break;
      default:
        return;
    }

    await context.push(route);
  }

  void _showProjectDialog(Project? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProjectForm(resumeId: widget.resumeId, existing: existing),
    );
  }

  Widget _buildScreenHeader(
    BuildContext context,
    ResumeModel resume,
    ResumeQualityReport qualityReport,
  ) {
    final projectsWithUrls = resume.projects
        .where((project) => (project.url ?? '').trim().isNotEmpty)
        .length;
    final technologyRichProjects = resume.projects
        .where((project) => project.technologies.isNotEmpty)
        .length;

    return Column(
      children: [
        EditorIntroCard(
          title: 'Proof Through Projects',
          subtitle:
              'Use this section to show applied skills, shipped work, and public links. Clean project data strengthens both the preview and exported resume narrative.',
          icon: Iconsax.folder_open,
          accentColor: const Color(0xFFEC4899),
          stats: [
            EditorIntroStat(
              label: '${resume.projects.length} projects',
              icon: Iconsax.folder_open,
            ),
            EditorIntroStat(
              label: '$projectsWithUrls linked',
              icon: Iconsax.link,
            ),
            EditorIntroStat(
              label: '$technologyRichProjects tagged',
              icon: Iconsax.code,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResumeQualityPanel(
          report: qualityReport,
          title: 'Project Guidance',
          subtitle:
              'Projects work best when they connect outcomes, technologies, and a destination link recruiters can inspect.',
          accentColor: const Color(0xFFEC4899),
          maxSuggestions: 2,
          onSuggestionTap: _handleQualitySuggestion,
        ),
      ],
    );
  }

  void _deleteProject(String id) {
    final resume = ref.read(currentResumeProvider(widget.resumeId));
    if (resume != null) {
      final updated = resume.projects.where((p) => p.id != id).toList();
      ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(resume.copyWith(projects: updated));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Project removed'),
            ],
          ),
          backgroundColor: const Color(0xFFEC4899),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FreePlanService.canEditSection('projects')) {
      return const Scaffold(
        body: SafeArea(
          child: UpgradePromptCard(
            featureName: 'premium_sections',
            message: 'Premium feature. Upgrade to edit this section.',
          ),
        ),
      );
    }

    final resume = ref.watch(currentResumeProvider(widget.resumeId));

    if (resume == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final qualityReport = ResumeQualityService.analyzeResume(resume);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Projects'),
      ),
      body: resume.projects.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildScreenHeader(context, resume, qualityReport),
                const SizedBox(height: 20),
                _buildEmptyState(),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: resume.projects.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildScreenHeader(context, resume, qualityReport),
                  );
                }

                final project = resume.projects[index - 1];
                return _ProjectCard(
                  project: project,
                  onEdit: () => _showProjectDialog(project),
                  onDelete: () => _deleteProject(project.id),
                ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showProjectDialog(null),
              icon: const Icon(Iconsax.add),
              label: const Text('Add Project'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.folder_open,
              size: 60,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Projects Added',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Showcase your best projects with outcomes, tools, and links that can survive template changes.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({required this.project, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final technologyCount =
        project.technologies.where((item) => item.trim().isNotEmpty).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.folder_open, color: Color(0xFFEC4899)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(project.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Iconsax.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Iconsax.trash, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                  ],
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EditorStatPill(
                      label: technologyCount > 0
                          ? '$technologyCount technologies'
                          : 'add tools used',
                      icon: Iconsax.code,
                      color: technologyCount > 0
                          ? const Color(0xFFEC4899)
                          : AppColors.warning,
                    ),
                    if ((project.url ?? '').trim().isNotEmpty)
                      const EditorStatPill(
                        label: 'live link included',
                        icon: Iconsax.link,
                        color: Color(0xFF0EA5E9),
                      ),
                  ],
                ),
                if (project.description.isNotEmpty) const SizedBox(height: 12),
                if (project.description.isNotEmpty)
                  Text(project.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
                if (project.technologies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: project.technologies.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFFEC4899), fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                ],
                if (project.url?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Iconsax.link, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(project.url!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectForm extends ConsumerStatefulWidget {
  final String resumeId;
  final Project? existing;

  const _ProjectForm({required this.resumeId, this.existing});

  @override
  ConsumerState<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _techController;
  List<String> _technologies = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    _urlController = TextEditingController(text: widget.existing?.url ?? '');
    _techController = TextEditingController();
    _technologies = List.from(widget.existing?.technologies ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _techController.dispose();
    super.dispose();
  }

  void _addTechnology() {
    if (_techController.text.trim().isNotEmpty) {
      setState(() {
        _technologies.add(_techController.text.trim());
        _techController.clear();
      });
    }
  }

  ResumeModel _buildDraftResume(ResumeModel resume) {
    final hasDraftInput = _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _urlController.text.trim().isNotEmpty ||
        _technologies.isNotEmpty ||
        _techController.text.trim().isNotEmpty;

    if (!hasDraftInput) {
      return resume;
    }

    final draftProject = Project(
      id: widget.existing?.id ?? 'draft-project',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      url: _urlController.text.trim(),
      technologies: [
        ..._technologies,
        if (_techController.text.trim().isNotEmpty) _techController.text.trim(),
      ],
    );

    final updatedProjects = widget.existing != null
        ? resume.projects
            .map((item) => item.id == draftProject.id ? draftProject : item)
            .toList()
        : [...resume.projects, draftProject];

    return resume.copyWith(projects: updatedProjects);
  }

  String? _liveValidationMessage() {
    if (_titleController.text.trim().isEmpty) {
      return 'Give the project a clear name so the preview can anchor it quickly.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Add a short description so this project shows purpose instead of only a title.';
    }
    if (_technologies.isEmpty && _techController.text.trim().isEmpty) {
      return 'Add the tools or stack you used so the project supports skill matching.';
    }
    if (_urlController.text.trim().isEmpty) {
      return 'A link is optional, but a URL makes this project easier to verify in shared resumes.';
    }
    return null;
  }

  void _saveProject() {
    if (_formKey.currentState?.validate() ?? false) {
      final resume = ref.read(currentResumeProvider(widget.resumeId));
      if (resume == null) return;

      final project = Project(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        url: _urlController.text.trim(),
        technologies: _technologies,
      );

      List<Project> updated;
      if (widget.existing != null) {
        updated = resume.projects.map((p) => p.id == project.id ? project : p).toList();
      } else {
        updated = [...resume.projects, project];
      }

      ref.read(currentResumeProvider(widget.resumeId).notifier).updateResume(resume.copyWith(projects: updated));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.existing != null ? 'Project updated' : 'Project added'),
              ],
            ),
            backgroundColor: const Color(0xFFEC4899),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider(widget.resumeId));
    final qualityReport = resume == null
        ? null
        : ResumeQualityService.analyzeResume(_buildDraftResume(resume));
    final liveValidationMessage = _liveValidationMessage();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existing != null ? 'Edit Project' : 'Add Project', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Iconsax.close_circle)),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  EditorIntroCard(
                    title: widget.existing != null
                        ? 'Refine project proof'
                        : 'Add a project that sells your work',
                    subtitle:
                        'Pair a concise outcome statement with the stack and link that back it up. This guidance uses your draft values before save.',
                    icon: Iconsax.folder_open,
                    accentColor: const Color(0xFFEC4899),
                    stats: [
                      EditorIntroStat(
                        label: _technologies.isNotEmpty
                            ? '${_technologies.length} saved technologies'
                            : 'stack not tagged yet',
                        icon: Iconsax.code,
                      ),
                      EditorIntroStat(
                        label: _urlController.text.trim().isNotEmpty
                            ? 'link included'
                            : 'link optional',
                        icon: Iconsax.link,
                      ),
                    ],
                  ),
                  if (qualityReport != null) ...[
                    const SizedBox(height: 16),
                    ResumeQualityPanel(
                      report: qualityReport,
                      title: 'Draft Project Guidance',
                      subtitle:
                          'The score below updates from your in-progress title, description, technologies, and link.',
                      accentColor: const Color(0xFFEC4899),
                      maxSuggestions: 2,
                    ),
                  ],
                  if (liveValidationMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEC4899)
                              .withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Iconsax.info_circle,
                            color: Color(0xFFEC4899),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              liveValidationMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Project Title',
                    hint: 'My Awesome Project',
                    prefixIcon: Iconsax.folder_open,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your project...',
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                  ),
                  CustomTextField(
                    controller: _urlController,
                    label: 'Project URL',
                    hint: 'https://github.com/...',
                    prefixIcon: Iconsax.link,
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _techController,
                          label: 'Technologies',
                          hint: 'React, Node.js...',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(onPressed: _addTechnology, icon: const Icon(Iconsax.add_circle, color: AppColors.primary)),
                    ],
                  ),
                  if (_technologies.isNotEmpty)
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _technologies.asMap().entries.map((e) => Chip(
                        label: Text(e.value),
                        deleteIcon: const Icon(Iconsax.close_circle, size: 18),
                        onDeleted: () => setState(() => _technologies.removeAt(e.key)),
                      )).toList(),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Pinned Save Button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProject,
                child: Text(widget.existing != null ? 'Update Project' : 'Save Project'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
