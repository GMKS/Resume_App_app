import 'package:hive/hive.dart';

part 'resume_model.g.dart';

@HiveType(typeId: 0)
class ResumeModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  PersonalInfo personalInfo;
  
  @HiveField(3)
  String? objective;
  
  @HiveField(4)
  List<Education> education;
  
  @HiveField(5)
  List<Experience> experience;
  
  @HiveField(6)
  List<Skill> skills;
  
  @HiveField(7)
  List<Project> projects;
  
  @HiveField(8)
  List<Certification> certifications;
  
  @HiveField(9)
  List<Language> languages;
  
  @HiveField(10)
  List<String> hobbies;
  
  @HiveField(11)
  List<Reference> references;
  
  @HiveField(12)
  String templateId;
  
  @HiveField(13)
  DateTime createdAt;
  
  @HiveField(14)
  DateTime updatedAt;
  
  @HiveField(15)
  int colorScheme;
  
  @HiveField(16)
  List<CustomSection> customSections;

  @HiveField(17)
  String writingLanguage;

  @HiveField(18)
  String fontFamily;

  @HiveField(19)
  String layoutStyle;

  ResumeModel({
    required this.id,
    required this.title,
    required this.personalInfo,
    this.objective,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.hobbies = const [],
    this.references = const [],
    this.templateId = 'modern',
    required this.createdAt,
    required this.updatedAt,
    this.colorScheme = 0,
    this.customSections = const [],
    this.writingLanguage = 'English',
    this.fontFamily = 'Roboto',
    this.layoutStyle = 'standard',
  });

  ResumeModel copyWith({
    String? id,
    String? title,
    PersonalInfo? personalInfo,
    String? objective,
    List<Education>? education,
    List<Experience>? experience,
    List<Skill>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
    List<Language>? languages,
    List<String>? hobbies,
    List<Reference>? references,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorScheme,
    List<CustomSection>? customSections,
    String? writingLanguage,
    String? fontFamily,
    String? layoutStyle,
  }) {
    return ResumeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      personalInfo: personalInfo ?? this.personalInfo,
      objective: objective ?? this.objective,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      languages: languages ?? this.languages,
      hobbies: hobbies ?? this.hobbies,
      references: references ?? this.references,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorScheme: colorScheme ?? this.colorScheme,
      customSections: customSections ?? this.customSections,
      writingLanguage: writingLanguage ?? this.writingLanguage,
      fontFamily: fontFamily ?? this.fontFamily,
      layoutStyle: layoutStyle ?? this.layoutStyle,
    );
  }

  // Calculate completion percentage
  int get completionPercentage {
    int total = 0;
    int filled = 0;
    
    // Personal info
    total += 7;
    if (personalInfo.fullName.isNotEmpty) filled++;
    if (personalInfo.email.isNotEmpty) filled++;
    if (personalInfo.phone.isNotEmpty) filled++;
    if (personalInfo.address.isNotEmpty) filled++;
    if (personalInfo.linkedIn != null && personalInfo.linkedIn!.isNotEmpty) filled++;
    if (personalInfo.website != null && personalInfo.website!.isNotEmpty) filled++;
    if (personalInfo.profileImage != null) filled++;
    
    // Objective
    total += 1;
    if (objective != null && objective!.isNotEmpty) filled++;
    
    // Education
    total += 1;
    if (education.isNotEmpty) filled++;
    
    // Experience
    total += 1;
    if (experience.isNotEmpty) filled++;
    
    // Skills
    total += 1;
    if (skills.isNotEmpty) filled++;
    
    return ((filled / total) * 100).round();
  }
}

@HiveType(typeId: 1)
class PersonalInfo {
  @HiveField(0)
  String fullName;
  
  @HiveField(1)
  String email;
  
  @HiveField(2)
  String phone;
  
  @HiveField(3)
  String address;
  
  @HiveField(4)
  String? linkedIn;
  
  @HiveField(5)
  String? github;
  
  @HiveField(6)
  String? website;
  
  @HiveField(7)
  String? profileImage;
  
  @HiveField(8)
  String? jobTitle;
  
  @HiveField(9)
  DateTime? dateOfBirth;

  PersonalInfo({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.linkedIn,
    this.github,
    this.website,
    this.profileImage,
    this.jobTitle,
    this.dateOfBirth,
  });

  PersonalInfo copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? linkedIn,
    String? github,
    String? website,
    String? profileImage,
    String? jobTitle,
    DateTime? dateOfBirth,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      linkedIn: linkedIn ?? this.linkedIn,
      github: github ?? this.github,
      website: website ?? this.website,
      profileImage: profileImage ?? this.profileImage,
      jobTitle: jobTitle ?? this.jobTitle,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

@HiveType(typeId: 2)
class Education {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String institution;
  
  @HiveField(2)
  String degree;
  
  @HiveField(3)
  String fieldOfStudy;
  
  @HiveField(4)
  DateTime startDate;
  
  @HiveField(5)
  DateTime? endDate;
  
  @HiveField(6)
  bool isCurrentlyStudying;
  
  @HiveField(7)
  String? grade;
  
  @HiveField(8)
  String? description;
  
  @HiveField(9)
  String? location;

  Education({
    required this.id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    required this.startDate,
    this.endDate,
    this.isCurrentlyStudying = false,
    this.grade,
    this.description,
    this.location,
  });

  Education copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrentlyStudying,
    String? grade,
    String? description,
    String? location,
  }) {
    return Education(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrentlyStudying: isCurrentlyStudying ?? this.isCurrentlyStudying,
      grade: grade ?? this.grade,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}

@HiveType(typeId: 3)
class Experience {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String company;
  
  @HiveField(2)
  String position;
  
  @HiveField(3)
  String? location;
  
  @HiveField(4)
  DateTime startDate;
  
  @HiveField(5)
  DateTime? endDate;
  
  @HiveField(6)
  bool isCurrentlyWorking;
  
  @HiveField(7)
  String description;
  
  @HiveField(8)
  List<String> achievements;

  Experience({
    required this.id,
    this.company = '',
    this.position = '',
    this.location,
    required this.startDate,
    this.endDate,
    this.isCurrentlyWorking = false,
    this.description = '',
    this.achievements = const [],
  });

  Experience copyWith({
    String? id,
    String? company,
    String? position,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrentlyWorking,
    String? description,
    List<String>? achievements,
  }) {
    return Experience(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrentlyWorking: isCurrentlyWorking ?? this.isCurrentlyWorking,
      description: description ?? this.description,
      achievements: achievements ?? this.achievements,
    );
  }
}

@HiveType(typeId: 4)
class Skill {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  int proficiency; // 1-5
  
  @HiveField(3)
  String? category;

  Skill({
    required this.id,
    this.name = '',
    this.proficiency = 3,
    this.category,
  });

  Skill copyWith({
    String? id,
    String? name,
    int? proficiency,
    String? category,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
      category: category ?? this.category,
    );
  }
}

@HiveType(typeId: 5)
class Project {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  String? url;
  
  @HiveField(4)
  List<String> technologies;
  
  @HiveField(5)
  DateTime? startDate;
  
  @HiveField(6)
  DateTime? endDate;

  Project({
    required this.id,
    this.title = '',
    this.description = '',
    this.url,
    this.technologies = const [],
    this.startDate,
    this.endDate,
  });

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    List<String>? technologies,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      technologies: technologies ?? this.technologies,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

@HiveType(typeId: 6)
class Certification {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String issuer;
  
  @HiveField(3)
  DateTime? issueDate;
  
  @HiveField(4)
  DateTime? expiryDate;
  
  @HiveField(5)
  String? credentialId;
  
  @HiveField(6)
  String? credentialUrl;

  Certification({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  Certification copyWith({
    String? id,
    String? name,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return Certification(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      credentialId: credentialId ?? this.credentialId,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }
}

@HiveType(typeId: 7)
class Language {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String proficiency; // Native, Fluent, Professional, Beginner

  Language({
    required this.id,
    this.name = '',
    this.proficiency = 'Professional',
  });

  Language copyWith({
    String? id,
    String? name,
    String? proficiency,
  }) {
    return Language(
      id: id ?? this.id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
    );
  }
}

@HiveType(typeId: 8)
class Reference {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String position;
  
  @HiveField(3)
  String company;
  
  @HiveField(4)
  String email;
  
  @HiveField(5)
  String phone;
  
  @HiveField(6)
  String? relationship;

  Reference({
    required this.id,
    this.name = '',
    this.position = '',
    this.company = '',
    this.email = '',
    this.phone = '',
    this.relationship,
  });

  Reference copyWith({
    String? id,
    String? name,
    String? position,
    String? company,
    String? email,
    String? phone,
    String? relationship,
  }) {
    return Reference(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }
}

@HiveType(typeId: 9)
class CustomSection {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  List<CustomSectionItem> items;

  @HiveField(3)
  int order;

  CustomSection({
    required this.id,
    this.title = '',
    this.items = const [],
    this.order = 0,
  });

  CustomSection copyWith({
    String? id,
    String? title,
    List<CustomSectionItem>? items,
    int? order,
  }) {
    return CustomSection(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      order: order ?? this.order,
    );
  }
}

@HiveType(typeId: 10)
class CustomSectionItem {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String? subtitle;
  
  @HiveField(3)
  String? description;
  
  @HiveField(4)
  DateTime? date;

  CustomSectionItem({
    required this.id,
    this.title = '',
    this.subtitle,
    this.description,
    this.date,
  });

  CustomSectionItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    DateTime? date,
  }) {
    return CustomSectionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}
