import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/resume_import_service.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/core/services/translation_service.dart';
import 'package:resume_builder/features/preview/services/preview_pdf_service.dart';

ResumeModel _buildGmkSeenaiResume() {
  final now = DateTime(2026, 4, 25);
  return ResumeModel(
    id: 'gmk-seenai-spanish-preview',
    title: 'GMK Seenai Resume',
    personalInfo: PersonalInfo(
      fullName: 'GMK Seenai',
      email: 'seenaigmk@gmail.com',
      phone: '+91 9916750642',
      address: 'Hyderabad, India',
      linkedIn: 'linkedin.com/seenai',
      github: 'github.com/gmk',
      jobTitle: 'HR Consultant',
    ),
    objective:
        'Strategic HR Consultant with expertise in talent management, employee relations, and organizational development across diverse industries.',
    education: <Education>[
      Education(
        id: 'edu-1',
        institution: 'Holy Jesus and Mary PG College',
        degree: 'MCA',
        fieldOfStudy: 'Computers',
        startDate: DateTime(2006, 1, 1),
        endDate: DateTime(2009, 1, 1),
      ),
      Education(
        id: 'edu-2',
        institution: 'Wesley Degree College',
        degree: 'BSc Comp.Science',
        fieldOfStudy: 'Computers',
        startDate: DateTime(2000, 1, 1),
        endDate: DateTime(2005, 1, 1),
      ),
    ],
    experience: <Experience>[
      Experience(
        id: 'exp-1',
        company: 'TechNova Solutions',
        position: 'Software Engineer',
        location: 'Bangalore, India',
        startDate: DateTime(2022, 1, 1),
        isCurrentlyWorking: true,
        description:
            'Developed scalable web applications using React and Node.js.',
        achievements: const <String>[
          'Improved API performance by 30% through optimization techniques.',
          'Collaborated with cross-functional teams to deliver new features.',
        ],
      ),
      Experience(
        id: 'exp-2',
        company: 'PixelCraft Labs',
        position: 'Frontend Developer',
        location: 'Remote',
        startDate: DateTime(2020, 6, 1),
        endDate: DateTime(2021, 12, 1),
        description: 'Assisted in developing internal tools using JavaScript.',
        achievements: const <String>[
          'Fixed bugs and improved application stability.',
          'Learned version control using Git and GitHub.',
        ],
      ),
      Experience(
        id: 'exp-3',
        company: 'DataBridge Technologies',
        position: 'Backend Developer',
        location: 'Hyderabad, India',
        startDate: DateTime(2019, 1, 1),
        endDate: DateTime(2020, 2, 1),
        description:
            'Developed websites for small businesses and startups.',
      ),
      Experience(
        id: 'exp-4',
        company: 'InnovateX Labs',
        position: 'Software Intern',
        location: 'Pune, India',
        startDate: DateTime(2017, 4, 1),
        endDate: DateTime(2018, 5, 1),
        description:
            'Designed and developed RESTful APIs using Node.js and Express.',
      ),
    ],
    skills: <Skill>[
      Skill(id: 'skill-1', name: 'Dart'),
      Skill(id: 'skill-2', name: 'Java'),
      Skill(id: 'skill-3', name: 'GraphQL'),
      Skill(id: 'skill-4', name: 'REST APIs'),
      Skill(id: 'skill-5', name: 'Unit Testing'),
      Skill(id: 'skill-6', name: 'Swift'),
      Skill(id: 'skill-7', name: 'SQL'),
    ],
    projects: <Project>[
      Project(
        id: 'proj-1',
        title: 'AI Resume Builder',
        description:
            'Developed a full-stack AI-powered resume builder that allows users to create professional resumes instantly.',
        url: 'github.com/yourusername/ai-resume-builder',
      ),
      Project(
        id: 'proj-2',
        title: 'E-commerce Web Application',
        description:
            'Built a scalable e-commerce platform with product listings, cart functionality, and secure checkout.',
        url: 'github.com/yourusername/social-dashboard',
      ),
    ],
    certifications: <Certification>[
      Certification(
        id: 'cert-1',
        name: 'ISTQB Certification',
        issuer: 'ISTQB Certified Tester Foundation Level',
        issueDate: DateTime(2023, 4, 1),
        credentialId: 'ISTQB-CTFL-2023-45872',
        credentialUrl: 'istqb.org/certification-path-root/ctfl.html',
      ),
      Certification(
        id: 'cert-2',
        name: 'Selenium Certification',
        issuer: 'Udemy',
        issueDate: DateTime(2023, 4, 1),
        credentialId: 'UC-SEL-8723645',
        credentialUrl: 'udemy.com/certificate/UC-SEL-8723645',
      ),
      Certification(
        id: 'cert-3',
        name: 'API Testing with Postman Certification',
        issuer: 'Postman',
        issueDate: DateTime(2026, 4, 1),
        credentialId: 'POST-API-55678',
        credentialUrl: 'academy.postman.com/certificates/POST-API-55678',
      ),
    ],
    languages: <Language>[
      Language(id: 'lang-1', name: 'Hindi', proficiency: 'Professional'),
      Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
    ],
    templateId: 'creative',
    writingLanguage: 'Spanish',
    createdAt: now,
    updatedAt: now,
  );
}

String _normalizeText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-gmk-spanish');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    TranslationService.clearCache();
    TranslationService.debugBackendOverride = null;
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() {
    TranslationService.clearCache();
    TranslationService.debugBackendOverride = (text, _) async {
      final replacements = <String, String>{
        'HR Consultant': 'Consultor de RRHH',
        'Strategic HR Consultant with expertise in talent management, employee relations, and organizational development across diverse industries.':
            'Consultor estrategico de recursos humanos con experiencia en gestion de talentos, relaciones con los empleados y desarrollo organizacional en diversas industrias.',
        'Software Engineer': 'Ingeniero de software',
        'Frontend Developer': 'Desarrollador front-end',
        'Backend Developer': 'Desarrollador de back-end',
        'Software Intern': 'Pasante de software',
        'Developed scalable web applications using React and Node.js.':
            'Desarrolle aplicaciones web escalables usando React y Node.js.',
        'Improved API performance by 30% through optimization techniques.':
            'Mejore el rendimiento de la API en un 30 % mediante tecnicas de optimizacion.',
        'Collaborated with cross-functional teams to deliver new features.':
            'Colabore con equipos multifuncionales para ofrecer nuevas funciones.',
        'Assisted in developing internal tools using JavaScript.':
            'Colabore en el desarrollo de herramientas internas utilizando JavaScript.',
        'Fixed bugs and improved application stability.':
            'Corregi errores y mejore la estabilidad de la aplicacion.',
        'Learned version control using Git and GitHub.':
            'Aprendi control de versiones con Git y GitHub.',
        'Developed websites for small businesses and startups.':
            'Desarrolle sitios web para pequenas empresas y startups.',
        'Designed and developed RESTful APIs using Node.js and Express.':
            'Disene y desarrolle API RESTful utilizando Node.js y Express.',
        'BSc Comp.Science': 'Licenciatura en Ciencias Comp.',
        'Unit Testing': 'Pruebas unitarias',
        'ISTQB Certification': 'Certificacion ISTQB',
        'Selenium Certification': 'Certificacion de Selenium',
        'API Testing with Postman Certification':
            'Certificacion de pruebas API con Postman',
        'Hindi': 'Hindi',
        'German': 'Aleman',
      };

      var translated = text;
      replacements.forEach((source, target) {
        translated = translated.replaceAll(source, target);
      });
      return translated;
    };
  });

  tearDown(() {
    TranslationService.clearCache();
    TranslationService.debugBackendOverride = null;
  });

  test(
      'generates the GMK Seenai Spanish preview pdf with translated headers, dates, and titles',
      () async {
    final bytes = await PreviewPdfService.generateBytes(_buildGmkSeenaiResume());
    final extractedText = ResumeImportService.extractTextFromBytes(
      bytes: bytes,
      fileName: 'gmk_seenai_spanish_preview.pdf',
    );
    final normalizedText = _normalizeText(extractedText);

    expect(normalizedText, contains('PERFIL'));
    expect(normalizedText, isNot(contains('PROFILE')));
    expect(
      RegExp(r'ene\.?\s+2022\s*-\s*Actualidad', caseSensitive: false)
          .hasMatch(normalizedText),
      isTrue,
    );
    expect(
      RegExp(r'Emitido\s+abr\.?\s+2023', caseSensitive: false)
          .hasMatch(normalizedText),
      isTrue,
    );
    expect(normalizedText, contains('ID de credencial'));
    expect(normalizedText, isNot(contains('Credential ID')));
    expect(normalizedText, contains('Constructor de curriculums con IA'));
    expect(
      normalizedText,
      contains('Aplicacion web de comercio electronico'),
    );
    expect(normalizedText, contains('Certificacion ISTQB'));
  });
}