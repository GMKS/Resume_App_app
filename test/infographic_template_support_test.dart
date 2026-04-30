import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/infographic_template_support.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'infographic-support-test',
      title: 'Infographic Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
      ),
      objective: 'Builds clear delivery systems.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Bluewave Labs',
          position: 'Senior Flutter Developer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 3, 1),
          description:
              'Led Flutter web and mobile delivery for customer-facing resume tooling.',
          achievements: const [
            'Reduced preview rendering regressions across major template updates.',
            'Introduced dedicated template smoke coverage and export validation.',
          ],
        ),
      ],
      education: const [],
      skills: const [],
      projects: [
        Project(
          id: 'project-1',
          title: 'Workflow Atlas',
          description:
              'Mapped operations into guided review paths for delivery teams. '
              'Added PDF-safe continuation handling for credentials. Docs: https://docs.example.com/workflow-atlas '
              'Demo: https://atlas.example.com/app',
          technologies: ['Flutter', 'PDF'],
          url: 'https://github.com/example/workflow-atlas',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Flutter Certified Developer',
          issuer: 'Google',
        ),
        Certification(
          id: 'cert-2',
          name: 'Professional Scrum Master',
          issuer: 'Scrum.org',
        ),
        Certification(
          id: 'cert-3',
          name: 'Accessibility Foundations',
          issuer: 'Deque',
        ),
      ],
      languages: const [],
      templateId: 'infographic',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('infographic support preserves full project summaries and all links', () {
    final resume = buildResume();

    final projects = InfographicTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
    );

    expect(projects, hasLength(1));
    expect(
      projects.single.detailLines,
      containsAll([
        'Mapped operations into guided review paths for delivery teams.',
        'Added PDF-safe continuation handling for credentials.',
      ]),
    );
    expect(
      projects.single.links,
      equals([
        'docs.example.com/workflow-atlas',
        'atlas.example.com/app',
        'github.com/example/workflow-atlas',
      ]),
    );

    expect(
      InfographicTemplateSupport.certificationLines(
        resume.certifications,
        maxItems: null,
      ),
      equals([
        'Flutter Certified Developer  •  Google',
        'Professional Scrum Master  •  Scrum.org',
        'Accessibility Foundations  •  Deque',
      ]),
    );
  });

  test('infographic support keeps all experience points by default', () {
    final resume = buildResume();

    final experiences = InfographicTemplateSupport.experienceEntries(
      resume.experience,
      maxItems: null,
    );

    expect(experiences, hasLength(1));
    expect(
      experiences.single.detailLines,
      equals([
        'Led Flutter web and mobile delivery for customer-facing resume tooling.',
        'Reduced preview rendering regressions across major template updates.',
        'Introduced dedicated template smoke coverage and export validation.',
      ]),
    );
  });
}