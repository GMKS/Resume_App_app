import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/emerald_executive_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'emerald-preview-test',
      title: 'Emerald Executive',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai@example.com',
        phone: '+91 99999 22226',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        website: 'https://seenai.dev',
        jobTitle: 'Senior Manager',
      ),
      objective:
          '→ Over 13 years in software testing and development with strong experience in automation and debugging → Experienced in mentoring teams through complex release cycles → Able to align test strategy with executive reporting expectations → Delivers high-quality release validation under tight timelines',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2021, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PU College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 1, 1),
          endDate: DateTime(2009, 1, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Selenium'),
        Skill(id: 'skill-2', name: 'Core Java'),
      ],
      templateId: 'emerald_executive',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets(
      'emerald executive preview uses dedicated screenshot-aligned layout',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: EmeraldExecutiveResumeTemplatePreview(
                accentColor: const Color(0xFF16653D),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('GMK SEENAI'), findsOneWidget);
    expect(find.text('SUMMARY'), findsOneWidget);
    expect(find.text('PROFESSIONAL EXPERIENCE'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
    expect(find.text('SKILLS'), findsNothing);
    expect(find.text('linkedin.com/in/seenai'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').contains('\u2192'),
      ),
      findsNothing,
    );
    expect(
      find.text(
          'Experienced in mentoring teams through complex release cycles.'),
      findsNothing,
    );
    expect(
      find.text('Experienced in mentoring teams through complex release cycles'),
      findsOneWidget,
    );
    expect(
      find.text(
          'Able to align test strategy with executive reporting expectations.'),
      findsNothing,
    );
    expect(
      find.text('Able to align test strategy with executive reporting expectations'),
      findsOneWidget,
    );
    expect(
      find.text('Delivers high-quality release validation under tight timelines'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
