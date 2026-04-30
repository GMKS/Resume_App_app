import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/features/ai/screens/linkedin_import_screen.dart';

void main() {
  test('LinkedIn import does not leak later sections into skills', () {
    const pastedProfile = '''
Seenai GMK
Automation Lead
Hyderabad, Telangana, India

Contact
9916750642 (Home)
seenai07@yahoo.co

Summary
I am a highly organized, thorough and motivated professional with 8 years of experience in all facets of software testing.

Experience
Tata Global Consultancy Services
Automation Lead
July 2018 - August 2024
Hyderabad Area, India

Skills
C#
Test Planning
Security Testing

Certifications
Git Essential Training: The Basics

Summary
Seenai GMK
Andhra Pradesh
India
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final skills = (parsed['skills'] as List<Object>).cast<String>();
    final summary = parsed['summary'] as String;

    expect(skills, contains('C#'));
    expect(skills, contains('Test Planning'));
    expect(skills, contains('Security Testing'));

    expect(skills, isNot(contains('Git Essential Training: The Basics')));
    expect(skills, isNot(contains('Seenai GMK')));
    expect(skills, isNot(contains('Andhra Pradesh')));
    expect(skills, isNot(contains('India')));
    expect(skills, isNot(contains('Summary')));
    expect(summary, contains('highly organized'));
  });

  test('LinkedIn import handles PDF-style profile extracts', () {
    const pastedProfile = '''
Seenai GMK
Automation Lead
Hyderabad, Telangana, India

Contact
Phone
9916750642 (Home)
Email
seenai07@yahoo.co
Profile
www.linkedin.com/in/seenai-gmk

About
Automation and quality engineering leader with 8 years of experience building reliable test platforms.

Experience
Automation Lead
Tata Consultancy Services
July 2018 - August 2024 · 6 yrs 2 mos
Hyderabad Area, India
Led test automation strategy and execution across enterprise releases.

SDET
Infosys
June 2016 - June 2018
Bengaluru, Karnataka, India
Built regression suites and improved release confidence.

Education
Jawaharlal Nehru Technological University
Bachelor of Technology, Computer Science
2012 - 2016

Skills
C#
Test Planning
Security Testing

Certifications
Git Essential Training: The Basics

Languages
English
Telugu
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final skills = (parsed['skills'] as List<Object>).cast<String>();
    final certifications = (parsed['certifications'] as List<Object>).cast<String>();
    final languages = (parsed['languages'] as List<Object>).cast<String>();
    final experienceCompanies =
        (parsed['experienceCompanies'] as List<Object>).cast<String>();
    final experiencePositions =
        (parsed['experiencePositions'] as List<Object>).cast<String>();

    expect(parsed['name'], 'Seenai GMK');
    expect(parsed['headline'], 'Automation Lead');
    expect(parsed['phone'], contains('9916750642'));
    expect(parsed['location'], 'Hyderabad, Telangana, India');
    expect(parsed['linkedIn'], contains('linkedin.com/in/seenai-gmk'));
    expect(parsed['summary'], contains('quality engineering leader'));

    expect(experiencePositions, containsAll(<String>['Automation Lead', 'SDET']));
    expect(experienceCompanies, containsAll(<String>['Tata Consultancy Services', 'Infosys']));
    expect(skills, containsAll(<String>['C#', 'Test Planning', 'Security Testing']));
    expect(certifications, contains('Git Essential Training: The Basics'));
    expect(languages, containsAll(<String>['English', 'Telugu']));
  });

  test('LinkedIn import ignores footer name and title in certifications', () {
    const pastedProfile = '''
Seenai GMK
Automation Lead

Contact
seenai07@yahoo.co

Certifications
Git Essential Training: The Basics
Communicating about Culturaly Sensitive Issues
Seenai GMK
Automation Lead
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final certifications =
        (parsed['certifications'] as List<Object>).cast<String>();

    expect(certifications, contains('Git Essential Training: The Basics'));
    expect(
      certifications,
      contains('Communicating about Culturaly Sensitive Issues'),
    );
    expect(certifications, isNot(contains('Seenai GMK')));
    expect(certifications, isNot(contains('Automation Lead')));
  });

  test('LinkedIn import strips the screen sample block from certifications', () {
    const pastedProfile = '''
Seenai GMK
Automation Lead

Contact
seenai07@yahoo.co

Certifications
Git Essential Training: The Basics
Paste your LinkedIn profile text here…
Example:
John Doe
Senior Software Engineer at Acme Corp
Sydney, NSW

About
Passionate engineer with 7 years experience…

Experience
Acme Corp · Senior Software Engineer
Jan 2021 – Present · Sydney, NSW
…

Skills
Python, AWS, Docker, Node.js…
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final certifications =
        (parsed['certifications'] as List<Object>).cast<String>();

    expect(certifications, equals(<String>['Git Essential Training: The Basics']));
    expect(certifications, isNot(contains('Paste your LinkedIn profile text here…')));
    expect(certifications, isNot(contains('John Doe')));
    expect(
      certifications,
      isNot(contains('Senior Software Engineer at Acme Corp')),
    );
  });

  test('LinkedIn import handles resume-style PDF text with section-first layout', () {
    const pastedProfile = '''
EDUCATION
MCA Computers
Holy Jesus and Mary PG College
2006 - 2009

SKILLS
Dart
Java
GraphQL

GMK SEENAI
HR Consultant
+91 9916750642
seenaigmk@gmail.com
Hyderabad, India
linkedin.com/seenai
github.com/gmk

ABOUT ME
Strategic HR Consultant with expertise in talent management, employee relations, and organizational development.

EXPERIENCE
Software Engineer Jan 2022 - Present
TechNova Solutions | Bangalore, India
Description:
Developed scalable web applications using React and Node.js

PROJECTS
AI Resume Builder
Built a full-stack AI-powered resume builder.
github.com/yourusername/ai-resume-builder

CERTIFICATIONS
ISTQB Certification
ISTQB Certified Tester Foundation Level
Issued Apr 2023
Credential ID: ISTQB-CTFL-2023-45872
istqb.org/certification-path-root/ctfl.html

LANGUAGES
Hindi | Professional
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final skills = (parsed['skills'] as List<Object>).cast<String>();
    final educationInstitutions =
      (parsed['educationInstitutions'] as List<Object>).cast<String>();
    final educationDegrees =
      (parsed['educationDegrees'] as List<Object>).cast<String>();
    final projectTitles =
      (parsed['projectTitles'] as List<Object>).cast<String>();
    final projectUrls =
      (parsed['projectUrls'] as List<Object>).cast<String>();
    final certificationIssuers =
      (parsed['certificationIssuers'] as List<Object>).cast<String>();
    final experienceCompanies =
        (parsed['experienceCompanies'] as List<Object>).cast<String>();
    final experiencePositions =
        (parsed['experiencePositions'] as List<Object>).cast<String>();

    expect(parsed['name'], 'GMK SEENAI');
    expect(parsed['headline'], 'HR Consultant');
    expect(parsed['email'], 'seenaigmk@gmail.com');
    expect(parsed['phone'], contains('9916750642'));
    expect(parsed['location'], 'Hyderabad, India');
    expect(parsed['linkedIn'], contains('linkedin.com/seenai'));
    expect(parsed['github'], contains('github.com/gmk'));
    expect(parsed['summary'], contains('Strategic HR Consultant'));
    expect(skills, containsAll(<String>['Dart', 'Java', 'GraphQL']));
    expect(skills, isNot(contains('GMK SEENAI')));
    expect(skills, isNot(contains('HR Consultant')));
    expect(educationInstitutions, contains('Holy Jesus and Mary PG College'));
    expect(educationDegrees, contains('MCA Computers'));
    expect(experiencePositions, contains('Software Engineer'));
    expect(experienceCompanies, contains('TechNova Solutions'));
    expect(projectTitles, contains('AI Resume Builder'));
    expect(
      projectUrls,
      contains('github.com/yourusername/ai-resume-builder'),
    );
    expect(certificationIssuers, contains('ISTQB Certified Tester Foundation Level'));
    expect(parsed['languages'], equals(<String>['Hindi']));
  });

  test('LinkedIn import handles contact-first PDF text order', () {
    const pastedProfile = '''
seenai07@yahoo.co
9916750642 (Home)
www.linkedin.com/in/seenai-gmk-74da9519
Seenai GMK
Automation Lead

PROFESSIONAL SUMMARY
Automation lead with experience across manual, automation, and Selenium testing.

WORK EXPERIENCE
Automation Lead Jan 2021 - Present
Tata Consultancy Services | Hyderabad, India
Description:
Led automation initiatives across enterprise releases.
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);

    expect(parsed['name'], 'Seenai GMK');
    expect(parsed['headline'], 'Automation Lead');
    expect(parsed['email'], 'seenai07@yahoo.co');
    expect(parsed['phone'], contains('9916750642'));
    expect(parsed['linkedIn'], contains('linkedin.com/in/seenai-gmk-74da9519'));
    expect(parsed['summary'], contains('Automation lead'));
  });

  test('LinkedIn import captures the full professional summary', () {
    const pastedProfile = '''
Seenai GMK
Automation Lead

PROFESSIONAL SUMMARY
Line one about automation leadership.
Line two about Selenium and manual testing.
Line three about framework ownership.
Line four about release quality.
Line five about collaboration.
Line six about delivery metrics.
Line seven about integration testing.
Line eight about regression coverage.
Line nine about mentoring teams.
Line ten about continuous improvement.

WORK EXPERIENCE
Automation Lead Jan 2021 - Present
Tata Consultancy Services | Hyderabad, India
Description:
Led automation initiatives across enterprise releases.
''';

    final parsed = debugParseLinkedInProfile(pastedProfile);
    final summary = parsed['summary'] as String;

    expect(summary, contains('Line one about automation leadership.'));
    expect(summary, contains('Line ten about continuous improvement.'));
  });

  test(
    'LinkedIn import backfills name and headline from the pre-summary footer and keeps them out of certifications',
    () {
      const pastedProfile = '''
Contact
9916750642 (Home)
seenai07@yahoo.co.in
www.linkedin.com/in/seenaigmk-74a04519 (LinkedIn)
Top Skills
C#
Test Planning
Security Testing
Certifications
Git Essential Training: The Basics
Communicating about Culturally
Sensitive Issues
Seenai GMK
Automation Lead
Andhra Pradesh, India
Summary
► Experience: I am a highly organized, thorough and motivated
professional with 8 years of experience in all facets of software
testing with key focus on Manual, Automation and Selenium Testing
using Core java and Cucumber Framework. Currently, I am working
as a SDTET (Software Development Engineer in Test) at UST
Global Pvt. Ltd., India.
►Excellence: I am competent in working in the complete (STLC)
testing life cycle involving Integration, Manual Testing, Regressing
Testing, Functional Testing, End to End Testing, System Testing,
Mobile App Testing, Defect Management and Agile Methodology.
Skilled in latest test management tools viz. Jenkins, Bamboo, Azure
DevOps. Proven experience with QA methodologies, requirement
analysis, writing test plans and test cases based on system
requirement specifications.
►Personal Traits: I have remarkable interpersonal, organizational &
time management skills. Possess superior leadership, team building,
communication, interpersonal, and presentation skills.
To know more about my work experience and skills, you can connect
with me, and I will be happy to discuss. Thank you
Experience
Tata Consultancy Services
Automation Lead
June 2021 - Present (4 years 11 months)
Hyderabad, Telangana, India
UST Global
SDET
July 2018 - August 2024 (6 years 2 months)
Hyderabad Area, India
Page 1 of 2
Working as SDET
HP
Senior Softwre Engineer
August 2010 - July 2017 (7 years)
Bangalore
with client Deloitte.
Education
Osmania University
Master of Computer Applications - MCA, Computer Science · (2006 - 2009)
Wesley Degree College
Bachelor of Science - BS  · (2002 - 2003)
Page 2 of 2
''';

      final parsed = debugParseLinkedInProfile(pastedProfile);
      final certifications =
          (parsed['certifications'] as List<Object>).cast<String>();
      final skills = (parsed['skills'] as List<Object>).cast<String>();

      expect(parsed['name'], 'Seenai GMK');
      expect(parsed['headline'], 'Automation Lead');
      expect(parsed['location'], 'Andhra Pradesh, India');
      expect(parsed['phone'], contains('9916750642'));
      expect(parsed['email'], 'seenai07@yahoo.co.in');
      expect(
        parsed['linkedIn'],
        contains('linkedin.com/in/seenaigmk-74a04519'),
      );
      expect(skills, containsAll(<String>['C#', 'Test Planning', 'Security Testing']));
      expect(
        certifications,
        contains('Git Essential Training: The Basics'),
      );
      expect(certifications, isNot(contains('Seenai GMK')));
      expect(certifications, isNot(contains('Automation Lead')));
      expect(certifications, isNot(contains('Andhra Pradesh, India')));
      expect(parsed['summary'], contains('highly organized, thorough and motivated'));
    },
  );

  testWidgets('LinkedIn import keeps example text out of the editable hint',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LinkedInImportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.decoration?.hintText, 'Paste your LinkedIn profile text here…');
    expect(
      find.text('Example profile text', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.textContaining('John Doe', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining(
        'Senior Software Engineer at Acme Corp',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}