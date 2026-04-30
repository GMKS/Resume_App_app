import 'package:uuid/uuid.dart';

import '../models/resume_model.dart';
import '../utils/user_custom_sections.dart';

class ResumeImportMapper {
  static const Uuid _uuid = Uuid();

  static ResumeModel applyParsedData({
    required ResumeModel resume,
    required Map<String, dynamic> parsedData,
  }) {
    String? stringAt(String key) => _normalizedString(parsedData[key]);

    final updatedPersonalInfo = resume.personalInfo.copyWith(
      fullName: stringAt('fullName') ?? resume.personalInfo.fullName,
      email: stringAt('email') ?? resume.personalInfo.email,
      phone: stringAt('phone') ?? resume.personalInfo.phone,
      address: stringAt('address') ?? resume.personalInfo.address,
      jobTitle: stringAt('jobTitle') ?? resume.personalInfo.jobTitle,
      linkedIn: stringAt('linkedIn') ?? resume.personalInfo.linkedIn,
      github: stringAt('github') ?? resume.personalInfo.github,
      website: stringAt('website') ?? resume.personalInfo.website,
    );

    final experiences = _experiencesFrom(parsedData['experience']);
    final education = _educationFrom(parsedData['education']);
    final skills = _skillsFrom(parsedData['skills']);
    final certifications = _certificationsFrom(parsedData['certifications']);
    final languages = _languagesFrom(parsedData['languages']);
    final projects = _projectsFrom(parsedData['projects']);
    final hobbies = _stringList(parsedData['hobbies']);
    final references = _referencesFrom(parsedData['references']);
    final parsedCustomSections = _customSectionsFrom(parsedData['customSections']);

    return resume.copyWith(
      personalInfo: updatedPersonalInfo,
      objective: stringAt('objective') ?? resume.objective,
      experience: experiences.isNotEmpty ? experiences : resume.experience,
      education: education.isNotEmpty ? education : resume.education,
      skills: skills.isNotEmpty ? skills : resume.skills,
      certifications: certifications.isNotEmpty ? certifications : resume.certifications,
      languages: languages.isNotEmpty ? languages : resume.languages,
      projects: projects.isNotEmpty ? projects : resume.projects,
      hobbies: hobbies.isNotEmpty ? hobbies : resume.hobbies,
      references: references.isNotEmpty ? references : resume.references,
      customSections: _mergedCustomSections(
        resume: resume,
        parsedSections: parsedCustomSections,
      ),
      updatedAt: DateTime.now(),
    );
  }

  static List<Experience> _experiencesFrom(dynamic value) {
    return _listOfMaps(value).map((entry) {
      final isCurrent = _boolValue(entry['isCurrentlyWorking']) ??
          _boolValue(entry['current']) ??
          _boolValue(entry['present']) ??
          false;
      final startDate = _dateValue(
            entry['startDate'] ?? entry['from'] ?? entry['dateStarted'],
          ) ??
          _dateFromParts(
            year: _intValue(entry['startYear']) ?? _intValue(entry['fromYear']),
            month:
                _intValue(entry['startMonth']) ?? _intValue(entry['fromMonth']),
            fallback: DateTime.now(),
          );
      final parsedEndDate = _dateValue(
        entry['endDate'] ?? entry['to'] ?? entry['dateEnded'],
      );
      final endDate = isCurrent
          ? null
          : parsedEndDate ??
              _dateFromParts(
                year: _intValue(entry['endYear']) ?? _intValue(entry['toYear']),
                month:
                    _intValue(entry['endMonth']) ?? _intValue(entry['toMonth']),
              );
      final description = _joinedText(
        entry['description'] ??
            entry['summary'] ??
            entry['responsibilities'] ??
            entry['details'],
      );
      final achievements = _stringList(
        entry['achievements'] ?? entry['highlights'] ?? entry['bullets'],
      );

      return Experience(
        id: _uuid.v4(),
        company: _normalizedString(entry['company']) ??
            _normalizedString(entry['employer']) ??
            '',
        position: _normalizedString(entry['position']) ??
            _normalizedString(entry['title']) ??
            _normalizedString(entry['role']) ??
            '',
        location: _normalizedString(entry['location']) ??
            _normalizedString(entry['city']),
        startDate: startDate,
        endDate: endDate,
        isCurrentlyWorking: isCurrent || endDate == null,
        description: description,
        achievements: achievements,
      );
    }).where(_hasExperienceContent).toList(growable: false);
  }

  static List<Education> _educationFrom(dynamic value) {
    return _listOfMaps(value).map((entry) {
      final isCurrent = _boolValue(entry['isCurrentlyStudying']) ??
          _boolValue(entry['current']) ??
          false;
      final startDate = _dateValue(entry['startDate']) ??
          _dateFromParts(
            year: _intValue(entry['startYear']),
            fallback: DateTime(DateTime.now().year),
          );
      final endDate = isCurrent
          ? null
          : _dateValue(entry['endDate']) ??
              _dateFromParts(year: _intValue(entry['endYear']));

      return Education(
        id: _uuid.v4(),
        institution: _normalizedString(entry['institution']) ??
            _normalizedString(entry['school']) ??
            _normalizedString(entry['university']) ??
            '',
        degree: _normalizedString(entry['degree']) ?? '',
        fieldOfStudy: _normalizedString(entry['fieldOfStudy']) ??
            _normalizedString(entry['major']) ??
            _normalizedString(entry['field']) ??
            '',
        startDate: startDate,
        endDate: endDate,
        isCurrentlyStudying: isCurrent || endDate == null,
        grade: _normalizedString(entry['grade']) ??
            _normalizedString(entry['gpa']),
        description: _joinedText(entry['description'] ?? entry['details']),
        location: _normalizedString(entry['location']) ??
            _normalizedString(entry['city']),
      );
    }).where(_hasEducationContent).toList(growable: false);
  }

  static List<Skill> _skillsFrom(dynamic value) {
    final seen = <String>{};
    final skills = <Skill>[];

    for (final entry in _listValue(value)) {
      String? name;
      String? category;
      int proficiency = 3;

      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        name = _normalizedString(map['name']) ??
            _normalizedString(map['skill']) ??
            _normalizedString(map['title']) ??
            _normalizedString(map['technology']);
        category = _normalizedString(map['category']) ??
            _normalizedString(map['group']);
        proficiency = _intValue(map['proficiency']) ??
            _intValue(map['level']) ??
            3;
      } else {
        name = _normalizedString(entry);
      }

      if (name == null) {
        continue;
      }

      final key = name.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }

      skills.add(
        Skill(
          id: _uuid.v4(),
          name: name,
          proficiency: proficiency.clamp(1, 5),
          category: category,
        ),
      );
    }

    return List<Skill>.unmodifiable(skills);
  }

  static List<Certification> _certificationsFrom(dynamic value) {
    return _listOfMaps(value).map((entry) {
      final issueDate = _dateValue(entry['issueDate']) ??
          _dateFromParts(year: _intValue(entry['issueYear']));
      final expiryDate = _dateValue(entry['expiryDate']) ??
          _dateFromParts(year: _intValue(entry['expiryYear']));

      return Certification(
        id: _uuid.v4(),
        name: _normalizedString(entry['name']) ??
            _normalizedString(entry['title']) ??
            '',
        issuer: _normalizedString(entry['issuer']) ??
            _normalizedString(entry['organization']) ??
            '',
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialId: _normalizedString(entry['credentialId']) ??
            _normalizedString(entry['licenseNumber']),
        credentialUrl: _normalizedString(entry['credentialUrl']) ??
            _normalizedString(entry['url']),
      );
    }).where(_hasCertificationContent).toList(growable: false);
  }

  static List<Language> _languagesFrom(dynamic value) {
    return _listValue(value).map((entry) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        return Language(
          id: _uuid.v4(),
          name: _normalizedString(map['name']) ??
              _normalizedString(map['language']) ??
              '',
          proficiency: _normalizedString(map['proficiency']) ??
              _normalizedString(map['level']) ??
              'Professional',
        );
      }

      return Language(
        id: _uuid.v4(),
        name: _normalizedString(entry) ?? '',
        proficiency: 'Professional',
      );
    }).where((language) => language.name.trim().isNotEmpty).toList(growable: false);
  }

  static List<Project> _projectsFrom(dynamic value) {
    return _listOfMaps(value).map((entry) {
      return Project(
        id: _uuid.v4(),
        title: _normalizedString(entry['title']) ??
            _normalizedString(entry['name']) ??
            '',
        description: _joinedText(
          entry['description'] ?? entry['summary'] ?? entry['details'],
        ),
        technologies: _stringList(entry['technologies'] ?? entry['techStack']),
        url: _normalizedString(entry['url']) ??
            _normalizedString(entry['link']) ??
            _normalizedString(entry['website']),
        startDate: _dateValue(entry['startDate']) ??
            _dateFromParts(year: _intValue(entry['startYear'])),
        endDate: _dateValue(entry['endDate']) ??
            _dateFromParts(year: _intValue(entry['endYear'])),
      );
    }).where(_hasProjectContent).toList(growable: false);
  }

  static List<Reference> _referencesFrom(dynamic value) {
    return _listValue(value).map((entry) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        return Reference(
          id: _uuid.v4(),
          name: _normalizedString(map['name']) ?? '',
          position: _normalizedString(map['position']) ??
              _normalizedString(map['title']) ??
              '',
          company: _normalizedString(map['company']) ??
              _normalizedString(map['organization']) ??
              '',
          email: _normalizedString(map['email']) ?? '',
          phone: _normalizedString(map['phone']) ?? '',
          relationship: _normalizedString(map['relationship']) ??
              _normalizedString(map['relation']),
        );
      }

      return Reference(
        id: _uuid.v4(),
        name: _normalizedString(entry) ?? '',
      );
    }).where(_hasReferenceContent).toList(growable: false);
  }

  static List<CustomSection> _customSectionsFrom(dynamic value) {
    return _listOfMaps(value).asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final title = normalizeUserCustomSectionTitle(
        _normalizedString(section['title']) ??
            _normalizedString(section['name']) ??
            _normalizedString(section['heading']) ??
            '',
      );
      final items = _customSectionItemsFrom(section['items'] ?? section['entries']);
      final fallbackItem = _customSectionItemFromMap(section);

      return CustomSection(
        id: _normalizedString(section['id'])?.trim().isNotEmpty == true
            ? _normalizedString(section['id'])!
            : buildUserCustomSectionId(),
        title: title,
        items: items.isNotEmpty
            ? items
            : (fallbackItem == null ? const <CustomSectionItem>[] : <CustomSectionItem>[fallbackItem]),
        order: _intValue(section['order']) ?? index,
      );
    }).where(_hasCustomSectionContent).toList(growable: false);
  }

  static List<CustomSectionItem> _customSectionItemsFrom(dynamic value) {
    return _listValue(value).map((entry) {
      if (entry is Map) {
        return _customSectionItemFromMap(
          Map<String, dynamic>.from(entry),
        );
      }
      final content = _normalizedString(entry);
      if (content == null) {
        return null;
      }
      return CustomSectionItem(
        id: _uuid.v4(),
        title: content,
      );
    }).whereType<CustomSectionItem>().toList(growable: false);
  }

  static CustomSectionItem? _customSectionItemFromMap(Map<String, dynamic> map) {
    final title = _normalizedString(map['title']) ??
        _normalizedString(map['heading']) ??
        _normalizedString(map['name']);
    final subtitle = _normalizedString(map['subtitle']) ??
        _normalizedString(map['role']) ??
        _normalizedString(map['organization']);
    final description = _joinedText(
      map['description'] ?? map['content'] ?? map['details'] ?? map['summary'],
    );
    final date = _dateValue(map['date']) ?? _dateValue(map['year']);

    if ([title, subtitle, description].every((value) => (value ?? '').isEmpty) &&
        date == null) {
      return null;
    }

    return CustomSectionItem(
      id: _uuid.v4(),
      title: title ?? '',
      subtitle: subtitle,
      description: description.isEmpty ? null : description,
      date: date,
    );
  }

  static List<CustomSection> _mergedCustomSections({
    required ResumeModel resume,
    required List<CustomSection> parsedSections,
  }) {
    if (parsedSections.isEmpty) {
      return resume.customSections;
    }

    final existingSections = orderedUserCustomSections(resume);
    final parsedByTitle = <String, CustomSection>{
      for (final section in parsedSections)
        normalizeUserCustomSectionTitle(section.title).toLowerCase(): section,
    };
    final orderedSections = <CustomSection>[];
    final consumedTitles = <String>{};

    for (final section in existingSections) {
      final key = normalizeUserCustomSectionTitle(section.title).toLowerCase();
      final parsed = parsedByTitle[key];
      if (parsed != null) {
        orderedSections.add(parsed.copyWith(order: orderedSections.length));
        consumedTitles.add(key);
      } else {
        orderedSections.add(section.copyWith(order: orderedSections.length));
      }
    }

    for (final section in parsedSections) {
      final key = normalizeUserCustomSectionTitle(section.title).toLowerCase();
      if (consumedTitles.add(key)) {
        orderedSections.add(section.copyWith(order: orderedSections.length));
      }
    }

    return mergeUserCustomSections(
      existingSections: resume.customSections,
      orderedUserSections: orderedSections,
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    return _listValue(value)
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  static List<dynamic> _listValue(dynamic value) {
    if (value is List) {
      return value;
    }
    if (value is String) {
      return value
          .split(RegExp(r'[\n,;|]+'))
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <dynamic>[];
  }

  static List<String> _stringList(dynamic value) {
    final seen = <String>{};
    final results = <String>[];

    for (final entry in _listValue(value)) {
      final normalized = entry is Map
          ? _normalizedString(
              (entry)['name'] ??
                  entry['title'] ??
                  entry['value'] ??
                  entry['label'],
            )
          : _normalizedString(entry);
      if (normalized == null) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      results.add(normalized);
    }

    return List<String>.unmodifiable(results);
  }

  static String _joinedText(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    if (value is List) {
      return value
          .map(_normalizedString)
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .join('\n');
    }
    return '';
  }

  static String? _normalizedString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  static bool? _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }
    final text = _normalizedString(value)?.toLowerCase();
    if (text == null) {
      return null;
    }
    if (text == 'true' || text == 'yes' || text == 'present') {
      return true;
    }
    if (text == 'false' || text == 'no') {
      return false;
    }
    return null;
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final text = _normalizedString(value);
    if (text == null) {
      return null;
    }
    return int.tryParse(text);
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime(value);
    }
    final text = _normalizedString(value);
    if (text == null) {
      return null;
    }

    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed;
    }

    final year = RegExp(r'(19|20)\d{2}').firstMatch(text)?.group(0);
    return year == null ? null : DateTime(int.parse(year));
  }

  static DateTime _dateFromParts({
    required int? year,
    int? month,
    DateTime? fallback,
  }) {
    final resolvedYear = year ?? fallback?.year ?? DateTime.now().year;
    final resolvedMonth = (month ?? fallback?.month ?? 1).clamp(1, 12);
    return DateTime(resolvedYear, resolvedMonth);
  }

  static bool _hasExperienceContent(Experience experience) {
    return experience.company.trim().isNotEmpty ||
        experience.position.trim().isNotEmpty ||
        experience.description.trim().isNotEmpty ||
        experience.achievements.isNotEmpty;
  }

  static bool _hasEducationContent(Education education) {
    return education.institution.trim().isNotEmpty ||
        education.degree.trim().isNotEmpty ||
        education.fieldOfStudy.trim().isNotEmpty ||
        (education.description ?? '').trim().isNotEmpty;
  }

  static bool _hasCertificationContent(Certification certification) {
    return certification.name.trim().isNotEmpty ||
        certification.issuer.trim().isNotEmpty;
  }

  static bool _hasProjectContent(Project project) {
    return project.title.trim().isNotEmpty ||
        project.description.trim().isNotEmpty ||
        project.technologies.isNotEmpty;
  }

  static bool _hasReferenceContent(Reference reference) {
    return reference.name.trim().isNotEmpty ||
        reference.company.trim().isNotEmpty ||
        reference.email.trim().isNotEmpty ||
        reference.phone.trim().isNotEmpty;
  }

  static bool _hasCustomSectionContent(CustomSection section) {
    return section.title.trim().isNotEmpty && section.items.isNotEmpty;
  }
}