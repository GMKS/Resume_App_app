import '../models/resume_model.dart';
import '../services/storage_service.dart';

const bool kStoreScreenshotMode = bool.fromEnvironment(
  'STORE_SCREENSHOT_MODE',
);
const String kStoreScreenshotResumeId = 'store-screenshot-resume';

Future<void> ensureStoreScreenshotSeedData() async {
  if (!kStoreScreenshotMode) {
    return;
  }

  final now = DateTime(2026, 5, 1);
  final expiry = now.add(const Duration(days: 30));

  await StorageService.setOnboardingComplete(true);
  await StorageService.setThemeMode('light');
  await StorageService.prefs.setString('subscription_provider', 'local');
  await StorageService.prefs.setString('subscription_plan', 'monthly');
  await StorageService.prefs.setBool('subscription_active', true);
  await StorageService.prefs.setBool('subscription_verified', true);
  await StorageService.prefs.setString(
    'subscription_purchase_date',
    now.millisecondsSinceEpoch.toString(),
  );
  await StorageService.prefs.setString(
    'subscription_expiry',
    expiry.millisecondsSinceEpoch.toString(),
  );
  await StorageService.prefs.setString(
    'subscription_verification_status',
    'screenshot_seed',
  );

  if (StorageService.getResume(kStoreScreenshotResumeId) != null) {
    return;
  }

  final sampleResume = ResumeModel(
    id: kStoreScreenshotResumeId,
    title: 'Senior Product Designer',
    personalInfo: PersonalInfo(
      fullName: 'Avery Johnson',
      email: 'avery.johnson@example.com',
      phone: '+1 415 555 0137',
      address: 'San Francisco, CA',
      linkedIn: 'linkedin.com/in/averyjohnson',
      github: 'github.com/averydesigns',
      website: 'averyjohnson.design',
      jobTitle: 'Senior Product Designer',
    ),
    objective:
        'Product designer with 6+ years of experience shaping mobile and web experiences that improve conversion, accessibility, and user trust.',
    education: [
      Education(
        id: 'edu-1',
        institution: 'California College of the Arts',
        degree: 'B.Des.',
        fieldOfStudy: 'Interaction Design',
        startDate: DateTime(2014, 8),
        endDate: DateTime(2018, 5),
        grade: '3.9 GPA',
      ),
    ],
    experience: [
      Experience(
        id: 'exp-1',
        company: 'Northstar Labs',
        position: 'Senior Product Designer',
        location: 'Remote',
        startDate: DateTime(2022, 2),
        isCurrentlyWorking: true,
        description:
            'Led end-to-end design for career tools, resume workflows, and AI-assisted writing features.',
        achievements: [
          'Increased completed resumes by 38% after redesigning the editor flow.',
          'Shipped a template marketplace used by over 40k monthly users.',
        ],
      ),
      Experience(
        id: 'exp-2',
        company: 'BrightHire',
        position: 'Product Designer',
        location: 'San Jose, CA',
        startDate: DateTime(2019, 6),
        endDate: DateTime(2022, 1),
        description:
            'Designed recruiting dashboards, candidate scorecards, and mobile-first profile flows.',
        achievements: [
          'Reduced drop-off in profile completion by 24% with a simplified onboarding experience.',
        ],
      ),
    ],
    skills: [
      Skill(id: 'skill-1', name: 'Product Strategy'),
      Skill(id: 'skill-2', name: 'UX Research'),
      Skill(id: 'skill-3', name: 'Figma'),
      Skill(id: 'skill-4', name: 'Design Systems'),
      Skill(id: 'skill-5', name: 'Mobile UX'),
      Skill(id: 'skill-6', name: 'Prototyping'),
    ],
    projects: [
      Project(
        id: 'project-1',
        title: 'Resume Studio Redesign',
        description:
            'Redesigned a resume editor with modular sections, template previews, and one-tap export.',
        technologies: ['Flutter', 'Firebase', 'Figma'],
      ),
      Project(
        id: 'project-2',
        title: 'AI Cover Letter Assistant',
        description:
            'Created an AI-assisted flow for generating tailored cover letters from resume data.',
        technologies: ['Prompt Design', 'Analytics'],
      ),
    ],
    certifications: [
      Certification(
        id: 'cert-1',
        name: 'Google UX Design Certificate',
        issuer: 'Google',
        issueDate: DateTime(2021, 10),
      ),
    ],
    languages: [
      Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
    ],
    hobbies: const ['Mentoring', 'Photography', 'Travel'],
    templateId: 'modern',
    colorScheme: 1,
    createdAt: now,
    updatedAt: now,
  );

  await StorageService.saveResume(sampleResume);
}
