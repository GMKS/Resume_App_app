import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/services/preview_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-bm-dump');
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
    final now = DateTime(2026, 5, 31);
    return ResumeModel(
      id: 'bm-dump',
      title: 'Business Management Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'gmkseenai07@gmail.com',
        phone: '+91 9916750642',
        address: 'Hyderabad, India',
        linkedIn: 'linkedin.com/in/seenai',
        website: 'seenaigmk.com',
        jobTitle: 'Automation Lead',
      ),
      objective:
          'Results-driven Automation Lead with over 13.6 years of experience in software testing and development, possessing a solid understanding of testing, coding, and debugging procedures.\n'
          'Proficient in programming languages such as Selenium using Core Java, Selenium, Cucumber, and TestNG, with a strong background in advising teams on identifying automatable test cases.\n'
          'Adept at collaborating with cross-functional teams to develop scalable test automation solutions and integrate them into CI/CD pipelines.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TCS',
          position: 'Automation Lead',
          location: 'Hyderabad',
          startDate: DateTime(2021, 6, 1),
          endDate: DateTime(2026, 5, 31),
          description: 'Developed and executed test automation scripts.',
          achievements: const [
            'Developed and executed test automation scripts',
            'Guided team members and contributed to test framework development',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Ltd',
          position: 'SDET (Software Development Engineer in Test)',
          location: '',
          startDate: DateTime(2018, 7, 1),
          endDate: DateTime(2021, 6, 1),
          description: 'Developed and maintained automation test scripts.',
          achievements: const [
            'Developed and maintained automation test scripts',
            'Implemented data-driven and page object model frameworks',
          ],
        ),
        Experience(
          id: 'exp-3',
          company: 'Shell Infotech Pvt Ltd',
          position: 'Automation Lead Consultant',
          location: '',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2018, 5, 1),
          description: 'Led automation efforts.',
          achievements: const [
            'Led automation efforts',
            'Enhanced test scripts and frameworks',
          ],
        ),
        Experience(
          id: 'exp-4',
          company: 'HP Software Pvt Ltd',
          position: 'Senior Software Test Engineer',
          location: '',
          startDate: DateTime(2010, 8, 1),
          endDate: DateTime(2017, 8, 1),
          description: 'Conducted software testing.',
          achievements: const [
            'Conducted software testing',
            'Supported enterprise releases with automation coverage',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Osmania University',
          degree: 'Master of Computer Applications',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2099, 1, 1),
          isCurrentlyStudying: true,
        ),
      ],
      skills: [
        Skill(id: 's1', name: 'Core Java'),
        Skill(id: 's2', name: 'Selenium'),
        Skill(id: 's3', name: 'Cucumber'),
        Skill(id: 's4', name: 'TestNG'),
        Skill(id: 's5', name: 'REST services'),
        Skill(id: 's6', name: 'SQL/PL-SQL'),
        Skill(id: 's7', name: 'CI/CD pipelines'),
        Skill(id: 's8', name: 'DevOps environments'),
      ],
      projects: [
        Project(
          id: 'p1',
          title: 'Cigna Health Care',
          description:
              'Cigna is a global healthcare services company with over 180 million customer relationships. The project focuses on improving health outcomes and providing actionable insights.',
        ),
        Project(
          id: 'p2',
          title: 'One Pulse Application',
          description:
              'Prudential Assurance Company Singapore is a leading life insurance company with a strong focus on protection and prevention.',
        ),
        Project(
          id: 'p3',
          title: 'MSD CRM Application',
          description:
              'Dynamics 365 for Field Service helps organizations deliver onsite service with improved efficiency and effectiveness.',
        ),
        Project(
          id: 'p4',
          title: 'Anthem Inc. (Health Insurance)',
          description:
              'Anthem Inc. is a major health insurance company, part of the Blue Cross Blue Shield Association.',
        ),
        Project(
          id: 'p5',
          title: 'Walt Disney World',
          description:
              'Walt Disney Parks & Resorts includes theme parks, resorts, and the Disney Cruise Line.',
        ),
        Project(
          id: 'p6',
          title: 'HP Ink Value Enabled Products',
          description:
              'HP specializes in computing, data storage, and networking hardware, software, and services.',
        ),
      ],
      languages: [
        Language(id: 'l1', name: 'English', proficiency: 'Fluent'),
        Language(id: 'l2', name: 'Hindi', proficiency: 'Fluent'),
        Language(id: 'l3', name: 'Telugu', proficiency: 'Fluent'),
      ],
      customSections: [
        CustomSection(
          id: 'user_custom_achievements',
          title: 'Achievements',
          order: 0,
          items: [
            CustomSectionItem(
              id: 'ach-1',
              title: 'Team Building',
              description:
                  'Built and led manual and automation testing teams from scratch.',
            ),
            CustomSectionItem(
              id: 'ach-2',
              title: 'Best Performer',
              description:
                  'Awarded Best Performer twice for outstanding contributions.',
            ),
            CustomSectionItem(
              id: 'ach-3',
              title: 'Testing Frameworks',
              description:
                  'Developed testing frameworks from scratch using the Karate tool, POM and Data Driven.',
            ),
          ],
        ),
      ],
      templateId: 'executive',
      colorScheme: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('dump current business management preview pdf', () async {
    final bytes = await PreviewPdfService.generatePreviewBytes(buildResume());
    final file = File('c:/Resume_App_app/temp/business_management_current.pdf');
    await file.writeAsBytes(bytes, flush: true);
    expect(await file.exists(), isTrue);
  });
}
