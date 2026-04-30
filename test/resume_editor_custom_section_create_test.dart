import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/editor/screens/resume_editor_screen.dart';
import 'package:resume_builder/features/editor/screens/user_custom_section_screen.dart';
import 'package:resume_builder/features/editor/widgets/user_custom_section_action_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  const resumeId = 'editor-custom-section-test';

  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 20);
    return ResumeModel(
      id: resumeId,
      title: 'Editor Test Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 010 1010',
        address: 'Austin, TX',
        jobTitle: 'QA Engineer',
      ),
      objective: 'Build stable resume editing flows.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Acme Corp',
          position: 'QA Engineer',
          startDate: DateTime(2024, 1, 1),
          description: 'Owned web release quality.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2020, 1, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/editor/$resumeId',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/editor/:resumeId',
          builder: (context, state) =>
              ResumeEditorScreen(resumeId: state.pathParameters['resumeId']!),
          routes: [
            GoRoute(
              path: 'user-custom/:sectionId',
              builder: (context, state) => UserCustomSectionScreen(
                resumeId: state.pathParameters['resumeId']!,
                sectionId: state.pathParameters['sectionId']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  GoRouter buildCustomSectionRouter(String sectionId) {
    return GoRouter(
      initialLocation: '/editor/$resumeId/user-custom/$sectionId',
      routes: [
        GoRoute(
          path: '/editor/:resumeId',
          builder: (context, state) =>
              ResumeEditorScreen(resumeId: state.pathParameters['resumeId']!),
          routes: [
            GoRoute(
              path: 'user-custom/:sectionId',
              builder: (context, state) => UserCustomSectionScreen(
                resumeId: state.pathParameters['resumeId']!,
                sectionId: state.pathParameters['sectionId']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTestApp() {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: buildRouter(),
      ),
    );
  }

  Widget buildCustomSectionTestApp(String sectionId) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: buildCustomSectionRouter(sectionId),
      ),
    );
  }

  Future<void> openAddCustomSectionSheet(WidgetTester tester) async {
    final addButton = find.text('Add Custom Section');
    await tester.scrollUntilVisible(
      addButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp(
      'resume-editor-custom-section-test',
    );
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
    await StorageService.deleteAllResumes();
    await StorageService.resumeBox.put(resumeId, buildResume());
    await StorageService.prefs.remove('section_order_$resumeId');
  });

  testWidgets('creates a user custom section with initial content',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Awards');
    await tester.enterText(
      textFields.at(1),
      'Won the release quality award\nImproved smoke coverage',
    );

    await tester.tap(find.text('Create Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Awards'), findsWidgets);

    final savedResume = StorageService.getResume(resumeId);
    expect(savedResume, isNotNull);
    expect(
      savedResume!.customSections.any((section) => section.title == 'Awards'),
      isTrue,
    );
  });

  testWidgets('creates an empty user custom section after confirmation',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Publications');
    await tester.tap(find.text('Create Section'));
    await tester.pumpAndSettle();

    expect(find.text('Save Empty Section?'), findsOneWidget);
    await tester.tap(find.text('Save Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Publications'), findsWidgets);

    final savedResume = StorageService.getResume(resumeId);
    expect(savedResume, isNotNull);
    final savedSection = savedResume!.customSections.firstWhere(
      (section) => section.title == 'Publications',
    );
    expect(savedSection.items, isEmpty);
  });

  testWidgets('rapid repeated create taps only create one section',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Awards');
    await tester.enterText(
      textFields.at(1),
      'Recognized for release quality leadership',
    );

    final createButton = find.text('Create Section');
    await tester.tap(createButton);
    await tester.tap(createButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('A custom section with this title already exists'), findsNothing);

    final savedResume = StorageService.getResume(resumeId);
    expect(savedResume, isNotNull);
    final matchingSections = savedResume!.customSections
        .where((section) => section.title == 'Awards')
        .toList(growable: false);
    expect(matchingSections.length, 1);
  });

  testWidgets('Add Entry action stays fully visible on narrow screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: UserCustomSectionActionBar(
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final labelFinder = find.text('Add Entry');
    expect(labelFinder, findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      findsOneWidget,
    );

    final labelRect = tester.getRect(labelFinder);
    expect(labelRect.left, greaterThanOrEqualTo(0));
    expect(labelRect.right, lessThanOrEqualTo(500));
  });
}