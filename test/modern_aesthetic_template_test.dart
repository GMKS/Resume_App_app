import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

void main() {
  ResumeModel buildResume({List<CustomSection> customSections = const []}) {
    final now = DateTime(2026, 4, 21);
    return ResumeModel(
      id: 'modern-aesthetic-test',
      title: 'SharpLine Resume',
      personalInfo: PersonalInfo(
        fullName: 'Seenai',
        email: 'seenai@example.com',
        phone: '+1 555 123 4567',
        address: 'New York, NY',
        linkedIn: 'linkedin.com/in/seenai',
        github: 'github.com/seenai',
        website: 'seenai.dev',
        jobTitle: 'HR Consultant',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Software Engineering',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led a team of 5 to deliver cloud-based platform and improved delivery quality.',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description: 'Developed a responsive portfolio site showcasing projects and skills.',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'AWS Certified Developer', issuer: 'Amazon'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      customSections: customSections,
      templateId: 'modern_aesthetic',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('modern aesthetic pdf generates with legacy and user custom sections', () async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_experience',
          title: 'Leadership Experience',
          items: [
            CustomSectionItem(
              id: 'lead-1',
              title: 'Led a team of 5 QA engineers',
              description: 'Managed automation framework development and release readiness.',
            ),
          ],
        ),
        CustomSection(
          id: 'user_custom_awards',
          title: 'Awards and Rewards',
          items: [
            CustomSectionItem(
              id: 'award-1',
              title: 'Best Automation Engineer Award',
              subtitle: 'TechSolutions Pvt Ltd',
              description: 'Recognized for building stable end-to-end automation coverage.',
              date: DateTime(2023, 1, 1),
            ),
          ],
        ),
      ],
    );

    final pdf = await ModernAestheticTemplate().generate(
      resume,
      PdfColor.fromHex('#6366F1'),
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });
}