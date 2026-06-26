import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/ai/services/raoe2_service.dart';

void main() {
  ResumeModel buildResume() {
    return ResumeModel(
      id: 'resume-1',
      title: 'QA Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '555-0100',
        address: 'Lagos, NG',
        jobTitle: 'Software Engineer',
      ),
      objective: 'Builds mobile features with Flutter.',
      experience: <Experience>[
        Experience(
          id: 'exp-1',
          company: 'Acme',
          position: 'Mobile Developer',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description: 'Built product features for customer-facing apps.',
          achievements: const <String>['Implemented onboarding flow'],
        ),
      ],
      skills: <Skill>[
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
      ],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  test('buildEditableResumeText renders key sections for AI input', () {
    final text = RAOE2Service.buildEditableResumeText(buildResume());

    expect(text, contains('Jane Doe'));
    expect(text, contains('Professional Summary'));
    expect(text, contains('Experience'));
    expect(text, contains('Skills'));
  });

  test('applyToResume updates summary experience and skills', () {
    final original = buildResume();
    const result = RAOE2OptimizationResult(
      originalResumeText: 'before',
      optimizedResumeText: 'after',
      missingKeywords: <String>['leadership'],
      keywordsAdded: <String>['leadership'],
      missingKeywordsAddressed: <String>['leadership'],
      actionableSuggestions: <String>['Add outcomes to projects'],
      sectionRewrites: <RAOE2SectionRewrite>[],
      rewrittenSummary:
          'Software engineer focused on Flutter delivery, stakeholder alignment, and measurable product outcomes.',
      rewrittenExperience: <RAOE2ExperienceRewrite>[
        RAOE2ExperienceRewrite(
          company: 'Acme',
          position: 'Senior Mobile Developer',
          description:
              'Led Flutter delivery for product initiatives with stronger stakeholder collaboration.',
          achievements: <String>[
            'Shipped a redesigned onboarding flow.',
            'Partnered with product to prioritize roadmap work.',
          ],
          keywordsAdded: <String>['leadership'],
          rationale: 'Emphasized leadership and delivery impact.',
        ),
      ],
      rewrittenSkills: <String>['Flutter', 'Dart', 'Leadership'],
      overallRationale: 'Targeted the job description more directly.',
      engineId: 'raoe2-ai',
      engineVersion: 'test',
    );

    final updated = RAOE2Service.applyToResume(
      resume: original,
      result: result,
    );

    expect(updated.objective, result.rewrittenSummary);
    expect(updated.experience.first.position, 'Senior Mobile Developer');
    expect(
      updated.experience.first.achievements,
      contains('Partnered with product to prioritize roadmap work.'),
    );
    expect(updated.skills.map((skill) => skill.name), contains('Leadership'));
  });

  test('keyword analyzer ignores generic posting words but keeps role terms', () {
    final missing = RAOE2KeywordAnalyzer.findMissingKeywords(
      resumeText: 'Flutter developer building mobile apps with Dart',
      jobDescription:
          'Application Developer with Flutter, Dart, strong team collaboration and 5 years of experience required',
    );

    expect(missing, contains('application'));
    expect(missing, isNot(contains('experience')));
    expect(missing, isNot(contains('years')));
    expect(missing, isNot(contains('team')));
  });
}