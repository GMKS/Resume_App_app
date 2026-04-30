import '../models/resume_model.dart';

enum ResumeQualityPriority {
  high,
  medium,
  low,
}

class ResumeQualitySuggestion {
  const ResumeQualitySuggestion({
    required this.sectionKey,
    required this.title,
    required this.description,
    this.priority = ResumeQualityPriority.medium,
  });

  final String sectionKey;
  final String title;
  final String description;
  final ResumeQualityPriority priority;
}

class ResumeQualityReport {
  const ResumeQualityReport({
    required this.score,
    this.strengths = const <String>[],
    this.suggestions = const <ResumeQualitySuggestion>[],
  });

  final int score;
  final List<String> strengths;
  final List<ResumeQualitySuggestion> suggestions;

  bool get hasSuggestions => suggestions.isNotEmpty;

  String get scoreLabel {
    if (score >= 85) {
      return 'Strong';
    }
    if (score >= 65) {
      return 'Good';
    }
    if (score >= 45) {
      return 'Needs polish';
    }
    return 'Needs work';
  }
}

class ResumeQualityService {
  static ResumeQualityReport analyzeResume(ResumeModel resume) {
    final suggestions = <ResumeQualitySuggestion>[];
    final strengths = <String>[];

    final personal = resume.personalInfo;
    final fullName = personal.fullName.trim();
    final email = personal.email.trim();
    final phone = personal.phone.trim();
    final address = personal.address.trim();
    final jobTitle = (personal.jobTitle ?? '').trim();
    final linkedIn = (personal.linkedIn ?? '').trim();
    final github = (personal.github ?? '').trim();
    final website = (personal.website ?? '').trim();
    final summary = (resume.objective ?? '').trim();

    final contactChannels = <String>[email, phone, linkedIn, github, website]
        .where((value) => value.isNotEmpty)
        .length;
    final digitalProfiles = <String>[linkedIn, github, website]
        .where((value) => value.isNotEmpty)
        .length;

    final experienceEntries = resume.experience;
    final experienceWithImpact = experienceEntries
        .where(
          (experience) =>
              experience.description.trim().isNotEmpty ||
              experience.achievements
                  .where((entry) => entry.trim().isNotEmpty)
                  .isNotEmpty,
        )
        .length;
    final experienceMissingDates = experienceEntries
        .where(
          (experience) =>
              !experience.isCurrentlyWorking && experience.endDate == null,
        )
        .length;

    final educationEntries = resume.education;
    final educationDetailed = educationEntries
        .where(
          (education) =>
              education.degree.trim().isNotEmpty &&
              education.institution.trim().isNotEmpty,
        )
        .length;

    final skillsCount = resume.skills.length;
    final skillsCategories = resume.skills
        .map((skill) => (skill.category ?? '').trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final projectEntries = resume.projects;
    final projectsWithLinks = projectEntries
        .where((project) => (project.url ?? '').trim().isNotEmpty)
        .length;
    final projectsWithStack = projectEntries
        .where((project) => project.technologies.isNotEmpty)
        .length;

    final certifications = resume.certifications;
    final certificationsWithMetadata = certifications
        .where(
          (certification) =>
              certification.issueDate != null ||
              (certification.credentialId ?? '').trim().isNotEmpty ||
              (certification.credentialUrl ?? '').trim().isNotEmpty,
        )
        .length;

    final languages = resume.languages;

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'personal',
          title: 'Complete the core contact block',
          description:
              'Add your full name, email, and phone so the header stays credible in preview and export.',
          priority: ResumeQualityPriority.high,
        ),
      );
    } else {
      strengths.add('Core contact details are present and ready for export.');
    }

    if (jobTitle.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'personal',
          title: 'Add a role headline',
          description:
              'A clear job title helps recruiters understand your target position immediately.',
          priority: ResumeQualityPriority.medium,
        ),
      );
    } else {
      strengths.add('A role headline clarifies your positioning.');
    }

    if (digitalProfiles == 0) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'personal',
          title: 'Add at least one professional link',
          description:
              'LinkedIn, GitHub, or a portfolio URL makes the resume easier to verify.',
          priority: ResumeQualityPriority.low,
        ),
      );
    } else if (digitalProfiles >= 2) {
      strengths.add('Multiple professional links strengthen recruiter trust.');
    }

    if (summary.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'summary',
          title: 'Write a professional summary',
          description:
              'A short summary improves ATS context and gives the preview a stronger opening.',
          priority: ResumeQualityPriority.high,
        ),
      );
    } else if (summary.length < 80) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'summary',
          title: 'Expand the summary with more context',
          description:
              'Add scope, strengths, or results so the summary says more than a short headline.',
          priority: ResumeQualityPriority.medium,
        ),
      );
    } else {
      strengths.add('The summary provides useful top-level context.');
    }

    if (experienceEntries.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'experience',
          title: 'Add work experience',
          description:
              'Experience is the strongest proof block for most templates and ATS review flows.',
          priority: ResumeQualityPriority.high,
        ),
      );
    } else {
      if (experienceWithImpact == 0) {
        suggestions.add(
          const ResumeQualitySuggestion(
            sectionKey: 'experience',
            title: 'Add impact statements or achievements',
            description:
                'Results and responsibility details make your roles persuasive in preview and export.',
            priority: ResumeQualityPriority.high,
          ),
        );
      } else {
        strengths.add('Experience entries include impact-oriented detail.');
      }

      if (experienceMissingDates > 0) {
        suggestions.add(
          ResumeQualitySuggestion(
            sectionKey: 'experience',
            title: 'Finish incomplete experience dates',
            description:
                '$experienceMissingDates role${experienceMissingDates == 1 ? '' : 's'} need an end date or should be marked as current.',
            priority: ResumeQualityPriority.medium,
          ),
        );
      }
    }

    if (educationEntries.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'education',
          title: 'Add education details',
          description:
              'At least one education entry improves completeness and helps support resume structure.',
          priority: ResumeQualityPriority.medium,
        ),
      );
    } else if (educationDetailed != educationEntries.length) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'education',
          title: 'Complete degree and institution fields',
          description:
              'Keep each education entry specific so templates can render it clearly.',
          priority: ResumeQualityPriority.low,
        ),
      );
    } else {
      strengths.add('Education entries are specific and ready to render.');
    }

    if (skillsCount < 4) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'skills',
          title: 'Expand the skills section',
          description:
              'Add a broader skill set so ATS matching and template summaries have enough signal.',
          priority: ResumeQualityPriority.medium,
        ),
      );
    } else if (skillsCategories <= 1 && skillsCount >= 6) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'skills',
          title: 'Balance skills across categories',
          description:
              'A mix of technical and supporting skills usually reads better than a single cluster.',
          priority: ResumeQualityPriority.low,
        ),
      );
    } else {
      strengths.add('Skills provide broad ATS and preview coverage.');
    }

    if (projectEntries.isEmpty) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'projects',
          title: 'Add at least one project',
          description:
              'Projects help prove tools, ownership, and shipped work beyond job titles alone.',
          priority: ResumeQualityPriority.low,
        ),
      );
    } else {
      if (projectsWithLinks == 0) {
        suggestions.add(
          const ResumeQualitySuggestion(
            sectionKey: 'projects',
            title: 'Add a project URL when possible',
            description:
                'A live link gives recruiters and hiring teams a way to verify your work quickly.',
            priority: ResumeQualityPriority.low,
          ),
        );
      }
      if (projectsWithStack == 0) {
        suggestions.add(
          const ResumeQualitySuggestion(
            sectionKey: 'projects',
            title: 'Tag project technologies',
            description:
                'List the tools or stack you used so each project reinforces your skill claims.',
            priority: ResumeQualityPriority.medium,
          ),
        );
      }
      if (projectsWithLinks > 0 || projectsWithStack > 0) {
        strengths.add('Projects reinforce your work with supporting detail.');
      }
    }

    if (certifications.isNotEmpty && certificationsWithMetadata == 0) {
      suggestions.add(
        const ResumeQualitySuggestion(
          sectionKey: 'certifications',
          title: 'Add certification verification details',
          description:
              'Issue dates, credential IDs, or URLs make certifications more credible in export.',
          priority: ResumeQualityPriority.low,
        ),
      );
    } else if (certificationsWithMetadata > 0) {
      strengths.add('Certification metadata improves trust signals.');
    }

    if (languages.isNotEmpty) {
      strengths.add('Language coverage supports international applications.');
    }

    final score = _computeScore(
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      jobTitle: jobTitle,
      contactChannels: contactChannels,
      summary: summary,
      experienceEntries: experienceEntries,
      experienceWithImpact: experienceWithImpact,
      experienceMissingDates: experienceMissingDates,
      educationEntries: educationEntries,
      educationDetailed: educationDetailed,
      skillsCount: skillsCount,
      skillsCategories: skillsCategories,
      projectEntries: projectEntries,
      projectsWithLinks: projectsWithLinks,
      projectsWithStack: projectsWithStack,
      certifications: certifications,
      certificationsWithMetadata: certificationsWithMetadata,
      languages: languages,
      customSections: resume.customSections,
    );

    suggestions.sort((left, right) {
      final priorityCompare =
          _priorityWeight(right.priority).compareTo(_priorityWeight(left.priority));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return left.title.compareTo(right.title);
    });

    return ResumeQualityReport(
      score: score,
      strengths: strengths.take(4).toList(growable: false),
      suggestions: suggestions,
    );
  }

  static int _computeScore({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String jobTitle,
    required int contactChannels,
    required String summary,
    required List<Experience> experienceEntries,
    required int experienceWithImpact,
    required int experienceMissingDates,
    required List<Education> educationEntries,
    required int educationDetailed,
    required int skillsCount,
    required int skillsCategories,
    required List<Project> projectEntries,
    required int projectsWithLinks,
    required int projectsWithStack,
    required List<Certification> certifications,
    required int certificationsWithMetadata,
    required List<Language> languages,
    required List<CustomSection> customSections,
  }) {
    var score = 0;

    if (fullName.isNotEmpty) score += 8;
    if (email.isNotEmpty) score += 8;
    if (phone.isNotEmpty) score += 8;
    if (address.isNotEmpty) score += 4;
    if (jobTitle.isNotEmpty) score += 6;
    if (contactChannels >= 3) score += 6;

    if (summary.isNotEmpty) {
      score += 10;
      if (summary.length >= 80) score += 4;
      if (summary.length >= 160) score += 2;
    }

    if (experienceEntries.isNotEmpty) {
      score += 18;
      if (experienceWithImpact > 0) score += 8;
      if (experienceMissingDates == 0) score += 6;
    }

    if (educationEntries.isNotEmpty) {
      score += 8;
      if (educationDetailed == educationEntries.length) score += 4;
    }

    if (skillsCount >= 8) {
      score += 12;
    } else if (skillsCount >= 4) {
      score += 8;
    } else if (skillsCount > 0) {
      score += 4;
    }

    if (skillsCategories >= 2) {
      score += 4;
    }

    if (projectEntries.isNotEmpty) {
      score += 7;
      if (projectsWithStack > 0) score += 3;
      if (projectsWithLinks > 0) score += 3;
    }

    if (certifications.isNotEmpty) {
      score += 3;
      if (certificationsWithMetadata > 0) score += 2;
    }

    if (languages.isNotEmpty) {
      score += 3;
    }

    if (customSections.isNotEmpty) {
      score += 2;
    }

    return score.clamp(0, 100);
  }

  static int _priorityWeight(ResumeQualityPriority priority) {
    switch (priority) {
      case ResumeQualityPriority.high:
        return 3;
      case ResumeQualityPriority.medium:
        return 2;
      case ResumeQualityPriority.low:
        return 1;
    }
  }
}