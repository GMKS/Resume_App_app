import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../models/job_tracker_models.dart';
import '../services/job_tracker_service.dart';

enum _JobTrackerView { table, kanban }

enum _JobDateFilter { all, last7, last30, last90 }

enum _JobAction { details, edit, addNote, tailor, preview, delete }

class JobTrackerScreen extends ConsumerStatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  ConsumerState<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends ConsumerState<JobTrackerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  JobApplicationStatus? _statusFilter;
  String? _companyFilter;
  String? _roleFilter;
  _JobDateFilter _dateFilter = _JobDateFilter.all;
  _JobTrackerView _view = _JobTrackerView.table;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openJobForm({JobApplicationRecord? existing}) async {
    final service = ref.read(jobTrackerServiceProvider);
    final resumes = [...StorageService.getAllResumes()]
      ..sort((left, right) => left.title.compareTo(right.title));
    final userId = existing?.userId.isNotEmpty == true
        ? existing!.userId
        : await service.currentUserId();
    if (!mounted) {
      return;
    }

    final result = await showModalBottomSheet<JobApplicationRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _JobTrackerFormSheet(
          existing: existing,
          resumes: resumes,
          service: service,
          userId: userId,
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      await ref.read(jobTrackerProvider.notifier).saveJob(result);
      if (!mounted) {
        return;
      }
      _showSnackBar(
        existing == null ? 'Job added to tracker.' : 'Job updated.',
      );
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _deleteJob(JobApplicationRecord job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete job'),
          content:
              Text('Remove ${job.company} - ${job.role} from your tracker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(jobTrackerProvider.notifier).deleteJob(job.jobId);
    if (!mounted) {
      return;
    }
    _showSnackBar('Job removed from tracker.');
  }

  Future<void> _moveJob(
    JobApplicationRecord job,
    JobApplicationStatus nextStatus,
  ) async {
    try {
      await ref
          .read(jobTrackerProvider.notifier)
          .moveJob(job.jobId, nextStatus);
      if (!mounted) {
        return;
      }
      _showSnackBar('${job.company} moved to ${nextStatus.label}.');
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _showAddNoteDialog(JobApplicationRecord job) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add note for ${job.company}'),
          content: TextField(
            controller: noteController,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'What changed?',
              hintText:
                  'Follow-up sent, recruiter replied, salary discussed...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(noteController.text.trim()),
              child: const Text('Save note'),
            ),
          ],
        );
      },
    );
    noteController.dispose();

    if (note == null || note.trim().isEmpty) {
      return;
    }

    await ref
        .read(jobTrackerProvider.notifier)
        .addNote(jobId: job.jobId, note: note);
    if (!mounted) {
      return;
    }
    _showSnackBar('Note added to ${job.company}.');
  }

  void _openJobDetails(
    JobApplicationRecord job,
    Map<String, ResumeModel> resumesById,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _JobDetailsSheet(
          job: job,
          linkedResume:
              job.resumeId == null ? null : resumesById[job.resumeId!],
          dateFormat: _dateFormat,
          onEdit: () {
            Navigator.of(context).pop();
            _openJobForm(existing: job);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteJob(job);
          },
          onAddNote: () {
            Navigator.of(context).pop();
            _showAddNoteDialog(job);
          },
          onTailorResume: () {
            Navigator.of(context).pop();
            _openTailorResume(job);
          },
          onPreviewResume: () {
            Navigator.of(context).pop();
            _openPreview(job);
          },
        );
      },
    );
  }

  void _openTailorResume(JobApplicationRecord job) {
    if (!job.hasResumeLinked) {
      _showSnackBar('Link a resume to this job before tailoring it.',
          isError: true);
      return;
    }

    if (job.jobDescription.trim().isEmpty) {
      _showSnackBar('Add a job description first so the optimizer has context.',
          isError: true);
      return;
    }

    final route = Uri(
      path: '/raoe2',
      queryParameters: <String, String>{
        'resumeId': job.resumeId!,
        'jobDescription': job.jobDescription,
      },
    ).toString();

    context.push(route);
  }

  void _openPreview(JobApplicationRecord job) {
    if (!job.hasResumeLinked) {
      _showSnackBar('This job does not have a linked resume yet.',
          isError: true);
      return;
    }
    context.push('/preview/${job.resumeId!}');
  }

  void _handleJobAction(
    JobApplicationRecord job,
    _JobAction action,
    Map<String, ResumeModel> resumesById,
  ) {
    switch (action) {
      case _JobAction.details:
        _openJobDetails(job, resumesById);
        break;
      case _JobAction.edit:
        _openJobForm(existing: job);
        break;
      case _JobAction.addNote:
        _showAddNoteDialog(job);
        break;
      case _JobAction.tailor:
        _openTailorResume(job);
        break;
      case _JobAction.preview:
        _openPreview(job);
        break;
      case _JobAction.delete:
        _deleteJob(job);
        break;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _companyFilter = null;
      _roleFilter = null;
      _dateFilter = _JobDateFilter.all;
      _searchController.clear();
    });
  }

  List<JobApplicationRecord> _applyFilters(List<JobApplicationRecord> jobs) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    bool matchesDate(JobApplicationRecord job) {
      if (_dateFilter == _JobDateFilter.all) {
        return true;
      }
      final referenceDate = job.appliedDate ?? job.createdAt;
      final duration = now.difference(referenceDate);
      switch (_dateFilter) {
        case _JobDateFilter.all:
          return true;
        case _JobDateFilter.last7:
          return duration.inDays <= 7;
        case _JobDateFilter.last30:
          return duration.inDays <= 30;
        case _JobDateFilter.last90:
          return duration.inDays <= 90;
      }
    }

    return jobs.where((job) {
      final matchesQuery = query.isEmpty ||
          job.company.toLowerCase().contains(query) ||
          job.role.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query) ||
          job.parsedSkills
              .any((skill) => skill.toLowerCase().contains(query)) ||
          job.parsedKeywords
              .any((keyword) => keyword.toLowerCase().contains(query));
      final matchesStatus =
          _statusFilter == null || job.status == _statusFilter;
      final matchesCompany =
          _companyFilter == null || job.company == _companyFilter;
      final matchesRole = _roleFilter == null || job.role == _roleFilter;
      return matchesQuery &&
          matchesStatus &&
          matchesCompany &&
          matchesRole &&
          matchesDate(job);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JobTrackerState>(jobTrackerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSnackBar(next.errorMessage!, isError: true);
          }
        });
      }
    });

    final state = ref.watch(jobTrackerProvider);
    final service = ref.read(jobTrackerServiceProvider);
    final resumes = [...StorageService.getAllResumes()]
      ..sort((left, right) => left.title.compareTo(right.title));
    final resumesById = <String, ResumeModel>{
      for (final resume in resumes) resume.id: resume,
    };
    final filteredJobs = _applyFilters(state.jobs);
    final analytics = service.buildAnalytics(state.jobs);
    final companyOptions = state.jobs
        .map((job) => job.company)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final roleOptions = state.jobs
        .map((job) => job.role)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Job Tracker'),
        actions: [
          IconButton(
            onPressed: _clearFilters,
            tooltip: 'Clear filters',
            icon: const Icon(Iconsax.refresh),
          ),
          IconButton(
            onPressed: () => ref.read(jobTrackerProvider.notifier).load(),
            tooltip: 'Refresh tracker',
            icon: const Icon(Iconsax.repeat),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(jobTrackerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _HeroSummaryCard(
              analytics: analytics,
              onAddJob: () => _openJobForm(),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            _AnalyticsGrid(analytics: analytics),
            const SizedBox(height: 16),
            _FilterPanel(
              searchController: _searchController,
              selectedStatus: _statusFilter,
              selectedCompany: _companyFilter,
              selectedRole: _roleFilter,
              selectedDateFilter: _dateFilter,
              selectedView: _view,
              companyOptions: companyOptions,
              roleOptions: roleOptions,
              onSearchChanged: (_) => setState(() {}),
              onStatusChanged: (status) =>
                  setState(() => _statusFilter = status),
              onCompanyChanged: (company) =>
                  setState(() => _companyFilter = company),
              onRoleChanged: (role) => setState(() => _roleFilter = role),
              onDateFilterChanged: (filter) =>
                  setState(() => _dateFilter = filter),
              onViewChanged: (view) => setState(() => _view = view),
            ),
            if (analytics.upcomingReminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _UpcomingReminderPanel(
                reminders: analytics.upcomingReminders,
                dateFormat: _dateFormat,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _view == _JobTrackerView.table
                            ? 'Application Table'
                            : 'Kanban Pipeline',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filteredJobs.length} of ${state.jobs.length} jobs visible',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openJobForm(),
                  icon: const Icon(Iconsax.add),
                  label: const Text('Add Job'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: AppLoadingState(
                  title: 'Loading job tracker',
                  message: 'Pulling your saved applications and analytics.',
                ),
              )
            else if (state.jobs.isEmpty)
              _EmptyTrackerState(onAddJob: () => _openJobForm())
            else if (filteredJobs.isEmpty)
              _FilteredEmptyState(onReset: _clearFilters)
            else if (_view == _JobTrackerView.table)
              _TableView(
                jobs: filteredJobs,
                resumesById: resumesById,
                dateFormat: _dateFormat,
                onActionSelected: (job, action) =>
                    _handleJobAction(job, action, resumesById),
              )
            else
              _KanbanBoard(
                jobs: filteredJobs,
                resumesById: resumesById,
                dateFormat: _dateFormat,
                service: service,
                onMove: _moveJob,
                onOpenDetails: (job) => _openJobDetails(job, resumesById),
                onAddNote: _showAddNoteDialog,
                onTailor: _openTailorResume,
              ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        minimum: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
              MediaQuery.paddingOf(context).bottom +
              16,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openJobForm(),
          icon: const Icon(Iconsax.add),
          label: const Text('Track Job'),
        ),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.analytics,
    required this.onAddJob,
  });

  final JobTrackerAnalytics analytics;
  final VoidCallback onAddJob;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Iconsax.briefcase, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay on top of every application',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track status, reminders, linked resumes, and follow-ups in one place.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryPill(
                label: 'Total jobs',
                value: analytics.totalJobs.toString(),
              ),
              _SummaryPill(
                label: 'Applications',
                value: analytics.totalApplications.toString(),
              ),
              _SummaryPill(
                label: 'Offers',
                value: analytics.offersCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddJob,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Iconsax.add),
              label: const Text('Add new job'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.analytics});

  final JobTrackerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          title: 'Applied',
          value: analytics.totalApplications.toString(),
          icon: Iconsax.send_1,
          color: AppColors.info,
        ),
        _MetricCard(
          title: 'Interviews',
          value: analytics.interviewsCount.toString(),
          icon: Iconsax.user_tick,
          color: AppColors.warning,
        ),
        _MetricCard(
          title: 'Offers',
          value: analytics.offersCount.toString(),
          icon: Iconsax.tick_circle,
          color: AppColors.success,
        ),
        _MetricCard(
          title: 'Rejected',
          value: analytics.rejectionsCount.toString(),
          icon: Iconsax.close_circle,
          color: AppColors.error,
        ),
        _MetricCard(
          title: 'Saved',
          value: analytics.savedCount.toString(),
          icon: Iconsax.archive,
          color: AppColors.primary,
        ),
        _MetricCard(
          title: 'Offer rate',
          value: '${analytics.conversionRate.toStringAsFixed(1)}%',
          icon: Iconsax.chart_1,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.selectedStatus,
    required this.selectedCompany,
    required this.selectedRole,
    required this.selectedDateFilter,
    required this.selectedView,
    required this.companyOptions,
    required this.roleOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCompanyChanged,
    required this.onRoleChanged,
    required this.onDateFilterChanged,
    required this.onViewChanged,
  });

  final TextEditingController searchController;
  final JobApplicationStatus? selectedStatus;
  final String? selectedCompany;
  final String? selectedRole;
  final _JobDateFilter selectedDateFilter;
  final _JobTrackerView selectedView;
  final List<String> companyOptions;
  final List<String> roleOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<JobApplicationStatus?> onStatusChanged;
  final ValueChanged<String?> onCompanyChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<_JobDateFilter> onDateFilterChanged;
  final ValueChanged<_JobTrackerView> onViewChanged;

  static const double _filterFieldWidth = 220;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters and views',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SegmentedButton<_JobTrackerView>(
                segments: const [
                  ButtonSegment<_JobTrackerView>(
                    value: _JobTrackerView.table,
                    icon: Icon(Iconsax.row_vertical),
                    label: Text('Table'),
                  ),
                  ButtonSegment<_JobTrackerView>(
                    value: _JobTrackerView.kanban,
                    icon: Icon(Iconsax.category),
                    label: Text('Kanban'),
                  ),
                ],
                selected: <_JobTrackerView>{selectedView},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    onViewChanged(selection.first);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.search_normal),
              hintText: 'Search company, role, location, skill, keyword',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusFilter(),
              _buildTextFilter(
                label: 'Company',
                initialValue: selectedCompany,
                allLabel: 'All companies',
                options: companyOptions,
                onChanged: onCompanyChanged,
              ),
              _buildTextFilter(
                label: 'Role',
                initialValue: selectedRole,
                allLabel: 'All roles',
                options: roleOptions,
                onChanged: onRoleChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in _JobDateFilter.values)
                ChoiceChip(
                  label: Text(_dateFilterLabel(filter)),
                  selected: filter == selectedDateFilter,
                  onSelected: (_) => onDateFilterChanged(filter),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateFilterLabel(_JobDateFilter filter) {
    switch (filter) {
      case _JobDateFilter.all:
        return 'All dates';
      case _JobDateFilter.last7:
        return 'Last 7 days';
      case _JobDateFilter.last30:
        return 'Last 30 days';
      case _JobDateFilter.last90:
        return 'Last 90 days';
    }
  }

  Widget _buildStatusFilter() {
    final labels = <String>[
      'All statuses',
      ...JobApplicationStatus.values.map((status) => status.label),
    ];

    return SizedBox(
      width: _filterFieldWidth,
      child: DropdownButtonFormField<JobApplicationStatus?>(
        initialValue: selectedStatus,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Status'),
        items: <DropdownMenuItem<JobApplicationStatus?>>[
          DropdownMenuItem<JobApplicationStatus?>(
            value: null,
            child: _dropdownLabel('All statuses'),
          ),
          ...JobApplicationStatus.values.map(
            (status) => DropdownMenuItem<JobApplicationStatus?>(
              value: status,
              child: _dropdownLabel(status.label),
            ),
          ),
        ],
        selectedItemBuilder: (context) =>
            labels.map(_selectedDropdownLabel).toList(),
        onChanged: onStatusChanged,
      ),
    );
  }

  Widget _buildTextFilter({
    required String label,
    required String? initialValue,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final labels = <String>[allLabel, ...options];

    return SizedBox(
      width: _filterFieldWidth,
      child: DropdownButtonFormField<String?>(
        initialValue: initialValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: _dropdownLabel(allLabel),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String?>(
              value: option,
              child: _dropdownLabel(option),
            ),
          ),
        ],
        selectedItemBuilder: (context) =>
            labels.map(_selectedDropdownLabel).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownLabel(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _selectedDropdownLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _dropdownLabel(text),
    );
  }
}

class _UpcomingReminderPanel extends StatelessWidget {
  const _UpcomingReminderPanel({
    required this.reminders,
    required this.dateFormat,
  });

  final List<JobReminderItem> reminders;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming reminders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _statusColor(reminder.status)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        reminder.kind == 'Interview'
                            ? Iconsax.user
                            : Iconsax.calendar_1,
                        size: 18,
                        color: _statusColor(reminder.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reminder.company} · ${reminder.role}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reminder.kind} on ${dateFormat.format(reminder.date)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: reminder.status),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({
    required this.jobs,
    required this.resumesById,
    required this.dateFormat,
    required this.onActionSelected,
  });

  final List<JobApplicationRecord> jobs;
  final Map<String, ResumeModel> resumesById;
  final DateFormat dateFormat;
  final void Function(JobApplicationRecord job, _JobAction action)
      onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          dataRowMinHeight: 78,
          dataRowMaxHeight: 90,
          columns: const [
            DataColumn(label: Text('Company / Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Linked Resume')),
            DataColumn(label: Text('Applied')),
            DataColumn(label: Text('Updated')),
            DataColumn(label: Text('Actions')),
          ],
          rows: jobs.map((job) {
            final linkedResume =
                job.resumeId == null ? null : resumesById[job.resumeId!];
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          job.company,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.role,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (job.location.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            job.location,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                DataCell(_StatusBadge(status: job.status)),
                DataCell(
                  SizedBox(
                    width: 250,
                    child: Text(
                      linkedResume?.title ?? 'Not linked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(job.appliedDate == null
                      ? 'Not applied'
                      : dateFormat.format(job.appliedDate!)),
                ),
                DataCell(Text(dateFormat.format(job.updatedAt))),
                DataCell(
                  PopupMenuButton<_JobAction>(
                    onSelected: (action) => onActionSelected(job, action),
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.details,
                          child: Text('View details'),
                        ),
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.edit,
                          child: Text('Edit job'),
                        ),
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.addNote,
                          child: Text('Add note'),
                        ),
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.tailor,
                          child: Text('Tailor linked resume'),
                        ),
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.preview,
                          child: Text('Open preview'),
                        ),
                        PopupMenuItem<_JobAction>(
                          value: _JobAction.delete,
                          child: Text('Delete'),
                        ),
                      ];
                    },
                    icon: const Icon(Iconsax.more),
                  ),
                ),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.jobs,
    required this.resumesById,
    required this.dateFormat,
    required this.service,
    required this.onMove,
    required this.onOpenDetails,
    required this.onAddNote,
    required this.onTailor,
  });

  final List<JobApplicationRecord> jobs;
  final Map<String, ResumeModel> resumesById;
  final DateFormat dateFormat;
  final JobTrackerService service;
  final Future<void> Function(
      JobApplicationRecord job, JobApplicationStatus nextStatus) onMove;
  final void Function(JobApplicationRecord job) onOpenDetails;
  final Future<void> Function(JobApplicationRecord job) onAddNote;
  final void Function(JobApplicationRecord job) onTailor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: JobApplicationStatus.values.map((status) {
            final statusJobs = jobs
                .where((job) => job.status == status)
                .toList(growable: false);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 320,
                child: DragTarget<JobApplicationRecord>(
                  onWillAcceptWithDetails: (details) {
                    final job = details.data;
                    return service.canTransition(job.status, status);
                  },
                  onAcceptWithDetails: (details) =>
                      onMove(details.data, status),
                  builder: (context, candidateData, rejectedData) {
                    final isActive = candidateData.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _statusColor(status).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? _statusColor(status)
                              : AppColors.border,
                          width: isActive ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _StatusBadge(status: status),
                              const SizedBox(width: 10),
                              Text(
                                statusJobs.length.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: statusJobs.isEmpty
                                ? Center(
                                    child: Text(
                                      'Drag jobs here',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: statusJobs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final job = statusJobs[index];
                                      final linkedResume = job.resumeId == null
                                          ? null
                                          : resumesById[job.resumeId!];
                                      final card = _KanbanJobCard(
                                        job: job,
                                        linkedResume: linkedResume,
                                        dateFormat: dateFormat,
                                        onTap: () => onOpenDetails(job),
                                        onAddNote: () => onAddNote(job),
                                        onTailor: () => onTailor(job),
                                      );
                                      return LongPressDraggable<
                                          JobApplicationRecord>(
                                        data: job,
                                        axis: Axis.horizontal,
                                        delay:
                                            const Duration(milliseconds: 140),
                                        maxSimultaneousDrags: 1,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child:
                                              SizedBox(width: 300, child: card),
                                        ),
                                        childWhenDragging:
                                            Opacity(opacity: 0.32, child: card),
                                        child: card,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.04, end: 0);
  }
}

class _KanbanJobCard extends StatelessWidget {
  const _KanbanJobCard({
    required this.job,
    required this.linkedResume,
    required this.dateFormat,
    required this.onTap,
    required this.onAddNote,
    required this.onTailor,
  });

  final JobApplicationRecord job;
  final ResumeModel? linkedResume;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onAddNote;
  final VoidCallback onTailor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.company,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.role,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            if (job.location.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Iconsax.location,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (linkedResume != null)
                  _InlineTag(
                      icon: Iconsax.document_text, label: linkedResume!.title),
                if (job.followUpDate != null)
                  _InlineTag(
                    icon: Iconsax.calendar_1,
                    label: 'Follow-up ${dateFormat.format(job.followUpDate!)}',
                  ),
                if (job.interviewDate != null)
                  _InlineTag(
                    icon: Iconsax.clock,
                    label: 'Interview ${dateFormat.format(job.interviewDate!)}',
                  ),
              ],
            ),
            if (job.parsedSkills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.parsedSkills
                    .take(4)
                    .map((skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact))
                    .toList(growable: false),
              ),
            ],
            if (job.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                job.notes.split('\n').last,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Iconsax.note_1, size: 16),
                  label: const Text('Note'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTailor,
                    icon: const Icon(Iconsax.magicpen, size: 16),
                    label: const Text('Tailor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrackerState extends StatelessWidget {
  const _EmptyTrackerState({required this.onAddJob});

  final VoidCallback onAddJob;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.briefcase, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'No jobs tracked yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first role to start tracking progress, reminders, notes, and linked resumes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddJob,
            icon: const Icon(Iconsax.add),
            label: const Text('Track first job'),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.filter_search, size: 40, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'No jobs match these filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the filters or clear them to see the rest of your pipeline.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}

class _JobDetailsSheet extends StatelessWidget {
  const _JobDetailsSheet({
    required this.job,
    required this.linkedResume,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onAddNote,
    required this.onTailorResume,
    required this.onPreviewResume,
  });

  final JobApplicationRecord job;
  final ResumeModel? linkedResume;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddNote;
  final VoidCallback onTailorResume;
  final VoidCallback onPreviewResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.company,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.role,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (job.location.trim().isNotEmpty)
                      _InlineTag(icon: Iconsax.location, label: job.location),
                    if (job.appliedDate != null)
                      _InlineTag(
                        icon: Iconsax.calendar,
                        label: 'Applied ${dateFormat.format(job.appliedDate!)}',
                      ),
                    if (linkedResume != null)
                      _InlineTag(
                        icon: Iconsax.document_text,
                        label: linkedResume!.title,
                      ),
                    if (job.salary?.trim().isNotEmpty == true)
                      _InlineTag(icon: Iconsax.money, label: job.salary!),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Iconsax.edit_2),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onAddNote,
                      icon: const Icon(Iconsax.note_1),
                      label: const Text('Add Note'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onTailorResume,
                      icon: const Icon(Iconsax.magicpen),
                      label: const Text('Tailor Resume'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onPreviewResume,
                      icon: const Icon(Iconsax.document_download),
                      label: const Text('Preview Resume'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Iconsax.trash, color: AppColors.error),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                if (job.jobDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Job Description',
                    child: Text(
                      job.jobDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (job.parsedSkills.isNotEmpty ||
                    job.parsedKeywords.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Parsed Insights',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (job.parsedSkills.isNotEmpty) ...[
                          Text(
                            'Skills',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: job.parsedSkills
                                .map((skill) => Chip(label: Text(skill)))
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (job.parsedKeywords.isNotEmpty) ...[
                          Text(
                            'Keywords',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: job.parsedKeywords
                                .map((keyword) => Chip(label: Text(keyword)))
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Notes',
                  child: Text(
                    job.notes.trim().isEmpty
                        ? 'No notes added yet.'
                        : job.notes,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: job.notes.trim().isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Activity Timeline',
                  child: job.activities.isEmpty
                      ? Text(
                          'No activity recorded yet.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        )
                      : Column(
                          children: job.activities.reversed.map((activity) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity.message,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateFormat.format(activity.createdAt),
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
                                ],
                              ),
                            );
                          }).toList(growable: false),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _JobTrackerFormSheet extends StatefulWidget {
  const _JobTrackerFormSheet({
    required this.existing,
    required this.resumes,
    required this.service,
    required this.userId,
  });

  final JobApplicationRecord? existing;
  final List<ResumeModel> resumes;
  final JobTrackerService service;
  final String userId;

  @override
  State<_JobTrackerFormSheet> createState() => _JobTrackerFormSheetState();
}

class _JobTrackerFormSheetState extends State<_JobTrackerFormSheet> {
  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final TextEditingController _locationController;
  late final TextEditingController _jobLinkController;
  late final TextEditingController _salaryController;
  late final TextEditingController _notesController;
  late final TextEditingController _jobDescriptionController;

  late JobApplicationStatus _status;
  late List<String> _parsedSkills;
  late List<String> _parsedKeywords;
  String? _selectedResumeId;
  DateTime? _followUpDate;
  DateTime? _interviewDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _companyController = TextEditingController(text: existing?.company ?? '');
    _roleController = TextEditingController(text: existing?.role ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _jobLinkController = TextEditingController(text: existing?.jobLink ?? '');
    _salaryController = TextEditingController(text: existing?.salary ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _jobDescriptionController =
        TextEditingController(text: existing?.jobDescription ?? '');
    _status = existing?.status ?? JobApplicationStatus.saved;
    _selectedResumeId = existing?.resumeId;
    _followUpDate = existing?.followUpDate;
    _interviewDate = existing?.interviewDate;
    _parsedSkills = [...(existing?.parsedSkills ?? const <String>[])];
    _parsedKeywords = [...(existing?.parsedKeywords ?? const <String>[])];
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _jobLinkController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  void _parseJobDescription() {
    final insights =
        widget.service.parseJobDescription(_jobDescriptionController.text);
    setState(() {
      if (_roleController.text.trim().isEmpty && insights.role.isNotEmpty) {
        _roleController.text = insights.role;
      }
      _parsedSkills = insights.skills;
      _parsedKeywords = insights.keywords;
    });

    if (insights.skills.isEmpty &&
        insights.keywords.isEmpty &&
        insights.role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No useful signals were extracted from the job description.')),
      );
    }
  }

  void _guessCompanyFromLink() {
    final raw = _jobLinkController.text.trim();
    final uri = Uri.tryParse(raw);
    final host = uri?.host ?? '';
    if (host.isEmpty) {
      return;
    }

    final segments = host.replaceFirst('www.', '').split('.');
    if (segments.isEmpty || segments.first.trim().isEmpty) {
      return;
    }

    final guessed = segments.first
        .split(RegExp(r'[-_]'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    if (guessed.isNotEmpty) {
      setState(() {
        if (_companyController.text.trim().isEmpty) {
          _companyController.text = guessed;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_companyController.text.trim().isEmpty ||
        _roleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company and role are required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final draft = widget.service.buildDraft(
      userId: widget.userId,
      existingId: widget.existing?.jobId,
      company: _companyController.text,
      role: _roleController.text,
      location: _locationController.text,
      status: _status,
      notes: _notesController.text,
      jobDescription: _jobDescriptionController.text,
      parsedSkills: _parsedSkills,
      parsedKeywords: _parsedKeywords,
      resumeId: _selectedResumeId,
      jobLink: _jobLinkController.text,
      salary: _salaryController.text,
      appliedDate: widget.existing?.appliedDate,
      followUpDate: _followUpDate,
      interviewDate: _interviewDate,
      createdAt: widget.existing?.createdAt,
      updatedAt: DateTime.now(),
      activities: widget.existing?.activities ?? const <JobActivityItem>[],
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final availableStatuses = widget.existing == null
        ? JobApplicationStatus.values
        : JobApplicationStatus.values
            .where((status) =>
                widget.service.canTransition(widget.existing!.status, status))
            .toList(growable: false);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.existing == null
                      ? 'Track a new job'
                      : 'Edit tracked job',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep job details, reminders, notes, and linked resume context together.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roleController,
                  decoration:
                      const InputDecoration(labelText: 'Role / Job Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<JobApplicationStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: availableStatuses
                      .map(
                        (status) => DropdownMenuItem<JobApplicationStatus>(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) {
                    if (status != null) {
                      setState(() => _status = status);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedResumeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Linked Resume'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'No linked resume',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...widget.resumes.map(
                      (resume) => DropdownMenuItem<String?>(
                        value: resume.id,
                        child: Text(
                          resume.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  selectedItemBuilder: (context) => <Widget>[
                    const Text(
                      'No linked resume',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ...widget.resumes.map(
                      (resume) => Text(
                        resume.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedResumeId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _jobLinkController,
                        decoration:
                            const InputDecoration(labelText: 'Job Link'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _guessCompanyFromLink,
                      child: const Text('Guess company'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _salaryController,
                  decoration:
                      const InputDecoration(labelText: 'Salary / Compensation'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Follow-up reminder',
                        value: _followUpDate,
                        onPick: () => _pickDate(
                          initialDate: _followUpDate,
                          onPicked: (value) => _followUpDate = value,
                        ),
                        onClear: _followUpDate == null
                            ? null
                            : () => setState(() => _followUpDate = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Interview reminder',
                        value: _interviewDate,
                        onPick: () => _pickDate(
                          initialDate: _interviewDate,
                          onPicked: (value) => _interviewDate = value,
                        ),
                        onClear: _interviewDate == null
                            ? null
                            : () => setState(() => _interviewDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _jobDescriptionController,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Job Description',
                    alignLabelWithHint: true,
                    hintText:
                        'Paste the job description to extract a role, skills, and keywords.',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _parseJobDescription,
                      icon: const Icon(Iconsax.scan),
                      label: const Text('Parse description'),
                    ),
                    if (_parsedSkills.isNotEmpty || _parsedKeywords.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _parsedSkills = <String>[];
                            _parsedKeywords = <String>[];
                          });
                        },
                        icon: const Icon(Iconsax.close_circle),
                        label: const Text('Clear parsed data'),
                      ),
                  ],
                ),
                if (_parsedSkills.isNotEmpty || _parsedKeywords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (_parsedSkills.isNotEmpty) ...[
                    Text(
                      'Skills',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _parsedSkills
                          .map((skill) => Chip(label: Text(skill)))
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_parsedKeywords.isNotEmpty) ...[
                    Text(
                      'Keywords',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _parsedKeywords
                          .map((keyword) => Chip(label: Text(keyword)))
                          .toList(growable: false),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(_isSubmitting ? 'Saving...' : 'Save Job'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Iconsax.calendar_1)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Iconsax.close_circle),
                ),
        ),
        child: Text(
          value == null ? 'Select date' : formatter.format(value!),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final JobApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(JobApplicationStatus status) {
  switch (status) {
    case JobApplicationStatus.saved:
      return AppColors.primary;
    case JobApplicationStatus.applied:
      return AppColors.info;
    case JobApplicationStatus.interview:
      return AppColors.warning;
    case JobApplicationStatus.offer:
      return AppColors.success;
    case JobApplicationStatus.rejected:
      return AppColors.error;
  }
}

IconData _statusIcon(JobApplicationStatus status) {
  switch (status) {
    case JobApplicationStatus.saved:
      return Iconsax.archive;
    case JobApplicationStatus.applied:
      return Iconsax.send_1;
    case JobApplicationStatus.interview:
      return Iconsax.user_tick;
    case JobApplicationStatus.offer:
      return Iconsax.tick_circle;
    case JobApplicationStatus.rejected:
      return Iconsax.close_circle;
  }
}
