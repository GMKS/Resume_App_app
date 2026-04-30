import '../models/resume_model.dart';

class ProfessionalRoleSectionConfig {
  final String id;
  final String title;
  final String description;
  final String emptyPrompt;

  const ProfessionalRoleSectionConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.emptyPrompt,
  });
}

// Business Management Resume (Executive) Sections
const _businessManagementSections = <String, ProfessionalRoleSectionConfig>{
  'business_leadership_achievements': ProfessionalRoleSectionConfig(
    id: 'business_leadership_achievements',
    title: 'Leadership Achievements',
    description: 'Showcase strategic wins, team growth, and organizational impact.',
    emptyPrompt: 'Add revenue growth, team scaling, restructures, or strategic initiatives.',
  ),
  'business_board_memberships': ProfessionalRoleSectionConfig(
    id: 'business_board_memberships',
    title: 'Board Memberships',
    description: 'Highlight board positions, committee roles, and governance experience.',
    emptyPrompt: 'Add board or committee name, role, and tenure.',
  ),
  'business_management_certifications': ProfessionalRoleSectionConfig(
    id: 'business_management_certifications',
    title: 'Management Certifications',
    description: 'List MBA, executive education, or leadership certifications.',
    emptyPrompt: 'Add certification name, institution, and completion date.',
  ),
};

// Design/Creative Resume Sections
const _designCreativeSections = <String, ProfessionalRoleSectionConfig>{
  'design_portfolio_highlights': ProfessionalRoleSectionConfig(
    id: 'design_portfolio_highlights',
    title: 'Portfolio Highlights',
    description: 'Showcase your best design projects and creative work.',
    emptyPrompt: 'Add project title, role, and link to portfolio or case study.',
  ),
  'design_awards_recognition': ProfessionalRoleSectionConfig(
    id: 'design_awards_recognition',
    title: 'Awards & Recognition',
    description: 'Display design awards, exhibitions, or industry recognition.',
    emptyPrompt: 'Add award name, year, and awarding organization.',
  ),
  'design_tools_software': ProfessionalRoleSectionConfig(
    id: 'design_tools_software',
    title: 'Design Tools & Software',
    description: 'List design software, tools, and creative platforms.',
    emptyPrompt: 'Add tool names: Adobe Creative Suite, Figma, Sketch, etc.',
  ),
  'design_specializations': ProfessionalRoleSectionConfig(
    id: 'design_specializations',
    title: 'Design Specializations',
    description: 'Highlight your design expertise areas.',
    emptyPrompt: 'Add specialization areas: UX/UI, Branding, Illustration, etc.',
  ),
};

// HealthCare Resume Sections
const _healthcareSections = <String, ProfessionalRoleSectionConfig>{
  'healthcare_licenses_certifications': ProfessionalRoleSectionConfig(
    id: 'healthcare_licenses_certifications',
    title: 'Medical Licenses & Certifications',
    description: 'Critical healthcare credentials and medical certifications.',
    emptyPrompt: 'Add license type, issuing authority, license number, and expiry date.',
  ),
  'healthcare_specializations': ProfessionalRoleSectionConfig(
    id: 'healthcare_specializations',
    title: 'Clinical Specializations',
    description: 'Medical specializations and clinical expertise areas.',
    emptyPrompt: 'Add specialization: Cardiology, Pediatrics, Surgery, Nursing, etc.',
  ),
  'healthcare_clinical_skills': ProfessionalRoleSectionConfig(
    id: 'healthcare_clinical_skills',
    title: 'Clinical Skills',
    description: 'Specific medical procedures, techniques, or patient care competencies.',
    emptyPrompt: 'Add clinical skill: Patient assessment, Surgical techniques, etc.',
  ),
  'healthcare_hospital_affiliations': ProfessionalRoleSectionConfig(
    id: 'healthcare_hospital_affiliations',
    title: 'Hospital Affiliations',
    description: 'Associated hospitals, clinics, or medical institutions.',
    emptyPrompt: 'Add institution name, affiliation type, and period.',
  ),
};

// Human Resources Resume Sections
const _hrResumeSection = <String, ProfessionalRoleSectionConfig>{
  'hr_certifications': ProfessionalRoleSectionConfig(
    id: 'hr_certifications',
    title: 'HR Certifications',
    description: 'Professional HR credentials: SHRM, CIPD, or similar.',
    emptyPrompt: 'Add certification: PHR, SHRM-CP, CIPD, etc., and year obtained.',
  ),
  'hr_talent_management': ProfessionalRoleSectionConfig(
    id: 'hr_talent_management',
    title: 'Talent Management Achievements',
    description: 'Recruitment, retention, and talent development accomplishments.',
    emptyPrompt: 'Add achievement: Hired X employees, Retention rate, etc.',
  ),
  'hr_compliance_programs': ProfessionalRoleSectionConfig(
    id: 'hr_compliance_programs',
    title: 'Compliance & Programs',
    description: 'HR compliance initiatives, training programs, or policy development.',
    emptyPrompt: 'Add program name: Benefits administration, Training program, Compliance audit.',
  ),
  'hr_employee_relations': ProfessionalRoleSectionConfig(
    id: 'hr_employee_relations',
    title: 'Employee Relations Expertise',
    description: 'Employee engagement, conflict resolution, or labor relations experience.',
    emptyPrompt: 'Add expertise: Conflict resolution, Union negotiations, Engagement programs.',
  ),
};

Map<String, Map<String, ProfessionalRoleSectionConfig>> _roleSectionCatalogs() => {
  'executive': _businessManagementSections,
  'designer_profile': _designCreativeSections,
  'professional_tone': _healthcareSections,
  'elegant_gold_layout': _hrResumeSection,
};

ProfessionalRoleSectionConfig? professionalRoleSectionConfigById(String templateId, String id) {
  return _roleSectionCatalogs()[templateId]?[id];
}

List<ProfessionalRoleSectionConfig> professionalRoleAllOptionalSectionConfigs(String templateId) {
  return _roleSectionCatalogs()[templateId]?.values.toList(growable: false) ?? [];
}

bool isProfessionalRoleOptionalSectionKey(String templateId, String key) {
  return _roleSectionCatalogs()[templateId]?.containsKey(key) ?? false;
}

List<ProfessionalRoleSectionConfig> professionalRoleRecommendedSections(String templateId) {
  final catalog = _roleSectionCatalogs()[templateId] ?? {};
  return catalog.values.toList(growable: false);
}

List<String> professionalRoleOptionalSectionKeys(ResumeModel resume) {
  if (!_roleSectionCatalogs().containsKey(resume.templateId)) {
    return [];
  }

  final recommended = professionalRoleRecommendedSections(resume.templateId)
      .map((section) => section.id)
      .toList();
  final existingKnown = resume.customSections
      .map((section) => section.id)
      .where((id) => isProfessionalRoleOptionalSectionKey(resume.templateId, id))
      .where((id) => !recommended.contains(id))
      .toList();
  return [...recommended, ...existingKnown];
}

List<CustomSection> ensureProfessionalRoleSections(ResumeModel resume) {
  final templateId = resume.templateId;
  if (!_roleSectionCatalogs().containsKey(templateId)) {
    return List<CustomSection>.from(resume.customSections);
  }

  final recommended = professionalRoleRecommendedSections(templateId);
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
