import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/ats_standard_format_template_support.dart';
import 'package:resume_builder/features/templates/widgets/ats_standard_format_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'ats-standard-format-preview-test',
      title: 'ATS Standard Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing and development, with strong experience in testing, coding, debugging, and automation delivery across UI, service, and data workflows.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Managed automation delivery across UI, API, and regression workflows while coordinating status updates with stakeholders.',
          achievements: const [
            'Led the automation team in developing and executing test automation scripts.',
            'Guided team members and contributed to framework development.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 2, 1),
          endDate: DateTime(2009, 2, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'Project Management'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics and automation workflows for health-claims operations and reporting.',
          url: 'https://example.com/cigna-health-care',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Cloud Practitioner',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'ats_standard_format',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets(
    'ats standard preview keeps the blue background, right guide, and full ATS data sections',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 254,
                child: AtsStandardFormatResumeTemplatePreview(
                  accentColor: const Color(0xFF5569E8),
                  resume: buildResume(),
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
                  const Color(AtsStandardFormatTemplateSupport.pageHex),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color ==
                  const Color(AtsStandardFormatTemplateSupport.guideHex),
        ),
        findsOneWidget,
      );
      expect(find.text('GMK SEENAI'), findsOneWidget);
      expect(find.text('Senior Manager'), findsOneWidget);
      expect(find.text('ABOUT ME'), findsOneWidget);
      expect(find.text('LINKS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('CERTIFICATIONS'), findsOneWidget);
      expect(find.text('LANGUAGES'), findsOneWidget);
      expect(find.text('LinkedIn: linkedin.com/in/seenai'), findsOneWidget);
      expect(find.text('GitHub: github.com/gmk'), findsOneWidget);
      expect(find.text('Website: seenaigmk.com'), findsOneWidget);
      expect(find.text('Cigna Health Care'), findsOneWidget);
      expect(find.text('example.com/cigna-health-care'), findsOneWidget);
      expect(find.text('AWS Cloud Practitioner'), findsOneWidget);
      expect(find.text('English  •  Professional'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.justify &&
              (widget.data ?? '').contains('testing, coding, debugging'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.right &&
              (widget.data ?? '').contains('2019 - 2025'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
