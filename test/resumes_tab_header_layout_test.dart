import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/providers/navigation_providers.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/resume/screens/resumes_tab_screen.dart';

ResumeModel _resume(String id, String title) {
  final now = DateTime(2026, 5, 1);
  return ResumeModel(
    id: id,
    title: title,
    personalInfo: PersonalInfo(fullName: 'GMK Seenai'),
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _disposeTestWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final hiveDir = await Directory.systemTemp.createTemp('resumes-tab-header');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  setUp(() async {
    await StorageService.deleteAllResumes();
    await StorageService.prefs.setString('subscription_plan', 'premium');
    await StorageService.prefs.setString(
      'subscription_expiry',
      DateTime(2030, 1, 1).millisecondsSinceEpoch.toString(),
    );
    await StorageService.saveResume(_resume('resume-1', 'MyResume_007'));
    await StorageService.saveResume(_resume('resume-2', 'My Resume 10'));
  });

  testWidgets('header keeps title and create action on one row on phone widths',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResumesTabScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final titleFinder = find.text('My Resumes');
    final buttonFinder = find.byType(FilledButton);
    final buttonLabelFinder = find.text('Create New Resume');

    expect(titleFinder, findsOneWidget);
    expect(buttonFinder, findsOneWidget);
    expect(buttonLabelFinder, findsOneWidget);

    final titleRect = tester.getRect(titleFinder);
    final buttonRect = tester.getRect(buttonFinder);

    expect((titleRect.top - buttonRect.top).abs(), lessThan(16));
    expect(buttonRect.left, greaterThan(titleRect.left));
    expect(tester.takeException(), isNull);

    await _disposeTestWidgetTree(tester);
  });

  testWidgets('shows only completed resumes when completed filter is active',
      (tester) async {
    final now = DateTime(2026, 5, 1);
    await StorageService.deleteAllResumes();
    await StorageService.saveResume(
      ResumeModel(
        id: 'resume-complete',
        title: 'Completed Resume',
        personalInfo: PersonalInfo(fullName: 'GMK Seenai'),
        createdAt: now,
        updatedAt: now,
        completionPercentage: 100,
      ),
    );
    await StorageService.saveResume(
      ResumeModel(
        id: 'resume-progress',
        title: 'Draft Resume',
        personalInfo: PersonalInfo(fullName: 'GMK Seenai'),
        createdAt: now,
        updatedAt: now,
        completionPercentage: 60,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeListFilterProvider.overrideWith(
            (ref) => StateController(ResumeListFilter.completed),
          ),
        ],
        child: const MaterialApp(
          home: ResumesTabScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Completed Resume'), findsOneWidget);
    expect(find.text('Draft Resume'), findsNothing);
    expect(find.text('Completed resumes'), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(find.text('Draft Resume'), findsOneWidget);

    await _disposeTestWidgetTree(tester);
  });
}