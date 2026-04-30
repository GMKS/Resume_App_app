import '../models/resume_model.dart';

class StartupOptionalSectionConfig {
  final String id;
  final String title;
  final String description;
  final String emptyPrompt;

  const StartupOptionalSectionConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.emptyPrompt,
  });
}

enum StartupProfileType {
  tech,
  entryLevel,
  education,
  skilledTrade,
  general,
}

const _startupSectionCatalog = <String, StartupOptionalSectionConfig>{
  'startup_achievements': StartupOptionalSectionConfig(
    id: 'startup_achievements',
    title: 'Achievements',
    description: 'Highlight outcomes, wins, and measurable impact.',
    emptyPrompt: 'Add revenue wins, launches, growth metrics, or standout results.',
  ),
  'startup_tools': StartupOptionalSectionConfig(
    id: 'startup_tools',
    title: 'Tools',
    description: 'Show the tools, platforms, or systems you work with.',
    emptyPrompt: 'Add product, engineering, design, lab, or shop-floor tools you use.',
  ),
  'startup_internships': StartupOptionalSectionConfig(
    id: 'startup_internships',
    title: 'Internships',
    description: 'Useful for fresher, student, and early-career profiles.',
    emptyPrompt: 'Add internship roles, responsibilities, and outcomes.',
  ),
  'startup_teaching_experience': StartupOptionalSectionConfig(
    id: 'startup_teaching_experience',
    title: 'Teaching Experience',
    description: 'Capture classroom, mentoring, training, or curriculum work.',
    emptyPrompt: 'Add classes taught, subjects covered, or mentoring contributions.',
  ),
  'startup_licenses': StartupOptionalSectionConfig(
    id: 'startup_licenses',
    title: 'Licenses',
    description: 'List role-critical licenses, permits, or registrations.',
    emptyPrompt: 'Add license name, issuing authority, and current status.',
  ),
  'startup_references': StartupOptionalSectionConfig(
    id: 'startup_references',
    title: 'References',
    description: 'Add references when the profile type commonly expects them.',
    emptyPrompt: 'Add reference name, role, organization, and contact notes.',
  ),
};

StartupOptionalSectionConfig? startupSectionConfigById(String id) {
  return _startupSectionCatalog[id];
}

List<StartupOptionalSectionConfig> startupAllOptionalSectionConfigs() {
  return _startupSectionCatalog.values.toList(growable: false);
}

bool isStartupOptionalSectionKey(String key) {
  return _startupSectionCatalog.containsKey(key);
}

StartupProfileType detectStartupProfileType(ResumeModel resume) {
  final raw = '${resume.personalInfo.jobTitle ?? ''} ${resume.title}'.toLowerCase();

  if (RegExp(
    r'teacher|faculty|lecturer|professor|tutor|trainer|academic|research|educat',
  ).hasMatch(raw)) {
    return StartupProfileType.education;
  }

  if (RegExp(
    r'fresher|student|graduate|intern|entry level|entry-level|trainee|apprentice',
  ).hasMatch(raw)) {
    return StartupProfileType.entryLevel;
  }

  if (RegExp(
    r'welder|electrician|mechanic|technician|operator|driver|nurse|plumber|fitter|fabricator|foreman',
  ).hasMatch(raw)) {
    return StartupProfileType.skilledTrade;
  }

  if (RegExp(
    r'developer|engineer|product|designer|growth|marketing|founder|startup|software|data|qa|test|ui|ux|devops',
  ).hasMatch(raw)) {
    return StartupProfileType.tech;
  }

  return StartupProfileType.general;
}

String startupProfileLabel(StartupProfileType profileType) {
  switch (profileType) {
    case StartupProfileType.tech:
      return 'startup and product';
    case StartupProfileType.entryLevel:
      return 'entry-level';
    case StartupProfileType.education:
      return 'education';
    case StartupProfileType.skilledTrade:
      return 'trade and field';
    case StartupProfileType.general:
      return 'general';
  }
}

List<StartupOptionalSectionConfig> startupRecommendedSections(ResumeModel resume) {
  switch (detectStartupProfileType(resume)) {
    case StartupProfileType.tech:
      return [
        _startupSectionCatalog['startup_achievements']!,
        _startupSectionCatalog['startup_tools']!,
      ];
    case StartupProfileType.entryLevel:
      return [
        _startupSectionCatalog['startup_internships']!,
        _startupSectionCatalog['startup_achievements']!,
        _startupSectionCatalog['startup_tools']!,
      ];
    case StartupProfileType.education:
      return [
        _startupSectionCatalog['startup_teaching_experience']!,
        _startupSectionCatalog['startup_licenses']!,
        _startupSectionCatalog['startup_references']!,
      ];
    case StartupProfileType.skilledTrade:
      return [
        _startupSectionCatalog['startup_tools']!,
        _startupSectionCatalog['startup_licenses']!,
        _startupSectionCatalog['startup_references']!,
      ];
    case StartupProfileType.general:
      return [
        _startupSectionCatalog['startup_achievements']!,
        _startupSectionCatalog['startup_tools']!,
      ];
  }
}

List<String> startupOptionalSectionKeys(ResumeModel resume) {
  final recommended = startupRecommendedSections(resume).map((section) => section.id).toList();
  final existingKnown = resume.customSections
      .map((section) => section.id)
      .where(isStartupOptionalSectionKey)
      .where((id) => !recommended.contains(id))
      .toList();
  return [...recommended, ...existingKnown];
}

List<String> startupSectionOrder(ResumeModel resume) {
  final optionalKeys = startupOptionalSectionKeys(resume);
  return [
    'summary',
    ...optionalKeys,
    'skills',
    'experience',
    'projects',
    'education',
    'certifications',
    'languages',
  ];
}

List<CustomSection> ensureStartupProfileSections(ResumeModel resume) {
  if (resume.templateId != 'startup') {
    return List<CustomSection>.from(resume.customSections);
  }

  final recommended = startupRecommendedSections(resume);
  final sections = List<CustomSection>.from(resume.customSections);

  for (final config in recommended) {
    final index = sections.indexWhere((section) => section.id == config.id);
    if (index == -1) {
      sections.add(CustomSection(id: config.id, title: config.title));
      continue;
    }

    if (sections[index].title.trim().isEmpty) {
      sections[index] = sections[index].copyWith(title: config.title);
    }
  }

  return sections;
}