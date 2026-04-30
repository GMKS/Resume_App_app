import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/elite_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'elite-preview-test',
      title: 'Elite Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.\n'
          'Improves preview fidelity, preserves detailed content, and builds maintainable resume export workflows.\n'
          'Partners across engineering and design teams to ship reliable product updates.',
      experience: const [],
      education: const [],
      skills: const [],
      projects: const [],
      certifications: const [],
      languages: const [],
      templateId: 'modern_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('elite preview uses numeric summary markers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: EliteResumeTemplatePreview(
                accentColor: const Color(0xFF6366F1),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    final marker = tester.widget<Text>(find.text('1.'));
    expect(marker.style?.color, const Color(0xFF35354A));
    expect(tester.takeException(), isNull);
  });
}