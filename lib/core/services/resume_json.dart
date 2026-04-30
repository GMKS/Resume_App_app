import '../models/resume_model.dart';

/// Converts [ResumeModel] to/from plain Map so it can be stored in Supabase.
class ResumeJson {
  // ── Serialise ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> toMap(ResumeModel r) => {
        'id': r.id,
        'title': r.title,
        'objective': r.objective,
        'templateId': r.templateId,
        'colorScheme': r.colorScheme,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'hobbies': r.hobbies,
        'personalInfo': _piToMap(r.personalInfo),
        'education': r.education.map(_eduToMap).toList(),
        'experience': r.experience.map(_expToMap).toList(),
        'skills': r.skills.map(_skillToMap).toList(),
        'projects': r.projects.map(_projToMap).toList(),
        'certifications': r.certifications.map(_certToMap).toList(),
        'languages': r.languages.map(_langToMap).toList(),
        'references': r.references.map(_refToMap).toList(),
        'customSections': r.customSections.map(_csToMap).toList(),
        'writingLanguage': r.writingLanguage,
        'fontFamily': r.fontFamily,
        'layoutStyle': r.layoutStyle,
      };

  static Map<String, dynamic> _piToMap(PersonalInfo p) => {
        'fullName': p.fullName,
        'email': p.email,
        'phone': p.phone,
        'address': p.address,
        'linkedIn': p.linkedIn,
        'github': p.github,
        'website': p.website,
        'profileImage': p.profileImage,
        'jobTitle': p.jobTitle,
        'dateOfBirth': p.dateOfBirth?.toIso8601String(),
      };

  static Map<String, dynamic> _eduToMap(Education e) => {
        'id': e.id,
        'institution': e.institution,
        'degree': e.degree,
        'fieldOfStudy': e.fieldOfStudy,
        'startDate': e.startDate.toIso8601String(),
        'endDate': e.endDate?.toIso8601String(),
        'isCurrentlyStudying': e.isCurrentlyStudying,
        'grade': e.grade,
        'description': e.description,
        'location': e.location,
      };

  static Map<String, dynamic> _expToMap(Experience e) => {
        'id': e.id,
        'company': e.company,
        'position': e.position,
        'location': e.location,
        'startDate': e.startDate.toIso8601String(),
        'endDate': e.endDate?.toIso8601String(),
        'isCurrentlyWorking': e.isCurrentlyWorking,
        'description': e.description,
        'achievements': e.achievements,
      };

  static Map<String, dynamic> _skillToMap(Skill s) => {
        'id': s.id,
        'name': s.name,
        'proficiency': s.proficiency,
        'category': s.category,
      };

  static Map<String, dynamic> _projToMap(Project p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'url': p.url,
        'technologies': p.technologies,
        'startDate': p.startDate?.toIso8601String(),
        'endDate': p.endDate?.toIso8601String(),
      };

  static Map<String, dynamic> _certToMap(Certification c) => {
        'id': c.id,
        'name': c.name,
        'issuer': c.issuer,
        'issueDate': c.issueDate?.toIso8601String(),
        'expiryDate': c.expiryDate?.toIso8601String(),
        'credentialId': c.credentialId,
        'credentialUrl': c.credentialUrl,
      };

  static Map<String, dynamic> _langToMap(Language l) => {
        'id': l.id,
        'name': l.name,
        'proficiency': l.proficiency,
      };

  static Map<String, dynamic> _refToMap(Reference r) => {
        'id': r.id,
        'name': r.name,
        'position': r.position,
        'company': r.company,
        'email': r.email,
        'phone': r.phone,
        'relationship': r.relationship,
      };

  static Map<String, dynamic> _csToMap(CustomSection cs) => {
        'id': cs.id,
        'title': cs.title,
        'items': cs.items.map(_csiToMap).toList(),
      'order': cs.order,
      };

  static Map<String, dynamic> _csiToMap(CustomSectionItem i) => {
        'id': i.id,
        'title': i.title,
        'subtitle': i.subtitle,
        'description': i.description,
        'date': i.date?.toIso8601String(),
      };

  // ── Deserialise ────────────────────────────────────────────────────────────

  static ResumeModel fromMap(Map<String, dynamic> m) {
    final pi = m['personalInfo'] as Map<String, dynamic>? ?? {};
    return ResumeModel(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      objective: m['objective'] as String?,
      templateId: m['templateId'] as String? ?? 'modern',
      colorScheme: m['colorScheme'] as int? ?? 0,
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: DateTime.parse(m['updatedAt'] as String),
      hobbies: List<String>.from(m['hobbies'] ?? []),
      personalInfo: _piFromMap(pi),
      education: (m['education'] as List<dynamic>? ?? []).map((e) => _eduFromMap(e as Map<String, dynamic>)).toList(),
      experience: (m['experience'] as List<dynamic>? ?? []).map((e) => _expFromMap(e as Map<String, dynamic>)).toList(),
      skills: (m['skills'] as List<dynamic>? ?? []).map((e) => _skillFromMap(e as Map<String, dynamic>)).toList(),
      projects: (m['projects'] as List<dynamic>? ?? []).map((e) => _projFromMap(e as Map<String, dynamic>)).toList(),
      certifications: (m['certifications'] as List<dynamic>? ?? []).map((e) => _certFromMap(e as Map<String, dynamic>)).toList(),
      languages: (m['languages'] as List<dynamic>? ?? []).map((e) => _langFromMap(e as Map<String, dynamic>)).toList(),
      references: (m['references'] as List<dynamic>? ?? []).map((e) => _refFromMap(e as Map<String, dynamic>)).toList(),
      customSections: (m['customSections'] as List<dynamic>? ?? []).map((e) => _csFromMap(e as Map<String, dynamic>)).toList(),
      writingLanguage: m['writingLanguage'] as String? ?? 'English',
      fontFamily: m['fontFamily'] as String? ?? 'Roboto',
      layoutStyle: m['layoutStyle'] as String? ?? 'standard',
    );
  }

  static PersonalInfo _piFromMap(Map<String, dynamic> m) => PersonalInfo(
        fullName: m['fullName'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        address: m['address'] as String? ?? '',
        linkedIn: m['linkedIn'] as String?,
        github: m['github'] as String?,
        website: m['website'] as String?,
        profileImage: m['profileImage'] as String?,
        jobTitle: m['jobTitle'] as String?,
        dateOfBirth: m['dateOfBirth'] != null ? DateTime.parse(m['dateOfBirth'] as String) : null,
      );

  static Education _eduFromMap(Map<String, dynamic> m) => Education(
        id: m['id'] as String,
        institution: m['institution'] as String? ?? '',
        degree: m['degree'] as String? ?? '',
        fieldOfStudy: m['fieldOfStudy'] as String? ?? '',
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        isCurrentlyStudying: m['isCurrentlyStudying'] as bool? ?? false,
        grade: m['grade'] as String?,
        description: m['description'] as String?,
        location: m['location'] as String?,
      );

  static Experience _expFromMap(Map<String, dynamic> m) => Experience(
        id: m['id'] as String,
        company: m['company'] as String? ?? '',
        position: m['position'] as String? ?? '',
        location: m['location'] as String?,
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        isCurrentlyWorking: m['isCurrentlyWorking'] as bool? ?? false,
        description: m['description'] as String? ?? '',
        achievements: List<String>.from(m['achievements'] ?? []),
      );

  static Skill _skillFromMap(Map<String, dynamic> m) => Skill(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        proficiency: m['proficiency'] as int? ?? 3,
        category: m['category'] as String?,
      );

  static Project _projFromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        url: m['url'] as String?,
        technologies: List<String>.from(m['technologies'] ?? []),
        startDate: m['startDate'] != null ? DateTime.parse(m['startDate'] as String) : null,
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
      );

  static Certification _certFromMap(Map<String, dynamic> m) => Certification(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        issuer: m['issuer'] as String? ?? '',
        issueDate: m['issueDate'] != null ? DateTime.parse(m['issueDate'] as String) : null,
        expiryDate: m['expiryDate'] != null ? DateTime.parse(m['expiryDate'] as String) : null,
        credentialId: m['credentialId'] as String?,
        credentialUrl: m['credentialUrl'] as String?,
      );

  static Language _langFromMap(Map<String, dynamic> m) => Language(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        proficiency: m['proficiency'] as String? ?? 'Professional',
      );

  static Reference _refFromMap(Map<String, dynamic> m) => Reference(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        position: m['position'] as String? ?? '',
        company: m['company'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        relationship: m['relationship'] as String?,
      );

  static CustomSection _csFromMap(Map<String, dynamic> m) => CustomSection(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        items: (m['items'] as List<dynamic>? ?? []).map((e) => _csiFromMap(e as Map<String, dynamic>)).toList(),
      order: m['order'] as int? ?? 0,
      );

  static CustomSectionItem _csiFromMap(Map<String, dynamic> m) => CustomSectionItem(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String?,
        description: m['description'] as String?,
        date: m['date'] != null ? DateTime.parse(m['date'] as String) : null,
      );
}
