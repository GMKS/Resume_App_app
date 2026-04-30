import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-education-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'education-resume-pdf-test',
      title: 'Education Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai1977@gmail.com',
        phone: '+91 9886750145',
        linkedIn: 'https://www..linkedin.com/seenai-com/ ',
        github: 'https://github.com/gmk',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 14.5 years in software testing or development, with a solid understanding of testing, coding, and debugging processes. Proficient in Java and Selenium-based automation frameworks with strong collaboration and problem-solving skills.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2025, 1, 1),
          description:
              'Led the automation team in developing and executing test automation scripts and collaborated with managers and onsite teams to ensure delivery quality.',
          achievements: const [
            'Managed client interactions for status updates, metrics, and team-related communication.',
            'Handled project estimation, scheduling, and risk management using Agile practices.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2007, 1, 1),
          endDate: DateTime(2009, 1, 1),
          grade: '1st Grade',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'Project Management'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Automation Dashboard',
          description:
              'Created a reporting dashboard for Selenium execution metrics and defect visibility. https://example.com/automation-dashboard',
          url: 'https://example.com/automation-dashboard',
          technologies: const ['Java', 'Selenium', 'SQL'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Scrum Master',
          issuer: 'Scrum Alliance',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      templateId: 'education_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the education resume pdf template', () {
    final template = PdfTemplateFactory.getTemplate('education_resume');
    expect(template, isA<EducationResumePdfTemplate>());
  });

  test('education resume pdf generates bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('education_resume');
    final pdf = await template.generate(resume, PdfColor.fromHex('#5D5FEF'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
