import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/professional_template_support.dart';
import 'package:resume_builder/features/templates/widgets/professional_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'professional-preview-test',
      title: 'Professional Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9889533165',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing and development with a strong understanding of testing, coding, and debugging procedures.\n'
          'Programming Skills: Proficient in Selenium, Core Java, and Cucumber.\n'
          'Problem Solving: Excellent analytical and technical troubleshooting abilities.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
          achievements: const [
            'Guided team members and contributed to test framework development.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Limited',
          position: 'Senior Software Engineer',
          location: 'Hyderabad, India',
          startDate: DateTime(2016, 6, 1),
          endDate: DateTime(2019, 12, 1),
          description:
              'Developed and maintained automation test scripts using Selenium and Core Java.',
          achievements: const [
            'Implemented data-driven and page object model frameworks.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU University',
          degree: 'B.Tech',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2007, 8, 1),
          endDate: DateTime(2011, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Selenium'),
        Skill(id: 'skill-2', name: 'Java'),
        Skill(id: 'skill-3', name: 'REST APIs'),
        Skill(id: 'skill-4', name: 'TestNG'),
        Skill(id: 'skill-5', name: 'Cucumber'),
        Skill(id: 'skill-6', name: 'CI/CD'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Test Automation Framework',
          description:
              'Built a BDD test framework with Cucumber and Selenium.\n'
              'Integrated reporting dashboards for nightly regression. Docs: https://docs.example.com/framework',
          url: 'https://example.com/framework',
          technologies: const ['Java', 'Selenium', 'Cucumber'],
        ),
        Project(
          id: 'project-2',
          title: 'API Coverage Platform',
          description:
              'Created reusable API validation workflows with Rest Assured.\n'
              'Live: https://api.example.com/coverage',
          url: 'https://github.com/example/api-coverage',
          technologies: const ['Rest Assured', 'Java', 'CI/CD'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'ISTQB Certified Tester',
          issuer: 'ISTQB',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'Telugu', proficiency: 'Native'),
        Language(id: 'lang-3', name: 'Hindi', proficiency: 'Professional'),
        Language(id: 'lang-4', name: 'Tamil', proficiency: 'Conversational'),
      ],
      templateId: 'professional',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated professional pdf template', () {
    final template = PdfTemplateFactory.getTemplate('professional');
    expect(template, isA<ProfessionalResumePdfTemplate>());
  });

  test('support compacts contact links and preserves project data', () {
    final resume = buildResume();

    final contacts = ProfessionalTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    expect(
      contacts.map((item) => item.label),
      equals([
        'seenai007@gmail.com',
        '+91 9889533165',
        'Hyderabad, India',
        'linkedin.com/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );

    final summary = ProfessionalTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    expect(summary.length, greaterThanOrEqualTo(3));
    expect(
      summary.any((line) => line.contains('Problem Solving')),
      isTrue,
    );

    final projects = ProfessionalTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    expect(projects, hasLength(2));
    expect(projects.first.title, 'Test Automation Framework');
    expect(
      projects.first.detailLines,
      containsAll([
        'Built a BDD test framework with Cucumber and Selenium.',
        'Integrated reporting dashboards for nightly regression.',
      ]),
    );
    expect(
      projects.first.links,
      equals(['docs.example.com/framework', 'example.com/framework']),
    );
    expect(projects.last.title, 'API Coverage Platform');
    expect(
      projects.last.detailLines,
      contains('Created reusable API validation workflows with Rest Assured.'),
    );
    expect(
      projects.last.links,
      equals([
        'api.example.com/coverage',
        'github.com/example/api-coverage',
      ]),
    );

    expect(
      ProfessionalTemplateSupport.languageLines(
        resume.languages,
        maxItems: null,
      ),
      equals([
        'English Professional',
        'Telugu Native',
        'Hindi Professional',
        'Tamil Conversational',
      ]),
    );
  });

  testWidgets('preview renders the dedicated professional sections',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 420,
              child: ProfessionalResumeTemplatePreview(
                accentColor: const Color(0xFF5A607D),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('PROFILE SNAPSHOT'), findsOneWidget);
    expect(find.text('CAREER EXPERIENCE'), findsOneWidget);
    expect(find.text('CORE SKILLS'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.text('linkedin.com/seenai'), findsOneWidget);
    expect(find.text('github.com/gmk'), findsOneWidget);
    expect(find.text('seenaigmk.com'), findsOneWidget);
    expect(find.textContaining('Automation Lead'), findsOneWidget);
    expect(find.textContaining('Test Automation Framework'), findsOneWidget);
    expect(
      find.textContaining('Integrated reporting dashboards for nightly regression.'),
      findsOneWidget,
    );
    expect(find.textContaining('API Coverage Platform'), findsOneWidget);
    expect(find.text('docs.example.com/framework'), findsOneWidget);
    expect(find.text('api.example.com/coverage'), findsOneWidget);
    expect(find.text('github.com/example/api-coverage'), findsOneWidget);
    expect(find.textContaining('ISTQB Certified Tester'), findsOneWidget);
    expect(find.textContaining('English Professional'), findsOneWidget);
    expect(find.textContaining('Hindi Professional'), findsOneWidget);
    expect(find.textContaining('Tamil Conversational'), findsOneWidget);
  });
}