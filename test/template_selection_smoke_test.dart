import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/screens/template_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  const resumeId = 'template-smoke-resume';

  ResumeModel buildResume({
    List<CustomSection> customSections = const <CustomSection>[],
  }) {
    final now = DateTime(2026, 3, 12);
    return ResumeModel(
      id: resumeId,
      title: 'Smoke Test Resume',
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
            'Introduced smoke-test coverage for template selection and PDF flows.',
          ],
          location: 'Remote',
        ),
        Experience(
          id: 'exp-2',
          company: 'Creative Forge',
          position: 'Flutter Engineer',
          startDate: DateTime(2020, 6, 1),
          endDate: DateTime(2021, 12, 1),
          description:
              'Built polished UI systems and reusable component libraries.',
          achievements: const [
            'Delivered reusable design-system widgets for a multi-template app.',
          ],
          location: 'Portland, OR',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'Testing'),
        Skill(id: 'skill-5', name: 'CI/CD'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description: 'Cross-platform resume editor with live previews.',
          technologies: ['Flutter', 'Hive', 'Firebase'],
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
      customSections: customSections,
      templateId: 'modern',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpTemplateScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TemplateSelectionScreen(resumeId: resumeId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTemplateDialog(
    WidgetTester tester,
    String templateId,
  ) async {
    final carousel = find.byKey(const ValueKey('template-carousel'));
    final card = find.byKey(ValueKey('template-card-$templateId'));
    final previewButton = find.byKey(ValueKey('template-preview-$templateId'));

    for (var reset = 0; reset < 12; reset++) {
      await tester.drag(carousel, const Offset(320, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    for (var attempt = 0; attempt < 40 && card.evaluate().isEmpty; attempt++) {
      await tester.drag(carousel, const Offset(-220, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    expect(card, findsOneWidget);

    await tester.ensureVisible(previewButton);
    await tester.pumpAndSettle();

    await tester.tap(previewButton);
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-template-smoke');
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

  testWidgets('smoke-tests key without-photo template previews',
      (tester) async {
    await pumpTemplateScreen(tester);

    await tester.tap(find.text('Without Photo'));
    await tester.pumpAndSettle();

    for (final templateId in const [
      'modern',
      'classic',
      'creative',
      'developer',
      'elegant_pink',
      'one_page_resume',
      'classic_temp',
      'two_column',
      'infographic',
      'forest_edge_classic',
    ]) {
      await openTemplateDialog(tester, templateId);

      expect(
        find.text('Select This Template').evaluate().isNotEmpty ||
            find.text('Preview Premium Template').evaluate().isNotEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders full template catalog in desktop grid layout',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpTemplateScreen(tester);

    final accentFinder = find.text('Accent Color');
    final previewFinder =
        find.byKey(const ValueKey('selected-template-preview'));
    final firstCardFinder = find.byKey(const ValueKey('template-card-modern'));

    expect(find.byKey(const ValueKey('template-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('template-grid-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('template-card-modern')), findsOneWidget);
    expect(find.byKey(const ValueKey('template-card-forest_edge_classic')),
        findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);

    final accentTop = tester.getTopLeft(accentFinder).dy;
    final previewTop = tester.getTopLeft(previewFinder).dy;
    final firstCardTop = tester.getTopLeft(firstCardFinder).dy;

    await tester.drag(
      find.byKey(const ValueKey('template-grid-scroll')),
      const Offset(0, -600),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(firstCardFinder).dy, lessThan(firstCardTop));
    expect(tester.getTopLeft(accentFinder).dy, closeTo(accentTop, 0.1));
    expect(tester.getTopLeft(previewFinder).dy, closeTo(previewTop, 0.1));
  });

  test('generates developer pdf without layout overflow', () async {
    final resume = buildResume().copyWith(templateId: 'developer');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('developer');
    final pdf = await template.generate(resume, PdfColor.fromHex('#8B5CF6'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates two column pdf without layout overflow', () async {
    final resume = buildResume().copyWith(
      templateId: 'two_column',
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Cross-platform resume editor with live previews, template isolation, and export-ready layouts that preserve updated project details.',
          technologies: ['Flutter', 'Hive', 'Firebase'],
          url: 'https://example.com/resume-builder',
        ),
      ],
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('two_column');
    final pdf = await template.generate(resume, PdfColor.fromHex('#8B5CF6'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates infographic pdf without layout overflow', () async {
    final resume = buildResume().copyWith(
      templateId: 'infographic',
      objective:
          'Transforms complex product narratives into clear, visual operating systems. → Aligns stakeholders with journey-based storytelling and measurable delivery. → Builds scalable patterns for preview, export, and high-fidelity design handoff.',
      projects: [
        Project(
          id: 'project-1',
          title: 'Signal Dashboard',
          description:
              'Built a product health dashboard that aligned research insights, roadmap risks, and release progress across teams.',
          technologies: ['Flutter', 'Firebase', 'Analytics'],
          url: 'https://example.com/signal-dashboard',
        ),
        Project(
          id: 'project-2',
          title: 'Workflow Atlas',
          description:
              'Mapped dense internal workflows into a reusable system of guided handoff views and task checkpoints.',
          technologies: ['Design Systems', 'UX Research'],
          url: 'https://example.com/workflow-atlas',
        ),
        Project(
          id: 'project-3',
          title: 'Launch Map',
          description:
              'Created a launch-readiness surface that visualized dependency blockers and milestone ownership.',
          technologies: ['Flutter Web', 'Data Viz'],
          url: 'https://example.com/launch-map',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Flutter Certified Developer',
          issuer: 'Google',
        ),
        Certification(
          id: 'cert-2',
          name: 'Design Systems Mastery',
          issuer: 'InVision',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('infographic');
    final pdf = await template.generate(resume, PdfColor.fromHex('#5E8FA2'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates pink rose modern pdf without layout overflow', () async {
    final resume = buildResume().copyWith(
      templateId: 'elegant_pink',
      personalInfo: buildResume().personalInfo.copyWith(
            github: 'https://github.com/jordansmith',
          ),
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Cross-platform resume editor with live previews, richer template-specific rendering, and export-ready project details that stay aligned with the edited resume.',
          technologies: ['Flutter', 'Hive', 'Firebase'],
          url: 'https://example.com/resume-builder',
        ),
      ],
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('elegant_pink');
    final pdf = await template.generate(resume, PdfColor.fromHex('#D87093'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
