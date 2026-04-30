import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/ats_optimized_clean_template_support.dart';
import 'package:resume_builder/features/templates/widgets/ats_optimized_clean_resume_template_preview.dart';

void main() {
  ResumeModel buildResume({List<CustomSection> customSections = const []}) {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'ats-optimized-clean-preview-test',
      title: 'ATS Optimized Clean Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products. Builds reliable user experiences with clear communication and strong execution.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          location: 'New York, NY',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 12, 1),
          achievements: const [
            'Led team of 5 to deliver cloud-based platform.',
            'Improved preview accuracy by aligning renderer output with production templates.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2015, 9, 1),
          endDate: DateTime(2019, 5, 1),
          grade: 'GPA: 3.8/4.0',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'REST APIs'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps template-specific output aligned with edited resume content.',
          url: 'https://preview.example.com',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      customSections: customSections,
      templateId: 'ats_optimized_clean',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets(
    'ats optimized clean preview adds summary bullets and moves certifications below core skills',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 254,
                child: AtsOptimizedCleanResumeTemplatePreview(
                  accentColor: const Color(0xFF7C3AED),
                  resume: buildResume(
                    customSections: [
                      CustomSection(
                        id: 'user_custom_leadership',
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
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color ==
                  const Color(AtsOptimizedCleanTemplateSupport.pageHex),
        ),
        findsWidgets,
      );
      expect(find.text('JOHN SMITH'), findsOneWidget);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('ABOUT ME'), findsOneWidget);
      expect(find.text('Core Skills'), findsOneWidget);
      expect(find.text('Certifications'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('johnsmith.dev'), findsOneWidget);
      expect(find.text('Resume Builder'), findsOneWidget);
      expect(find.text('preview.example.com'), findsOneWidget);
      expect(find.text('AWS Certified Developer  •  Amazon'), findsOneWidget);
      expect(find.text('Leadership Highlights'), findsOneWidget);
      expect(find.text('Cross-Team Delivery'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.justify &&
              (widget.data ?? '').contains('high-quality solutions'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration! as BoxDecoration).color ==
                  const Color(AtsOptimizedCleanTemplateSupport.inkHex),
        ),
        findsNWidgets(2),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.right &&
              (widget.data ?? '').contains('johnsmith.dev'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Certifications')).dy,
        lessThan(tester.getTopLeft(find.text('EXPERIENCE')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Certifications')).dy,
        greaterThan(tester.getTopLeft(find.text('Core Skills')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
