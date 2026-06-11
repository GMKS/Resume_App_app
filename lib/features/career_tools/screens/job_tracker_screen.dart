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

enum _JobAction { details, edit, addNote, tailor, preview, delete }

enum _JobMetricFilter {
  applied,
  interviews,
  offers,
  rejected,
  saved,
  offerRate,
}

class JobTrackerScreen extends ConsumerStatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  ConsumerState<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends ConsumerState<JobTrackerScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final GlobalKey _tableSectionKey = GlobalKey();

  _JobMetricFilter? _metricFilter;

  @override
  void dispose() {
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
      _metricFilter = null;
    });
  }

  Future<void> _focusTableSection() async {
    final sectionContext = _tableSectionKey.currentContext;
    if (sectionContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  String _metricFilterLabel(_JobMetricFilter filter) {
    switch (filter) {
      case _JobMetricFilter.applied:
        return 'Applied jobs';
      case _JobMetricFilter.interviews:
        return 'Interview jobs';
      case _JobMetricFilter.offers:
        return 'Offer jobs';
      case _JobMetricFilter.rejected:
        return 'Rejected jobs';
      case _JobMetricFilter.saved:
        return 'Saved jobs';
      case _JobMetricFilter.offerRate:
        return 'Offer rate jobs';
    }
  }

  Future<void> _activateMetricFilter(_JobMetricFilter filter) async {
    setState(() {
      _metricFilter = filter;
    });
    await _focusTableSection();
  }

  List<JobApplicationRecord> _applyFilters(List<JobApplicationRecord> jobs) {
    return jobs.where((job) {
      return switch (_metricFilter) {
        null => true,
        _JobMetricFilter.applied => job.status.countsAsApplied,
        _JobMetricFilter.interviews =>
          job.status == JobApplicationStatus.interview,
        _JobMetricFilter.offers => job.status == JobApplicationStatus.offer,
        _JobMetricFilter.rejected =>
          job.status == JobApplicationStatus.rejected,
        _JobMetricFilter.saved => job.status == JobApplicationStatus.saved,
        _JobMetricFilter.offerRate => job.status == JobApplicationStatus.offer,
      };
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
    final activeTableTitle = _metricFilter == null
        ? 'Application Table'
        : _metricFilterLabel(_metricFilter!);

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
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openJobForm(),
                icon: const Icon(Iconsax.add),
                label: const Text('Add New Job'),
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _AnalyticsGrid(
              analytics: analytics,
              onMetricTap: _activateMetricFilter,
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
              key: _tableSectionKey,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTableTitle,
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
                      if (_metricFilter != null) ...[
                        const SizedBox(height: 8),
                        ActionChip(
                          avatar: const Icon(Iconsax.filter, size: 16),
                          label: Text(_metricFilterLabel(_metricFilter!)),
                          onPressed: () {
                            setState(() => _metricFilter = null);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (_metricFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _metricFilter = null);
                    },
                    child: const Text('Show all'),
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
            else
              _TableView(
                jobs: filteredJobs,
                resumesById: resumesById,
                dateFormat: _dateFormat,
                onActionSelected: (job, action) =>
                    _handleJobAction(job, action, resumesById),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({
    required this.analytics,
    required this.onMetricTap,
  });

  final JobTrackerAnalytics analytics;
  final ValueChanged<_JobMetricFilter> onMetricTap;

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
          onTap: () => onMetricTap(_JobMetricFilter.applied),
        ),
        _MetricCard(
          title: 'Interviews',
          value: analytics.interviewsCount.toString(),
          icon: Iconsax.user_tick,
          color: AppColors.warning,
          onTap: () => onMetricTap(_JobMetricFilter.interviews),
        ),
        _MetricCard(
          title: 'Offers',
          value: analytics.offersCount.toString(),
          icon: Iconsax.tick_circle,
          color: AppColors.success,
          onTap: () => onMetricTap(_JobMetricFilter.offers),
        ),
        _MetricCard(
          title: 'Rejected',
          value: analytics.rejectionsCount.toString(),
          icon: Iconsax.close_circle,
          color: AppColors.error,
          onTap: () => onMetricTap(_JobMetricFilter.rejected),
        ),
        _MetricCard(
          title: 'Saved',
          value: analytics.savedCount.toString(),
          icon: Iconsax.archive,
          color: AppColors.primary,
          onTap: () => onMetricTap(_JobMetricFilter.saved),
        ),
        _MetricCard(
          title: 'Offer rate',
          value: '${analytics.conversionRate.toStringAsFixed(1)}%',
          icon: Iconsax.chart_1,
          color: AppColors.secondary,
          onTap: () => onMetricTap(_JobMetricFilter.offerRate),
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
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
          ),
        ),
      ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit job',
                        onPressed: () =>
                            onActionSelected(job, _JobAction.edit),
                        icon: const Icon(Iconsax.edit_2),
                      ),
                      IconButton(
                        tooltip: 'Delete job',
                        onPressed: () =>
                            onActionSelected(job, _JobAction.delete),
                        icon: const Icon(Iconsax.trash),
                        color: AppColors.error,
                      ),
                      PopupMenuButton<_JobAction>(
                        tooltip: 'More job actions',
                        onSelected: (action) => onActionSelected(job, action),
                        itemBuilder: (context) {
                          return const [
                            PopupMenuItem<_JobAction>(
                              value: _JobAction.details,
                              child: Text('View details'),
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
                          ];
                        },
                        icon: const Icon(Iconsax.more),
                      ),
                    ],
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
