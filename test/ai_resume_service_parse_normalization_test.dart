import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/ai_resume_service.dart';

void main() {
  test('normalizeParsedResumePayload preserves nested and extra resume sections', () {
    final normalized = AiResumeService.normalizeParsedResumePayload(
      <String, dynamic>{
        'personalInfo': <String, dynamic>{
          'name': 'Casey Reed',
          'email': 'casey@example.com',
          'phone': '+1 555 111 2222',
          'location': 'Austin, TX',
          'title': 'Senior Product Designer',
          'linkedin': 'linkedin.com/in/casey',
          'github': 'github.com/casey',
          'portfolio': 'https://casey.design',
        },
        'summary': 'Design leader focused on accessible product systems.',
        'workHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'employer': 'Northwind',
            'role': 'Lead Product Designer',
            'city': 'Austin',
            'startYear': 2021,
            'current': true,
            'details': <String>[
              'Led redesign of the onboarding journey.',
              'Improved conversion by 18%.',
            ],
            'highlights': <String>['Mentored 3 designers.'],
          },
        ],
        'academicHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'school': 'State University',
            'degree': 'B.Des',
            'major': 'Interaction Design',
            'startYear': 2015,
            'endYear': 2019,
            'gpa': '3.9',
            'details': 'Graduated with honors.',
          },
        ],
        'technicalSkills': <String, dynamic>{
          'design': <String>['Figma', 'Prototyping'],
          'collaboration': 'Facilitation, Leadership',
        },
        'licenses': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Google UX Certification',
            'organization': 'Google',
            'issueYear': 2023,
            'url': 'https://cred.example/google-ux',
          },
        ],
        'languageProficiencies': <Map<String, dynamic>>[
          <String, dynamic>{'language': 'English', 'level': 'Native'},
        ],
        'portfolioProjects': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Design System',
            'summary': 'Unified component library across four products.',
            'techStack': <String>['Figma', 'Design Tokens'],
            'website': 'https://casey.design/system',
          },
        ],
        'interests': <String>['Photography', 'Travel'],
        'references': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Morgan Lee',
            'title': 'Director of Design',
            'organization': 'Northwind',
            'email': 'morgan@example.com',
          },
        ],
        'sections': <String, dynamic>{
          'volunteerExperience': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Mentor',
              'organization': 'Women in Design',
              'description': 'Coached early-career designers for portfolio reviews.',
            },
          ],
        },
        'awards': <String>['AIGA Student Award'],
      },
    );

    expect(normalized['fullName'], 'Casey Reed');
    expect(normalized['email'], 'casey@example.com');
    expect(normalized['jobTitle'], 'Senior Product Designer');
    expect(normalized['linkedIn'], 'linkedin.com/in/casey');
    expect(normalized['website'], 'https://casey.design');
    expect(normalized['objective'], 'Design leader focused on accessible product systems.');

    final experiences = normalized['experience'] as List<dynamic>;
    expect(experiences, hasLength(1));
    expect(experiences.first['company'], 'Northwind');
    expect(experiences.first['position'], 'Lead Product Designer');
    expect(experiences.first['achievements'], contains('Mentored 3 designers.'));

    final education = normalized['education'] as List<dynamic>;
    expect(education.first['institution'], 'State University');
    expect(education.first['fieldOfStudy'], 'Interaction Design');

    expect(normalized['skills'], containsAll(<String>['Figma', 'Prototyping', 'Facilitation', 'Leadership']));

    final certifications = normalized['certifications'] as List<dynamic>;
    expect(certifications.first['name'], 'Google UX Certification');
    expect(certifications.first['credentialUrl'], 'https://cred.example/google-ux');

    final hobbies = normalized['hobbies'] as List<dynamic>;
    expect(hobbies, containsAll(<String>['Photography', 'Travel']));

    final references = normalized['references'] as List<dynamic>;
    expect(references.first['name'], 'Morgan Lee');
    expect(references.first['company'], 'Northwind');

    final customSections = normalized['customSections'] as List<dynamic>;
    final titles = customSections
        .map((section) => (section as Map<String, dynamic>)['title'] as String)
        .toList(growable: false);
    expect(titles, containsAll(<String>['Volunteer Experience', 'Awards']));
  });
}