import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/resume_import_mapper.dart';
import 'package:resume_builder/core/utils/user_custom_sections.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 22);
    return ResumeModel(
      id: 'resume-1',
      title: 'Existing Resume',
      personalInfo: PersonalInfo(
        fullName: 'Old Name',
        email: 'old@example.com',
        phone: '+1 555 999 0000',
      ),
      hobbies: const <String>['Cycling'],
      references: <Reference>[
        Reference(
          id: 'ref-existing',
          name: 'Existing Reference',
          company: 'Legacy Corp',
        ),
      ],
      customSections: <CustomSection>[
        CustomSection(
          id: buildUserCustomSectionId(),
          title: 'Awards',
          order: 0,
          items: <CustomSectionItem>[
            CustomSectionItem(id: 'award-old', title: 'Legacy Award'),
          ],
        ),
        CustomSection(
          id: buildUserCustomSectionId(),
          title: 'Leadership Experience',
          order: 1,
          items: <CustomSectionItem>[
            CustomSectionItem(id: 'leader-old', title: 'Team Mentor'),
          ],
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  test('applyParsedData maps broader sections and merges custom sections', () {
    final updated = ResumeImportMapper.applyParsedData(
      resume: buildResume(),
      parsedData: <String, dynamic>{
        'fullName': 'Casey Reed',
        'email': 'casey@example.com',
        'jobTitle': 'Senior Product Designer',
        'objective': 'Design leader focused on scalable systems.',
        'experience': <Map<String, dynamic>>[
          <String, dynamic>{
            'company': 'Northwind',
            'position': 'Lead Product Designer',
            'startYear': 2021,
            'isCurrentlyWorking': true,
            'description': 'Led redesign of the onboarding journey.',
            'achievements': <String>['Mentored 3 designers.'],
          },
        ],
        'education': <Map<String, dynamic>>[
          <String, dynamic>{
            'institution': 'State University',
            'degree': 'B.Des',
            'fieldOfStudy': 'Interaction Design',
            'startYear': 2015,
            'endYear': 2019,
            'description': 'Graduated with honors.',
          },
        ],
        'skills': <dynamic>[
          'Figma',
          <String, dynamic>{'name': 'Leadership', 'category': 'Soft Skills'},
        ],
        'certifications': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Google UX Certification',
            'issuer': 'Google',
            'issueYear': 2023,
          },
        ],
        'languages': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'English', 'proficiency': 'Native'},
        ],
        'projects': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Design System',
            'description': 'Unified component library across four products.',
            'technologies': <String>['Figma', 'Design Tokens'],
          },
        ],
        'hobbies': <String>['Photography', 'Travel'],
        'references': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Morgan Lee',
            'position': 'Director of Design',
            'company': 'Northwind',
            'email': 'morgan@example.com',
          },
        ],
        'customSections': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Awards',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'title': 'AIGA Student Award'},
            ],
          },
          <String, dynamic>{
            'title': 'Publications',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'title': 'Designing for Trust',
                'subtitle': 'Medium',
                'description': 'Featured article on accessibility patterns.',
              },
            ],
          },
        ],
      },
    );

    expect(updated.personalInfo.fullName, 'Casey Reed');
    expect(updated.personalInfo.email, 'casey@example.com');
    expect(updated.personalInfo.jobTitle, 'Senior Product Designer');
    expect(updated.objective, 'Design leader focused on scalable systems.');

    expect(updated.experience, hasLength(1));
    expect(updated.experience.first.company, 'Northwind');
    expect(updated.experience.first.achievements, contains('Mentored 3 designers.'));

    expect(updated.education.first.description, 'Graduated with honors.');
    expect(updated.skills.map((skill) => skill.name), containsAll(<String>['Figma', 'Leadership']));
    expect(updated.hobbies, containsAll(<String>['Photography', 'Travel']));
    expect(updated.references.first.name, 'Morgan Lee');
    expect(updated.references.first.position, 'Director of Design');

    final titles = orderedUserCustomSections(updated)
        .map((section) => section.title)
        .toList(growable: false);
    expect(titles, <String>['Awards', 'Leadership Experience', 'Publications']);
    expect(orderedUserCustomSections(updated).first.items.first.title, 'AIGA Student Award');
  });

  test('applyParsedData preserves existing optional sections when parsed data omits them', () {
    final existing = buildResume();
    final updated = ResumeImportMapper.applyParsedData(
      resume: existing,
      parsedData: <String, dynamic>{
        'fullName': 'Casey Reed',
        'hobbies': <String>[],
        'references': <Map<String, dynamic>>[],
        'customSections': <Map<String, dynamic>>[],
      },
    );

    expect(updated.personalInfo.fullName, 'Casey Reed');
    expect(updated.hobbies, existing.hobbies);
    expect(updated.references.first.name, 'Existing Reference');
    expect(orderedUserCustomSections(updated).map((section) => section.title),
        <String>['Awards', 'Leadership Experience']);
  });
}