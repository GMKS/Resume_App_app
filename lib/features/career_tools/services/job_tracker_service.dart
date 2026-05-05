import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_sync_service.dart';
import '../models/job_tracker_models.dart';

class DuplicateJobApplicationException implements Exception {
  DuplicateJobApplicationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidJobStatusTransitionException implements Exception {
  InvalidJobStatusTransitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JobTrackerState {
  const JobTrackerState({
    required this.isLoading,
    required this.jobs,
    this.errorMessage,
  });

  final bool isLoading;
  final List<JobApplicationRecord> jobs;
  final String? errorMessage;

  JobTrackerState copyWith({
    bool? isLoading,
    List<JobApplicationRecord>? jobs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JobTrackerState(
      isLoading: isLoading ?? this.isLoading,
      jobs: jobs ?? this.jobs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const JobTrackerState initial = JobTrackerState(
    isLoading: true,
    jobs: <JobApplicationRecord>[],
  );
}

class JobTrackerService {
  const JobTrackerService();

  static const String _storageKeyPrefix = 'job_tracker_entries_';
  static const String _localFallbackKey = '${_storageKeyPrefix}local';
  static const Uuid _uuid = Uuid();

  static const Map<JobApplicationStatus, Set<JobApplicationStatus>>
      _validTransitions = <JobApplicationStatus, Set<JobApplicationStatus>>{
    JobApplicationStatus.saved: <JobApplicationStatus>{
      JobApplicationStatus.saved,
      JobApplicationStatus.applied,
      JobApplicationStatus.rejected,
    },
    JobApplicationStatus.applied: <JobApplicationStatus>{
      JobApplicationStatus.applied,
      JobApplicationStatus.interview,
      JobApplicationStatus.rejected,
    },
    JobApplicationStatus.interview: <JobApplicationStatus>{
      JobApplicationStatus.interview,
      JobApplicationStatus.offer,
      JobApplicationStatus.rejected,
    },
    JobApplicationStatus.offer: <JobApplicationStatus>{
      JobApplicationStatus.offer,
      JobApplicationStatus.rejected,
    },
    JobApplicationStatus.rejected: <JobApplicationStatus>{
      JobApplicationStatus.rejected,
    },
  };

  Future<String> _storageKey() async {
    final userId = await SupabaseSyncService.currentUserId;
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return _localFallbackKey;
    }
    return '$_storageKeyPrefix$normalized';
  }

  Future<List<String>> _storageKeysForRead() async {
    final primary = await _storageKey();
    if (primary == _localFallbackKey) {
      return const <String>[_localFallbackKey];
    }
    return <String>[primary, _localFallbackKey];
  }

  Future<List<String>> _storageKeysForWrite() async {
    final primary = await _storageKey();
    if (primary == _localFallbackKey) {
      return const <String>[_localFallbackKey];
    }
    return <String>[primary, _localFallbackKey];
  }

  Future<String> currentUserId() {
    return SupabaseSyncService.currentUserId;
  }

  Future<List<JobApplicationRecord>> loadJobs() async {
    final keys = await _storageKeysForRead();
    for (final key in keys) {
      final raw = StorageService.prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          continue;
        }

        final jobs = decoded
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
            .map(JobApplicationRecord.fromMap)
            .toList(growable: false)
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

        if (jobs.isEmpty) {
          continue;
        }

        return jobs;
      } catch (_) {
        continue;
      }
    }

    return const <JobApplicationRecord>[];
  }

  Future<void> persistJobs(List<JobApplicationRecord> jobs) async {
    final keys = await _storageKeysForWrite();
    final payload = jobs.map((job) => job.toMap()).toList(growable: false);
    final encoded = jsonEncode(payload);
    for (final key in keys) {
      await StorageService.prefs.setString(key, encoded);
    }
  }

  bool canTransition(
    JobApplicationStatus from,
    JobApplicationStatus to,
  ) {
    final allowed = _validTransitions[from] ?? const <JobApplicationStatus>{};
    return allowed.contains(to);
  }

  JobApplicationRecord buildDraft({
    required String userId,
    required String company,
    required String role,
    required String location,
    required JobApplicationStatus status,
    required String notes,
    required String jobDescription,
    required List<String> parsedSkills,
    required List<String> parsedKeywords,
    String? existingId,
    String? resumeId,
    String? jobLink,
    String? salary,
    DateTime? appliedDate,
    DateTime? followUpDate,
    DateTime? interviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<JobActivityItem> activities = const <JobActivityItem>[],
  }) {
    final now = DateTime.now();
    final effectiveAppliedDate = status.countsAsApplied
        ? (appliedDate ?? now)
        : appliedDate;

    return JobApplicationRecord(
      jobId: existingId ?? _uuid.v4(),
      userId: userId,
      company: company.trim(),
      role: role.trim(),
      location: location.trim(),
      status: status,
      appliedDate: effectiveAppliedDate,
      resumeId: resumeId?.trim().isEmpty == true ? null : resumeId?.trim(),
      jobLink: jobLink?.trim().isEmpty == true ? null : jobLink?.trim(),
      salary: salary?.trim().isEmpty == true ? null : salary?.trim(),
      notes: notes.trim(),
      jobDescription: jobDescription.trim(),
      parsedSkills: _dedupeStrings(parsedSkills),
      parsedKeywords: _dedupeStrings(parsedKeywords),
      followUpDate: followUpDate,
      interviewDate: interviewDate,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      activities: activities,
    );
  }

  List<JobApplicationRecord> insertOrUpdate({
    required List<JobApplicationRecord> jobs,
    required JobApplicationRecord candidate,
  }) {
    _assertNoDuplicate(jobs, candidate);

    final existingIndex = jobs.indexWhere((job) => job.jobId == candidate.jobId);
    if (existingIndex == -1) {
      final created = candidate.copyWith(
        activities: <JobActivityItem>[
          JobActivityItem(
            id: _uuid.v4(),
            type: 'created',
            message: 'Added ${candidate.company} - ${candidate.role}',
            createdAt: candidate.createdAt,
          ),
          ...candidate.activities,
        ],
      );
      final updated = <JobApplicationRecord>[created, ...jobs]
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return updated;
    }

    final existing = jobs[existingIndex];
    if (!canTransition(existing.status, candidate.status)) {
      throw InvalidJobStatusTransitionException(
        'Cannot move ${existing.status.label} directly to ${candidate.status.label}.',
      );
    }

    final newActivities = <JobActivityItem>[
      ...existing.activities,
      ..._buildChangeActivities(existing, candidate),
    ];

    final updatedRecord = candidate.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      activities: newActivities,
      appliedDate: candidate.status.countsAsApplied
          ? (candidate.appliedDate ?? existing.appliedDate ?? DateTime.now())
          : candidate.appliedDate,
    );

    final updatedJobs = [...jobs]
      ..[existingIndex] = updatedRecord
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return updatedJobs;
  }

  List<JobApplicationRecord> deleteJob({
    required List<JobApplicationRecord> jobs,
    required String jobId,
  }) {
    return jobs.where((job) => job.jobId != jobId).toList(growable: false);
  }

  List<JobApplicationRecord> updateStatus({
    required List<JobApplicationRecord> jobs,
    required String jobId,
    required JobApplicationStatus nextStatus,
  }) {
    final index = jobs.indexWhere((job) => job.jobId == jobId);
    if (index == -1) {
      return jobs;
    }
    final existing = jobs[index];
    if (!canTransition(existing.status, nextStatus)) {
      throw InvalidJobStatusTransitionException(
        'Cannot move ${existing.status.label} directly to ${nextStatus.label}.',
      );
    }

    final updated = existing.copyWith(
      status: nextStatus,
      appliedDate: nextStatus.countsAsApplied
          ? (existing.appliedDate ?? DateTime.now())
          : existing.appliedDate,
      updatedAt: DateTime.now(),
      activities: <JobActivityItem>[
        ...existing.activities,
        JobActivityItem(
          id: _uuid.v4(),
          type: 'status_change',
          message:
              'Status changed from ${existing.status.label} to ${nextStatus.label}',
          createdAt: DateTime.now(),
        ),
      ],
    );

    final updatedJobs = [...jobs]
      ..[index] = updated
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return updatedJobs;
  }

  List<JobApplicationRecord> addNote({
    required List<JobApplicationRecord> jobs,
    required String jobId,
    required String note,
  }) {
    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty) {
      return jobs;
    }

    final index = jobs.indexWhere((job) => job.jobId == jobId);
    if (index == -1) {
      return jobs;
    }

    final existing = jobs[index];
    final combinedNotes = existing.notes.trim().isEmpty
        ? trimmedNote
        : '${existing.notes.trim()}\n$trimmedNote';

    final updated = existing.copyWith(
      notes: combinedNotes,
      updatedAt: DateTime.now(),
      activities: <JobActivityItem>[
        ...existing.activities,
        JobActivityItem(
          id: _uuid.v4(),
          type: 'note',
          message: trimmedNote,
          createdAt: DateTime.now(),
        ),
      ],
    );

    final updatedJobs = [...jobs]
      ..[index] = updated
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return updatedJobs;
  }

  List<JobApplicationRecord> mergeByMostRecent({
    required List<JobApplicationRecord> localJobs,
    required List<JobApplicationRecord> cloudJobs,
  }) {
    final merged = <String, JobApplicationRecord>{
      for (final job in localJobs) job.jobId: job,
    };

    for (final job in cloudJobs) {
      final existing = merged[job.jobId];
      if (existing == null || job.updatedAt.isAfter(existing.updatedAt)) {
        merged[job.jobId] = job;
      }
    }

    final jobs = merged.values.toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return jobs;
  }

  JobDescriptionInsights parseJobDescription(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return const JobDescriptionInsights(role: '', skills: <String>[], keywords: <String>[]);
    }

    final lower = text.toLowerCase();
    const knownSkills = <String>[
      'flutter',
      'dart',
      'firebase',
      'sql',
      'python',
      'java',
      'javascript',
      'typescript',
      'selenium',
      'cypress',
      'playwright',
      'api',
      'rest',
      'automation',
      'testing',
      'qa',
      'git',
      'agile',
      'scrum',
      'aws',
      'azure',
      'docker',
      'kubernetes',
      'ci/cd',
      'leadership',
      'communication',
      'security',
      'mobile',
      'ui',
      'ux',
    ];

    final skills = knownSkills
        .where((skill) => lower.contains(skill))
        .map((skill) => skill.toUpperCase() == 'QA'
            ? 'QA'
            : skill[0].toUpperCase() + skill.substring(1))
        .toList(growable: false);

    const rolePatterns = <String>[
      'software engineer',
      'automation tester',
      'automation test engineer',
      'qa engineer',
      'quality engineer',
      'mobile developer',
      'flutter developer',
      'product manager',
      'data analyst',
      'backend engineer',
      'frontend engineer',
      'full stack developer',
      'devops engineer',
      'designer',
    ];

    String role = '';
    for (final pattern in rolePatterns) {
      if (lower.contains(pattern)) {
        role = pattern
            .split(' ')
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
        break;
      }
    }

    if (role.isEmpty) {
      final firstSentence = text.split(RegExp(r'[.!?\n]')).first.trim();
      final candidates = firstSentence
          .split(RegExp(r'\s+'))
          .take(5)
          .join(' ')
          .trim();
      role = candidates.length > 4 ? candidates : '';
    }

    final keywords = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 3 && !_keywordStopWords.contains(token))
        .toSet()
        .take(10)
        .map((token) => token[0].toUpperCase() + token.substring(1))
        .toList(growable: false);

    return JobDescriptionInsights(
      role: role,
      skills: skills,
      keywords: keywords,
    );
  }

  JobTrackerAnalytics buildAnalytics(List<JobApplicationRecord> jobs) {
    final sortedReminders = buildUpcomingReminders(jobs)
      ..sort((left, right) => left.date.compareTo(right.date));
    final totalApplications = jobs.where((job) => job.status.countsAsApplied).length;
    final interviewsCount =
        jobs.where((job) => job.status == JobApplicationStatus.interview).length;
    final offersCount =
        jobs.where((job) => job.status == JobApplicationStatus.offer).length;
    final rejectionsCount =
        jobs.where((job) => job.status == JobApplicationStatus.rejected).length;
    final savedCount =
        jobs.where((job) => job.status == JobApplicationStatus.saved).length;

    final conversionRate = totalApplications == 0
        ? 0.0
        : (offersCount / totalApplications) * 100;

    return JobTrackerAnalytics(
      totalJobs: jobs.length,
      totalApplications: totalApplications,
      interviewsCount: interviewsCount,
      offersCount: offersCount,
      rejectionsCount: rejectionsCount,
      savedCount: savedCount,
      conversionRate: conversionRate,
      upcomingReminders: sortedReminders.take(5).toList(growable: false),
    );
  }

  List<JobReminderItem> buildUpcomingReminders(List<JobApplicationRecord> jobs) {
    final now = DateTime.now();
    final reminders = <JobReminderItem>[];
    for (final job in jobs) {
      if (job.followUpDate != null && !job.followUpDate!.isBefore(now.subtract(const Duration(days: 1)))) {
        reminders.add(JobReminderItem(
          jobId: job.jobId,
          company: job.company,
          role: job.role,
          kind: 'Follow-up',
          date: job.followUpDate!,
          status: job.status,
        ));
      }
      if (job.interviewDate != null && !job.interviewDate!.isBefore(now.subtract(const Duration(days: 1)))) {
        reminders.add(JobReminderItem(
          jobId: job.jobId,
          company: job.company,
          role: job.role,
          kind: 'Interview',
          date: job.interviewDate!,
          status: job.status,
        ));
      }
    }
    return reminders;
  }

  void _assertNoDuplicate(
    List<JobApplicationRecord> jobs,
    JobApplicationRecord candidate,
  ) {
    final exists = jobs.any(
      (job) => job.jobId != candidate.jobId &&
          job.normalizedCompany == candidate.normalizedCompany &&
          job.normalizedRole == candidate.normalizedRole,
    );

    if (exists) {
      throw DuplicateJobApplicationException(
        'A job for ${candidate.company} - ${candidate.role} already exists.',
      );
    }
  }

  List<JobActivityItem> _buildChangeActivities(
    JobApplicationRecord existing,
    JobApplicationRecord candidate,
  ) {
    final now = DateTime.now();
    final activities = <JobActivityItem>[];
    if (existing.status != candidate.status) {
      activities.add(JobActivityItem(
        id: _uuid.v4(),
        type: 'status_change',
        message:
            'Status changed from ${existing.status.label} to ${candidate.status.label}',
        createdAt: now,
      ));
    }
    if (existing.resumeId != candidate.resumeId && candidate.resumeId != null) {
      activities.add(JobActivityItem(
        id: _uuid.v4(),
        type: 'resume_linked',
        message: 'Linked a resume to this job.',
        createdAt: now,
      ));
    }
    if (existing.notes.trim() != candidate.notes.trim() && candidate.notes.trim().isNotEmpty) {
      activities.add(JobActivityItem(
        id: _uuid.v4(),
        type: 'note',
        message: 'Updated notes for this application.',
        createdAt: now,
      ));
    }
    if (existing.jobDescription.trim() != candidate.jobDescription.trim() &&
        candidate.jobDescription.trim().isNotEmpty) {
      activities.add(JobActivityItem(
        id: _uuid.v4(),
        type: 'job_description',
        message: 'Updated the job description and extracted keywords.',
        createdAt: now,
      ));
    }
    return activities;
  }

  static List<String> _dedupeStrings(List<String> input) {
    final seen = <String>{};
    final values = <String>[];
    for (final entry in input) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        values.add(trimmed);
      }
    }
    return values;
  }

  static const Set<String> _keywordStopWords = <String>{
    'with',
    'that',
    'this',
    'from',
    'have',
    'strong',
    'their',
    'will',
    'into',
    'about',
    'looking',
    'skills',
    'experience',
    'professional',
    'role',
    'required',
    'preferred',
    'using',
    'years',
    'work',
    'team',
    'teams',
  };
}

final jobTrackerServiceProvider = Provider<JobTrackerService>(
  (ref) => const JobTrackerService(),
);

final jobTrackerProvider =
    StateNotifierProvider<JobTrackerNotifier, JobTrackerState>(
  (ref) => JobTrackerNotifier(ref.read(jobTrackerServiceProvider))..load(),
);

class JobTrackerNotifier extends StateNotifier<JobTrackerState> {
  JobTrackerNotifier(this._service) : super(JobTrackerState.initial);

  final JobTrackerService _service;

  Future<List<JobApplicationRecord>> _latestJobs() async {
    final persisted = await _service.loadJobs();
    return persisted.isEmpty ? state.jobs : persisted;
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobs = await _service.loadJobs();
      state = state.copyWith(isLoading: false, jobs: jobs, clearError: true);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> saveJob(JobApplicationRecord draft) async {
    final currentJobs = await _latestJobs();
    final updated = _service.insertOrUpdate(jobs: currentJobs, candidate: draft);
    await _service.persistJobs(updated);
    state = state.copyWith(jobs: updated, clearError: true);
  }

  Future<void> deleteJob(String jobId) async {
    final currentJobs = await _latestJobs();
    final updated = _service.deleteJob(jobs: currentJobs, jobId: jobId);
    await _service.persistJobs(updated);
    state = state.copyWith(jobs: updated, clearError: true);
  }

  Future<void> moveJob(String jobId, JobApplicationStatus status) async {
    final currentJobs = await _latestJobs();
    final updated = _service.updateStatus(
      jobs: currentJobs,
      jobId: jobId,
      nextStatus: status,
    );
    await _service.persistJobs(updated);
    state = state.copyWith(jobs: updated, clearError: true);
  }

  Future<void> addNote({required String jobId, required String note}) async {
    final currentJobs = await _latestJobs();
    final updated = _service.addNote(
      jobs: currentJobs,
      jobId: jobId,
      note: note,
    );
    await _service.persistJobs(updated);
    state = state.copyWith(jobs: updated, clearError: true);
  }
}