import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/ats_standard_format_template_support.dart';

void main() {
  test(
      'keeps ATS Standard links, project details, certifications, and languages intact',
      () {
    final links = AtsStandardFormatTemplateSupport.linkItems(
      PersonalInfo(
        linkedIn: 'https://linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
      ),
    );

    expect(
      links.map((item) => item.label),
      containsAll(<String>[
        'linkedin.com/in/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );

    final projectEntries = AtsStandardFormatTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics and automation workflows for health-claims operations and reporting. https://example.com/cigna-health-care',
          url: 'https://example.com/cigna-health-care',
        ),
      ],
      compactLinks: false,
    );

    expect(projectEntries, hasLength(1));
    expect(projectEntries.single.title, 'Cigna Health Care');
    expect(
      projectEntries.single.detailLines.join(' | '),
      contains('Built analytics and automation workflows'),
    );
    expect(
      projectEntries.single.url,
      'https://example.com/cigna-health-care',
    );

    final certificationEntries =
        AtsStandardFormatTemplateSupport.certificationEntries(
      [
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
      compactLinks: false,
    );

    expect(certificationEntries, hasLength(1));
    expect(certificationEntries.single.name, 'AWS Cloud Practitioner');
    final certificationText =
        certificationEntries.single.detailLines.join(' | ');
    expect(certificationText, contains('Amazon'));
    expect(certificationText, contains('Issued Jan 2024'));
    expect(certificationText, contains('Expires Jan 2027'));
    expect(certificationText, contains('Credential ID: AWS-123456'));
    expect(
      certificationEntries.single.url,
      'https://example.com/cert/aws-123456',
    );

    final languageLines = AtsStandardFormatTemplateSupport.languageLines(
      [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Native'),
      ],
    );

    expect(
      languageLines,
      containsAll(<String>[
        'English  •  Professional',
        'German  •  Native',
      ]),
    );
  });

  test(
      'keeps full experience and summary detail lines for ATS Standard data shaping',
      () {
    final summaryLines = AtsStandardFormatTemplateSupport.summaryLines(
      'Lead automation delivery → Mentor engineers → Drive debugging quality',
    );
    expect(
      summaryLines,
      containsAll(<String>[
        'Lead automation delivery',
        'Mentor engineers',
        'Drive debugging quality',
      ]),
    );

    final experienceEntries =
        AtsStandardFormatTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'TCS',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Managed automation delivery across UI, API, and regression workflows.',
          achievements: const [
            'Guided team members and contributed to framework development.',
            'Managed client interactions for status updates, metrics, and communication.',
          ],
        ),
      ],
    );

    expect(experienceEntries, hasLength(1));
    expect(experienceEntries.single.dateRange, '2019 - 2025');
    expect(
      experienceEntries.single.detailLines.join(' | '),
      contains(
          'Managed automation delivery across UI, API, and regression workflows.'),
    );
    expect(
      experienceEntries.single.detailLines.join(' | '),
      contains('Guided team members and contributed to framework development.'),
    );
    expect(
      experienceEntries.single.detailLines.join(' | '),
      contains(
          'Managed client interactions for status updates, metrics, and communication.'),
    );
  });
}
