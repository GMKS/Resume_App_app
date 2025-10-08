/// Model for custom resume content
class CustomResumeData {
  // Personal Information
  final String fullName;
  final String jobTitle;
  final ContactInfo contactInfo;
  final String summary;

  // Main Sections
  final List<Skill> skills;
  final List<Experience> experience;
  final List<Education> education;
  final List<Certification> certifications;
  final List<Project> projects;
  final List<Language> languages;
  final List<String> hobbies;
  final List<Achievement> achievements;
  final List<Reference> references;

  // Settings
  final bool showReferences;

  const CustomResumeData({
    this.fullName = '',
    this.jobTitle = '',
    this.contactInfo = const ContactInfo(),
    this.summary = '',
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.certifications = const [],
    this.projects = const [],
    this.languages = const [],
    this.hobbies = const [],
    this.achievements = const [],
    this.references = const [],
    this.showReferences = false,
  });

  CustomResumeData copyWith({
    String? fullName,
    String? jobTitle,
    ContactInfo? contactInfo,
    String? summary,
    List<Skill>? skills,
    List<Experience>? experience,
    List<Education>? education,
    List<Certification>? certifications,
    List<Project>? projects,
    List<Language>? languages,
    List<String>? hobbies,
    List<Achievement>? achievements,
    List<Reference>? references,
    bool? showReferences,
  }) {
    return CustomResumeData(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      contactInfo: contactInfo ?? this.contactInfo,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      languages: languages ?? this.languages,
      hobbies: hobbies ?? this.hobbies,
      achievements: achievements ?? this.achievements,
      references: references ?? this.references,
      showReferences: showReferences ?? this.showReferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'jobTitle': jobTitle,
      'contactInfo': contactInfo.toJson(),
      'summary': summary,
      'skills': skills.map((s) => s.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'languages': languages.map((l) => l.toJson()).toList(),
      'hobbies': hobbies,
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'references': references.map((r) => r.toJson()).toList(),
      'showReferences': showReferences,
    };
  }

  factory CustomResumeData.fromJson(Map<String, dynamic> json) {
    return CustomResumeData(
      fullName: json['fullName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
      summary: json['summary'] ?? '',
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((s) => Skill.fromJson(s))
          .toList(),
      experience: (json['experience'] as List<dynamic>? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList(),
      education: (json['education'] as List<dynamic>? ?? [])
          .map((e) => Education.fromJson(e))
          .toList(),
      certifications: (json['certifications'] as List<dynamic>? ?? [])
          .map((c) => Certification.fromJson(c))
          .toList(),
      projects: (json['projects'] as List<dynamic>? ?? [])
          .map((p) => Project.fromJson(p))
          .toList(),
      languages: (json['languages'] as List<dynamic>? ?? [])
          .map((l) => Language.fromJson(l))
          .toList(),
      hobbies: List<String>.from(json['hobbies'] ?? []),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((a) => Achievement.fromJson(a))
          .toList(),
      references: (json['references'] as List<dynamic>? ?? [])
          .map((r) => Reference.fromJson(r))
          .toList(),
      showReferences: json['showReferences'] ?? false,
    );
  }
}

/// Contact Information Model
class ContactInfo {
  final String email;
  final String phone;
  final String linkedin;
  final String website;
  final String location;

  const ContactInfo({
    this.email = '',
    this.phone = '',
    this.linkedin = '',
    this.website = '',
    this.location = '',
  });

  ContactInfo copyWith({
    String? email,
    String? phone,
    String? linkedin,
    String? website,
    String? location,
  }) {
    return ContactInfo(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'linkedin': linkedin,
      'website': website,
      'location': location,
    };
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      linkedin: json['linkedin'] ?? '',
      website: json['website'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

/// Skill Model with optional progress/proficiency
class Skill {
  final String name;
  final String? icon;
  final double? proficiency; // 0.0 to 1.0
  final String category;

  const Skill({
    required this.name,
    this.icon,
    this.proficiency,
    this.category = 'General',
  });

  Skill copyWith({
    String? name,
    String? icon,
    double? proficiency,
    String? category,
  }) {
    return Skill(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      proficiency: proficiency ?? this.proficiency,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'proficiency': proficiency,
      'category': category,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'] ?? '',
      icon: json['icon'],
      proficiency: json['proficiency']?.toDouble(),
      category: json['category'] ?? 'General',
    );
  }
}

/// Experience Model
class Experience {
  final String jobTitle;
  final String companyName;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrentJob;
  final String description;

  const Experience({
    required this.jobTitle,
    required this.companyName,
    this.location = '',
    this.startDate,
    this.endDate,
    this.isCurrentJob = false,
    this.description = '',
  });

  Experience copyWith({
    String? jobTitle,
    String? companyName,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrentJob,
    String? description,
  }) {
    return Experience(
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrentJob: isCurrentJob ?? this.isCurrentJob,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobTitle': jobTitle,
      'companyName': companyName,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrentJob': isCurrentJob,
      'description': description,
    };
  }

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCurrentJob: json['isCurrentJob'] ?? false,
      description: json['description'] ?? '',
    );
  }
}

/// Education Model
class Education {
  final String degree;
  final String institution;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final String? gpa;

  const Education({
    required this.degree,
    required this.institution,
    this.location = '',
    this.startDate,
    this.endDate,
    this.description = '',
    this.gpa,
  });

  Education copyWith({
    String? degree,
    String? institution,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? gpa,
  }) {
    return Education(
      degree: degree ?? this.degree,
      institution: institution ?? this.institution,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      gpa: gpa ?? this.gpa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'gpa': gpa,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'] ?? '',
      institution: json['institution'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'] ?? '',
      gpa: json['gpa'],
    );
  }
}

/// Certification Model
class Certification {
  final String name;
  final String issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? credentialId;
  final String? credentialUrl;

  const Certification({
    required this.name,
    required this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  Certification copyWith({
    String? name,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return Certification(
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      credentialId: credentialId ?? this.credentialId,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'credentialId': credentialId,
      'credentialUrl': credentialUrl,
    };
  }

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      credentialId: json['credentialId'],
      credentialUrl: json['credentialUrl'],
    );
  }
}

/// Project Model
class Project {
  final String title;
  final String description;
  final List<String> technologies;
  final String? projectUrl;
  final String? githubUrl;
  final String? imagePath;
  final DateTime? startDate;
  final DateTime? endDate;

  const Project({
    required this.title,
    this.description = '',
    this.technologies = const [],
    this.projectUrl,
    this.githubUrl,
    this.imagePath,
    this.startDate,
    this.endDate,
  });

  Project copyWith({
    String? title,
    String? description,
    List<String>? technologies,
    String? projectUrl,
    String? githubUrl,
    String? imagePath,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Project(
      title: title ?? this.title,
      description: description ?? this.description,
      technologies: technologies ?? this.technologies,
      projectUrl: projectUrl ?? this.projectUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      imagePath: imagePath ?? this.imagePath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'technologies': technologies,
      'projectUrl': projectUrl,
      'githubUrl': githubUrl,
      'imagePath': imagePath,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      technologies: List<String>.from(json['technologies'] ?? []),
      projectUrl: json['projectUrl'],
      githubUrl: json['githubUrl'],
      imagePath: json['imagePath'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}

/// Language Model with proficiency
class Language {
  final String name;
  final String proficiency; // Beginner, Intermediate, Advanced, Native

  const Language({required this.name, this.proficiency = 'Intermediate'});

  Language copyWith({String? name, String? proficiency}) {
    return Language(
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'proficiency': proficiency};
  }

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: json['name'] ?? '',
      proficiency: json['proficiency'] ?? 'Intermediate',
    );
  }
}

/// Achievement Model
class Achievement {
  final String title;
  final String description;
  final DateTime? date;
  final String? badgeIcon;

  const Achievement({
    required this.title,
    this.description = '',
    this.date,
    this.badgeIcon,
  });

  Achievement copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? badgeIcon,
  }) {
    return Achievement(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      badgeIcon: badgeIcon ?? this.badgeIcon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date?.toIso8601String(),
      'badgeIcon': badgeIcon,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      badgeIcon: json['badgeIcon'],
    );
  }
}

/// Reference Model
class Reference {
  final String name;
  final String title;
  final String company;
  final String email;
  final String phone;
  final String relationship;

  const Reference({
    required this.name,
    this.title = '',
    this.company = '',
    this.email = '',
    this.phone = '',
    this.relationship = '',
  });

  Reference copyWith({
    String? name,
    String? title,
    String? company,
    String? email,
    String? phone,
    String? relationship,
  }) {
    return Reference(
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'company': company,
      'email': email,
      'phone': phone,
      'relationship': relationship,
    };
  }

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }
}

/// Language proficiency levels
class LanguageProficiency {
  static const List<String> levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Native',
  ];
}
