import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/free_plan_service.dart';
import 'package:resume_builder/core/services/resume_export_service.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/core/utils/export_file_validation.dart';
import 'package:resume_builder/features/profile/screens/help_support_screen.dart';
import 'package:resume_builder/features/resume/screens/resumes_tab_screen.dart';
import 'package:resume_builder/features/settings/screens/settings_screen.dart';
import 'package:resume_builder/shared/widgets/feature_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  const resumeId = 'premium-feature-test-resume';

  ResumeModel buildResume({String templateId = 'blue_gray'}) {
    final now = DateTime(2026, 3, 17);
    return ResumeModel(
      id: resumeId,
      title: 'Premium Feature Resume',
      personalInfo: PersonalInfo(
        fullName: 'Alex Morgan',
        email: 'alex@example.com',
        phone: '+1 555 123 0000',
        address: 'Austin, TX',
        linkedIn: 'linkedin.com/in/alexmorgan',
        github: 'github.com/alexmorgan',
        website: 'alexmorgan.dev',
        jobTitle: 'Product Designer',
        profileImage: base64Encode(List<int>.filled(8, 7)),
      ),
      objective:
          'Design polished, conversion-focused resume experiences across mobile and web.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Design Institute',
          degree: 'B.Des.',
          fieldOfStudy: 'Communication Design',
          startDate: DateTime(2015, 6, 1),
          endDate: DateTime(2019, 4, 1),
          location: 'Chicago, IL',
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'North Star Studio',
          position: 'Lead Product Designer',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 3, 1),
          description:
              'Led premium UX for resume editing and export workflows.',
          achievements: const [
            'Improved export conversion with better premium entry points.',
            'Designed reusable feature-gating patterns for cross-platform UI.',
          ],
          location: 'Remote',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'UX Writing'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Premium Export Flow',
          description: 'Introduced DOCX and TXT exports with premium locks.',
          technologies: const ['Flutter', 'Dart', 'WordprocessingML'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'UX Certification',
          issuer: 'Nielsen Norman Group',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      customSections: [
        CustomSection(
          id: 'custom-1',
          title: 'Awards',
          items: [
            CustomSectionItem(
              id: 'award-1',
              title: 'Design Excellence Award',
              subtitle: '2025',
              description: 'Recognised for premium UX improvements.',
            ),
          ],
        ),
      ],
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  Future<void> resetFreePlan() async {
    await StorageService.prefs.remove('subscription_plan');
    await StorageService.prefs.remove('subscription_expiry');
    await StorageService.prefs.remove('free_plan_pdf_exports');
    await StorageService.prefs.remove('free_plan_ai_uses');
    await StorageService.prefs.remove('trial_started_at');
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-premium-tests');
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
    await resetFreePlan();
    await StorageService.resumeBox.put(resumeId, buildResume());
  });

  group('ResumeExportService', () {
    test('buildTxtExport produces readable resume content', () {
      final export = ResumeExportService.buildTxtExport(buildResume());
      final content = utf8.decode(export.bytes);

      expect(export.filename, 'Alex_Morgan_Resume.txt');
      expect(export.mimeType, 'text/plain');
      expect(content, contains('Alex Morgan'));
      expect(content, contains('CONTACT'));
      expect(content, contains('EXPERIENCE'));
      expect(content, contains('North Star Studio'));
      expect(content, contains('AWARDS'));
    });

    test('buildDocxExport produces a valid zip-based docx payload', () {
      final export = ResumeExportService.buildDocxExport(buildResume());

      expect(export.filename, 'Alex_Morgan_Resume.docx');
      expect(
        export.mimeType,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(export.bytes, isNotEmpty);
      expect(export.bytes[0], 0x50);
      expect(export.bytes[1], 0x4B);
      expect(
        () => validateExportBytes(
          bytes: export.bytes,
          fileName: export.filename,
          mimeType: export.mimeType,
        ),
        returnsNormally,
      );
    });

    test('buildDocxExport strips invalid XML characters and escapes symbols',
        () {
      final export = ResumeExportService.buildDocxExport(
        buildResume().copyWith(
          personalInfo: buildResume().personalInfo.copyWith(
                fullName: 'Alex Ñ <Morgan> & Co',
              ),
          objective: 'Lead special chars \u0001 \u000B & < > " quotes',
        ),
      );

      final archive = ZipDecoder().decodeBytes(export.bytes);
      final documentFile = archive.findFile('word/document.xml');
      expect(documentFile, isNotNull);

      final content = documentFile!.content;
      final xmlBytes = content is List<int> ? content : <int>[];
      final documentXml = utf8.decode(xmlBytes, allowMalformed: false);

      expect(documentXml, contains('Alex Ñ &lt;Morgan&gt; &amp; Co'));
      expect(documentXml, contains('&quot; quotes'));
      expect(documentXml.contains('\u0001'), isFalse);
      expect(documentXml.contains('\u000B'), isFalse);
    });

    test('buildDocxExport keeps required OOXML parts for empty resume content',
        () {
      final export = ResumeExportService.buildDocxExport(
        ResumeModel(
          id: 'empty-docx',
          title: 'Empty Resume',
          personalInfo: PersonalInfo(),
          createdAt: DateTime(2026, 3, 17),
          updatedAt: DateTime(2026, 3, 17),
        ),
      );

      expect(
        () => validateExportBytes(
          bytes: export.bytes,
          fileName: export.filename,
          mimeType: export.mimeType,
        ),
        returnsNormally,
      );
    });

    test('buildDocxExport handles long text and profile image data', () {
      final longText =
          List<String>.filled(120, 'Scaled premium export content.').join(' ');
      final resume = buildResume().copyWith(
        objective: longText,
        personalInfo: buildResume().personalInfo.copyWith(
              profileImage: base64Encode(List<int>.filled(256, 11)),
            ),
      );

      final export = ResumeExportService.buildDocxExport(resume);

      expect(export.bytes.length, greaterThan(1024));
      expect(
        () => validateExportBytes(
          bytes: export.bytes,
          fileName: export.filename,
          mimeType: export.mimeType,
        ),
        returnsNormally,
      );
    });
  });

  group('Resume completion', () {
    test('calculateCompletionPercentage rounds expected scenarios', () {
      expect(calculateCompletionPercentage(0, 8).round(), 0);
      expect(calculateCompletionPercentage(1, 8).round(), 13);
      expect(calculateCompletionPercentage(4, 8).round(), 50);
      expect(calculateCompletionPercentage(5, 8).round(), 63);
      expect(calculateCompletionPercentage(8, 8).round(), 100);
    });

    test('completion stats and percentage stay aligned for resume sections',
        () {
      final resume = buildResume().copyWith(
        certifications: const [],
        languages: const [],
        projects: const [],
      );

      expect(resume.completionStats.completedSections, 5);
      expect(resume.completionStats.totalSections, 8);
      expect(resume.completionPercentage, 63);
    });
  });

  group('Premium entry points', () {
    test('free bundle includes 5 AI suggestions and shared upgrade message',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await StorageService.prefs.setInt('trial_started_at', now);

      expect(FreePlanService.remainingAiSuggestions, 5);
      expect(
        FreePlanService.premiumTemplateMessage,
        'Unlock premium templates, unlimited resumes, and watermark-free exports.',
      );
      expect(
        FreePlanService.aiLimitMessage,
        'Unlock premium templates, unlimited resumes, and watermark-free exports.',
      );
      expect(
        FreePlanService.exportLimitMessage,
        'Unlock premium templates, unlimited resumes, and watermark-free exports.',
      );
    });

    test('trial starts active and allows one PDF export', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await StorageService.prefs.setInt('trial_started_at', now);

      expect(FreePlanService.isTrialActive, isTrue);
      expect(FreePlanService.isTrialExpired, isFalse);
      expect(FreePlanService.remainingTrialDays, greaterThanOrEqualTo(1));
      expect(FreePlanService.canExportPdf, isTrue);

      await FreePlanService.recordPdfExport();

      expect(FreePlanService.canExportPdf, isFalse);
      expect(
        FreePlanService.currentExportMessage,
        FreePlanService.trialExportUsedMessage,
      );
    });

    test('expired trial blocks exporting until upgrade', () async {
      final expiredStart = DateTime.now()
          .subtract(const Duration(days: FreePlanService.trialDays + 1))
          .millisecondsSinceEpoch;
      await StorageService.prefs.setInt('trial_started_at', expiredStart);

      expect(FreePlanService.isTrialExpired, isTrue);
      expect(FreePlanService.canExportPdf, isFalse);
      expect(
        FreePlanService.currentExportMessage,
        FreePlanService.exportLimitMessage,
      );
    });

    test('premium templates are previewable but export stays premium',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await StorageService.prefs.setInt('trial_started_at', now);

      expect(FreePlanService.isTemplateLocked('modern'), isTrue);
      expect(FreePlanService.canExportResumeTemplate('modern'), isFalse);
      expect(
        FreePlanService.exportMessageForTemplate('modern'),
        FreePlanService.recommendedUpgradeMessage,
      );

      expect(FreePlanService.isTemplateLocked('classic'), isFalse);
      expect(FreePlanService.canExportResumeTemplate('classic'), isTrue);
    });

    testWidgets(
        'SettingsScreen shows premium badges for cloud sync and support',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Backup & Sync'), findsOneWidget);
      expect(find.text('Priority Support'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsNWidgets(2));
    });

    testWidgets('HelpSupportScreen shows premium badge on live chat',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(const HelpSupportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('new resume CTA stays enabled even after first free resume',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(const ResumesTabScreen()));
      await tester.pumpAndSettle();

      final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create New Resume'),
      );

      expect(createButton.onPressed, isNotNull);
    });

    test('free plan keeps premium photo upload locked', () {
      expect(FreePlanService.canUploadPhoto, isFalse);
    });
  });
}
