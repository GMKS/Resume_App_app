import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/editor/screens/custom_section_screen.dart';
import 'package:resume_builder/features/editor/screens/resume_editor_screen.dart';
import 'package:resume_builder/features/editor/screens/user_custom_section_screen.dart';

const resumeEditorCustomSectionResumeId = 'editor-custom-section-test';

ResumeModel buildResumeEditorCustomSectionResume() {
  final now = DateTime(2026, 4, 20);
  return ResumeModel(
    id: resumeEditorCustomSectionResumeId,
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

GoRouter buildResumeEditorCustomSectionRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation:
        initialLocation ?? '/editor/$resumeEditorCustomSectionResumeId',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/editor/:resumeId',
        builder: (context, state) => ResumeEditorScreen(
          resumeId: state.pathParameters['resumeId']!,
        ),
        routes: [
          GoRoute(
            path: 'custom/:sectionId',
            builder: (context, state) => CustomSectionScreen(
              resumeId: state.pathParameters['resumeId']!,
              sectionId: state.pathParameters['sectionId']!,
            ),
          ),
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

Widget buildResumeEditorCustomSectionTestApp({String? initialLocation}) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: buildResumeEditorCustomSectionRouter(
        initialLocation: initialLocation,
      ),
    ),
  );
}

Future<void> initializeResumeEditorCustomSectionStorage(String prefix) async {
  SharedPreferences.setMockInitialValues({});
  final hiveDir = await Directory.systemTemp.createTemp(prefix);
  Hive.init(hiveDir.path);
  await StorageService.init();
}

Future<void> resetResumeEditorCustomSectionStorage() async {
  await StorageService.deleteAllResumes();
  await StorageService.resumeBox.put(
    resumeEditorCustomSectionResumeId,
    buildResumeEditorCustomSectionResume(),
  );
  await StorageService.prefs.remove(
    'section_order_$resumeEditorCustomSectionResumeId',
  );
}

Future<void> openAddCustomSectionSheet(WidgetTester tester) async {
  final addButton = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data?.startsWith('Add ') ?? false) &&
        (widget.data?.contains('Custom Section') ?? false),
    description: 'add custom section label',
  );
  await tester.scrollUntilVisible(
    addButton,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  final addTileTapTarget = find
      .ancestor(
        of: addButton,
        matching: find.byType(InkWell),
      )
      .hitTestable();

  expect(addTileTapTarget, findsOneWidget);

  await tester.tap(addTileTapTarget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  expect(find.text('Create Section'), findsOneWidget);
}

Future<void> disposeTestWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}
