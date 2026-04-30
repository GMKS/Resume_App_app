import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/ai/services/resume_job_match_service.dart';

void main() {
  ResumeModel buildResume() {
    return ResumeModel(
      id: 'resume-1',
      title: 'Senior Flutter Engineer',
      personalInfo: PersonalInfo(
        fullName: 'Alex Carter',
        email: 'alex@example.com',
        phone: '+1 555 0101',
        address: 'Austin, TX',
        jobTitle: 'Senior Flutter Engineer',
        linkedIn: 'linkedin.com/in/alexcarter',
      ),
      objective:
          'Senior Flutter engineer shipping mobile apps with Dart, Firebase, analytics, and cross-functional delivery leadership.',
      experience: <Experience>[
        Experience(
          id: 'exp-1',
          company: 'Northwind',
          position: 'Senior Flutter Engineer',
          startDate: DateTime(2021, 1),
          description:
              'Built Flutter features, integrated Firebase services, improved release quality, and partnered with product and design teams.',
          achievements: const <String>[
            'Reduced crash-free session issues by 28%.',
            'Mentored 3 mobile engineers.',
          ],
        ),
      ],
      skills: <Skill>[
        Skill(id: 'skill-1', name: 'Flutter', proficiency: 5),
        Skill(id: 'skill-2', name: 'Dart', proficiency: 5),
        Skill(id: 'skill-3', name: 'Firebase', proficiency: 4),
        Skill(id: 'skill-4', name: 'REST APIs', proficiency: 4),
      ],
      projects: <Project>[
        Project(
          id: 'proj-1',
          title: 'Retail Checkout App',
          description:
              'Delivered a Flutter point-of-sale experience with Firebase authentication and analytics instrumentation.',
          technologies: const <String>['Flutter', 'Firebase', 'Analytics'],
        ),
      ],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );
  }

  test('analyze returns match score, missing skills, section scores, and suggestions', () {
    final result = ResumeJobMatchService.analyze(
      resume: buildResume(),
      jobDescription: '''
Senior Mobile Engineer

Required skills: Flutter, Dart, Firebase, GraphQL, leadership.
Experience with mobile development, stakeholder management, and product collaboration.
''',
    );

    expect(result.matchScore, greaterThan(0));
    expect(result.extractedKeywords, contains('flutter'));
    expect(result.extractedKeywords, contains('graphql'));
    expect(result.matchedKeywords, containsAll(<String>['flutter', 'dart', 'firebase']));
    expect(result.missingSkills, contains('graphql'));
    expect(result.topSkills, contains('Flutter'));
    expect(result.sectionScores, isNotEmpty);
    expect(
      result.sectionScores.map((section) => section.sectionKey),
      containsAll(<String>['summary', 'experience', 'skills']),
    );
    expect(
      result.suggestions.map((suggestion) => suggestion.sectionKey),
      contains('skills'),
    );
  });

  test('analyze accepts an injected similarity provider', () {
    const provider = _AlwaysMatchSimilarityProvider();

    final result = ResumeJobMatchService.analyze(
      resume: buildResume(),
      jobDescription: 'Required skills: Flutter, leadership, mentoring.',
      similarityProvider: provider,
    );

    expect(result.engineId, 'test-provider');
    expect(result.engineVersion, ResumeJobMatchService.engineVersion);
    expect(result.sectionScores.firstWhere((section) => section.sectionKey == 'summary').score, greaterThan(0));
  });
}

class _AlwaysMatchSimilarityProvider extends ResumeJobSimilarityProvider {
  const _AlwaysMatchSimilarityProvider();

  @override
  String get id => 'test-provider';

  @override
  double computeSimilarity({
    required String resumeText,
    required String jobText,
    required Set<String> resumeKeywords,
    required Set<String> jobKeywords,
  }) {
    return 1;
  }
}