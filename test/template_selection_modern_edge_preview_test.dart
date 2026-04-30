import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/templates/screens/template_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  const resumeId = 'modern-edge-template-preview';

  ResumeModel buildResume() {
    final now = DateTime(2026, 3, 12);
    return ResumeModel(
      id: resumeId,
      title: 'Template Preview Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 123 4567',
        address: 'Seattle, WA',
        linkedIn: 'linkedin.com/in/jordansmith',
        github: 'github.com/jordansmith',
        website: 'jordansmith.dev',
        jobTitle: 'Senior Flutter Developer',
      ),
      objective:
          'Build accessible Flutter products, improve rendering performance, and mentor engineers across mobile and web teams.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 9, 1),
          endDate: DateTime(2020, 5, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Bluewave Labs',
          position: 'Senior Flutter Developer',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 3, 1),
          description:
              'Led Flutter web and mobile delivery for customer-facing resume tooling.',
          achievements: const [
            'Reduced preview rendering regressions across major template updates.',
          ],
          location: 'Remote',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description: 'Cross-platform resume editor with live previews.',
          technologies: ['Flutter', 'Hive'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Flutter Certified Developer',
          issuer: 'Google',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              description:
                  'Led audit readiness and stakeholder reporting across release trains.',
            ),
          ],
        ),
      ],
      templateId: 'modern_edge',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpTemplateScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: TemplateSelectionScreen(resumeId: resumeId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> openModernEdgeDialog(WidgetTester tester) async {
    final carousel = find.byKey(const ValueKey('template-carousel'));
    final card = find.byKey(const ValueKey('template-card-modern_edge'));
    final previewButton = find.byKey(
      const ValueKey('template-preview-modern_edge'),
    );

    await tester.tap(find.text('With Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (var reset = 0; reset < 12; reset++) {
      await tester.drag(carousel, const Offset(320, 0), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
    }

    for (var attempt = 0; attempt < 40 && card.evaluate().isEmpty; attempt++) {
      await tester.drag(carousel, const Offset(-220, 0), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
    }

    expect(card, findsOneWidget);

    await tester.ensureVisible(previewButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    await tester.tap(previewButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-modern-edge-preview');
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
  });

  testWidgets('template preview dialog uses the stored resume data', (
    tester,
  ) async {
    await pumpTemplateScreen(tester);
    await openModernEdgeDialog(tester);

    expect(find.text('Leadership Highlights'), findsAtLeastNWidgets(1));
    expect(find.text('Cross-Team Delivery'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}