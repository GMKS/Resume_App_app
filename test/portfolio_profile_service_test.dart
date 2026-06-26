import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/portfolio/services/portfolio_profile_service.dart';

void main() {
  ResumeModel buildResume({
    required String id,
    String website = '',
    List<Project> projects = const <Project>[],
  }) {
    return ResumeModel(
      id: id,
      title: 'Resume $id',
      personalInfo: PersonalInfo(website: website),
      projects: projects,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  test('resolvePortfolioUrl prefers the resume website and normalizes it', () {
    final resume = buildResume(
      id: 'resume-1',
      website: 'portfolio.johnsmith.dev',
      projects: <Project>[
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description: 'Case study site',
          url: 'https://example.com/project',
        ),
      ],
    );

    final url = PortfolioProfileService.resolvePortfolioUrl(resume);

    expect(url, 'https://portfolio.johnsmith.dev');
  });

  test('resolvePortfolioUrl falls back to a portfolio project url', () {
    final resume = buildResume(
      id: 'resume-1',
      projects: <Project>[
        Project(
          id: 'project-1',
          title: 'Portfolio Showcase',
          description: 'Highlights and case studies',
          url: 'portfolio.example.com/showcase',
        ),
      ],
    );

    final url = PortfolioProfileService.resolvePortfolioUrl(resume);

    expect(url, 'https://portfolio.example.com/showcase');
  });

  test('resolvePortfolioUrl ignores disallowed email-host websites', () {
    final resume = buildResume(
      id: 'resume-1',
      website: 'https://www.gmail.com',
      projects: <Project>[
        Project(
          id: 'project-1',
          title: 'Portfolio Showcase',
          description: 'Highlights and case studies',
          url: 'portfolio.example.com/showcase',
        ),
      ],
    );

    final url = PortfolioProfileService.resolvePortfolioUrl(resume);

    expect(url, 'https://portfolio.example.com/showcase');
  });

  test('resolvePortfolioUrl returns empty for email-derived website values',
      () {
    final resume = buildResume(
      id: 'resume-1',
      website: 'seenai@example.com',
    );

    final url = PortfolioProfileService.resolvePortfolioUrl(resume);

    expect(url, isEmpty);
  });

  test('selectSourceResume honors preferred resume id when present', () {
    final first = buildResume(id: 'resume-1');
    final second = buildResume(id: 'resume-2', website: 'resume2.dev');

    final selected = PortfolioProfileService.selectSourceResume(
      <ResumeModel>[first, second],
      preferredResumeId: 'resume-1',
    );

    expect(selected?.id, 'resume-1');
  });
}
