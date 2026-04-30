import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'package:resume_builder/features/career_tools/models/job_tracker_models.dart';
import 'package:resume_builder/features/career_tools/services/job_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = JobTrackerService();
  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp('job-tracker-service-test');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await StorageService.prefs.clear();
  });

  JobApplicationRecord buildJob({
    required String id,
    required String company,
    required String role,
    JobApplicationStatus status = JobApplicationStatus.saved,
  }) {
    return service.buildDraft(
      userId: 'user-1',
      existingId: id,
      company: company,
      role: role,
      location: 'Remote',
      status: status,
      notes: '',
      jobDescription: 'Flutter role using Dart, Firebase, and API integrations.',
      parsedSkills: const <String>['Flutter', 'Dart'],
      parsedKeywords: const <String>['Firebase'],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  test('insertOrUpdate prevents duplicate company and role pairs', () {
    final existing = buildJob(id: '1', company: 'Acme', role: 'Flutter Developer');
    final duplicate = buildJob(id: '2', company: 'acme', role: 'flutter developer');

    expect(
      () => service.insertOrUpdate(jobs: <JobApplicationRecord>[existing], candidate: duplicate),
      throwsA(isA<DuplicateJobApplicationException>()),
    );
  });

  test('updateStatus rejects invalid transition and allows valid ones', () {
    final saved = buildJob(id: '1', company: 'Acme', role: 'QA Engineer');

    expect(
      () => service.updateStatus(
        jobs: <JobApplicationRecord>[saved],
        jobId: saved.jobId,
        nextStatus: JobApplicationStatus.offer,
      ),
      throwsA(isA<InvalidJobStatusTransitionException>()),
    );

    final appliedJobs = service.updateStatus(
      jobs: <JobApplicationRecord>[saved],
      jobId: saved.jobId,
      nextStatus: JobApplicationStatus.applied,
    );

    expect(appliedJobs.single.status, JobApplicationStatus.applied);
    expect(appliedJobs.single.activities.last.message, contains('Saved to Applied'));
  });

  test('parseJobDescription extracts role, skills, and keywords', () {
    final insights = service.parseJobDescription(
      'We are hiring a Flutter Developer to build mobile experiences with Dart, Firebase, REST API integrations, and strong communication.',
    );

    expect(insights.role, 'Flutter Developer');
    expect(insights.skills, contains('Flutter'));
    expect(insights.skills, contains('Dart'));
    expect(insights.skills, contains('Firebase'));
    expect(insights.keywords, isNotEmpty);
  });

  test('persistJobs and loadJobs round-trip saved entries', () async {
    await StorageService.prefs.setString('sync_device_id', 'device-a');

    final job = buildJob(
      id: '1',
      company: 'Acme',
      role: 'Flutter Developer',
    );

    await service.persistJobs(<JobApplicationRecord>[job]);
    final loaded = await service.loadJobs();

    expect(loaded, hasLength(1));
    expect(loaded.single.company, 'Acme');
    expect(loaded.single.role, 'Flutter Developer');
  });

  test('loadJobs falls back to local entries when the scoped key changes', () async {
    await StorageService.prefs.setString('sync_device_id', 'device-a');

    final job = buildJob(
      id: '1',
      company: 'Acme',
      role: 'QA Engineer',
    );

    await service.persistJobs(<JobApplicationRecord>[job]);

    await StorageService.prefs.setString('sync_device_id', 'device-b');
    final loaded = await service.loadJobs();

    expect(loaded, hasLength(1));
    expect(loaded.single.company, 'Acme');
    expect(loaded.single.role, 'QA Engineer');
  });
}