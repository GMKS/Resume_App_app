// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResumeModelAdapter extends TypeAdapter<ResumeModel> {
  @override
  final int typeId = 0;

  @override
  ResumeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResumeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      personalInfo: fields[2] as PersonalInfo,
      objective: fields[3] as String?,
      education: (fields[4] as List).cast<Education>(),
      experience: (fields[5] as List).cast<Experience>(),
      skills: (fields[6] as List).cast<Skill>(),
      projects: (fields[7] as List).cast<Project>(),
      certifications: (fields[8] as List).cast<Certification>(),
      languages: (fields[9] as List).cast<Language>(),
      hobbies: (fields[10] as List).cast<String>(),
      references: (fields[11] as List).cast<Reference>(),
      templateId: fields[12] as String,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      colorScheme: fields[15] as int,
      customSections: (fields[16] as List).cast<CustomSection>(),
      writingLanguage: fields[17] as String,
      fontFamily: fields[18] as String,
      layoutStyle: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResumeModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.personalInfo)
      ..writeByte(3)
      ..write(obj.objective)
      ..writeByte(4)
      ..write(obj.education)
      ..writeByte(5)
      ..write(obj.experience)
      ..writeByte(6)
      ..write(obj.skills)
      ..writeByte(7)
      ..write(obj.projects)
      ..writeByte(8)
      ..write(obj.certifications)
      ..writeByte(9)
      ..write(obj.languages)
      ..writeByte(10)
      ..write(obj.hobbies)
      ..writeByte(11)
      ..write(obj.references)
      ..writeByte(12)
      ..write(obj.templateId)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.colorScheme)
      ..writeByte(16)
      ..write(obj.customSections)
      ..writeByte(17)
      ..write(obj.writingLanguage)
      ..writeByte(18)
      ..write(obj.fontFamily)
      ..writeByte(19)
      ..write(obj.layoutStyle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonalInfoAdapter extends TypeAdapter<PersonalInfo> {
  @override
  final int typeId = 1;

  @override
  PersonalInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalInfo(
      fullName: fields[0] as String,
      email: fields[1] as String,
      phone: fields[2] as String,
      address: fields[3] as String,
      linkedIn: fields[4] as String?,
      github: fields[5] as String?,
      website: fields[6] as String?,
      profileImage: fields[7] as String?,
      jobTitle: fields[8] as String?,
      dateOfBirth: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalInfo obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.linkedIn)
      ..writeByte(5)
      ..write(obj.github)
      ..writeByte(6)
      ..write(obj.website)
      ..writeByte(7)
      ..write(obj.profileImage)
      ..writeByte(8)
      ..write(obj.jobTitle)
      ..writeByte(9)
      ..write(obj.dateOfBirth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EducationAdapter extends TypeAdapter<Education> {
  @override
  final int typeId = 2;

  @override
  Education read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Education(
      id: fields[0] as String,
      institution: fields[1] as String,
      degree: fields[2] as String,
      fieldOfStudy: fields[3] as String,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      isCurrentlyStudying: fields[6] as bool,
      grade: fields[7] as String?,
      description: fields[8] as String?,
      location: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Education obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.institution)
      ..writeByte(2)
      ..write(obj.degree)
      ..writeByte(3)
      ..write(obj.fieldOfStudy)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.isCurrentlyStudying)
      ..writeByte(7)
      ..write(obj.grade)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExperienceAdapter extends TypeAdapter<Experience> {
  @override
  final int typeId = 3;

  @override
  Experience read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Experience(
      id: fields[0] as String,
      company: fields[1] as String,
      position: fields[2] as String,
      location: fields[3] as String?,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      isCurrentlyWorking: fields[6] as bool,
      description: fields[7] as String,
      achievements: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Experience obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.company)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.isCurrentlyWorking)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.achievements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperienceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SkillAdapter extends TypeAdapter<Skill> {
  @override
  final int typeId = 4;

  @override
  Skill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Skill(
      id: fields[0] as String,
      name: fields[1] as String,
      proficiency: fields[2] as int,
      category: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Skill obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.proficiency)
      ..writeByte(3)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 5;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      url: fields[3] as String?,
      technologies: (fields[4] as List).cast<String>(),
      startDate: fields[5] as DateTime?,
      endDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.technologies)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CertificationAdapter extends TypeAdapter<Certification> {
  @override
  final int typeId = 6;

  @override
  Certification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Certification(
      id: fields[0] as String,
      name: fields[1] as String,
      issuer: fields[2] as String,
      issueDate: fields[3] as DateTime?,
      expiryDate: fields[4] as DateTime?,
      credentialId: fields[5] as String?,
      credentialUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Certification obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.issuer)
      ..writeByte(3)
      ..write(obj.issueDate)
      ..writeByte(4)
      ..write(obj.expiryDate)
      ..writeByte(5)
      ..write(obj.credentialId)
      ..writeByte(6)
      ..write(obj.credentialUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LanguageAdapter extends TypeAdapter<Language> {
  @override
  final int typeId = 7;

  @override
  Language read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Language(
      id: fields[0] as String,
      name: fields[1] as String,
      proficiency: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Language obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.proficiency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReferenceAdapter extends TypeAdapter<Reference> {
  @override
  final int typeId = 8;

  @override
  Reference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reference(
      id: fields[0] as String,
      name: fields[1] as String,
      position: fields[2] as String,
      company: fields[3] as String,
      email: fields[4] as String,
      phone: fields[5] as String,
      relationship: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reference obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.company)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.relationship);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomSectionAdapter extends TypeAdapter<CustomSection> {
  @override
  final int typeId = 9;

  @override
  CustomSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomSection(
      id: fields[0] as String,
      title: fields[1] as String,
      items: (fields[2] as List).cast<CustomSectionItem>(),
      order: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomSection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomSectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomSectionItemAdapter extends TypeAdapter<CustomSectionItem> {
  @override
  final int typeId = 10;

  @override
  CustomSectionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomSectionItem(
      id: fields[0] as String,
      title: fields[1] as String,
      subtitle: fields[2] as String?,
      description: fields[3] as String?,
      date: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomSectionItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.subtitle)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomSectionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
