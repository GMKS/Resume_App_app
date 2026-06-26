import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/translation_service.dart';

ResumeModel _buildResume() {
  return ResumeModel(
    id: 'resume-translation-1',
    title: 'QA Resume',
    personalInfo: PersonalInfo(
      fullName: 'Jane Doe',
      email: 'jane@example.com',
      phone: '+1 555 0100',
      address: 'Lagos, Nigeria',
      jobTitle: 'Senior QA Engineer',
    ),
    objective: 'Build reliable mobile releases for global users.',
    experience: <Experience>[
      Experience(
        id: 'exp-1',
        company: 'Acme Corp',
        position: 'QA Lead',
        location: 'Remote',
        startDate: DateTime(2023, 1, 1),
        isCurrentlyWorking: true,
        description: 'Built Flutter test automation for checkout flows.',
        achievements: const <String>[
          'Increased release confidence across iOS and Android.',
        ],
      ),
    ],
    education: <Education>[
      Education(
        id: 'edu-1',
        institution: 'University of Lagos',
        degree: 'Bachelor of Science',
        fieldOfStudy: 'Computer Science',
        location: 'Remote',
        startDate: DateTime(2018, 1, 1),
      ),
    ],
    skills: <Skill>[
      Skill(id: 'skill-1', name: 'Flutter'),
      Skill(id: 'skill-2', name: 'Firebase'),
    ],
    projects: <Project>[
      Project(
        id: 'proj-1',
        title: 'Resume Builder',
        description: 'Built a resume parser and job tracker.',
      ),
    ],
    certifications: <Certification>[
      Certification(
        id: 'cert-1',
        name: 'AWS Certified Cloud Practitioner',
        issuer: 'Amazon Web Services',
      ),
    ],
    languages: <Language>[
      Language(id: 'lang-1', name: 'English', proficiency: 'Fluent'),
    ],
    hobbies: const <String>['Hiking'],
    references: <Reference>[
      Reference(
        id: 'ref-1',
        name: 'John Manager',
        position: 'Director of Quality',
        company: 'Acme Corp',
      ),
    ],
    customSections: <CustomSection>[
      CustomSection(
        id: 'custom-1',
        title: 'Volunteer Experience',
        items: <CustomSectionItem>[
          CustomSectionItem(
            id: 'item-1',
            title: 'QA Mentor',
            subtitle: 'Community Lab',
            description: 'Mentored junior testers.',
          ),
        ],
      ),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUp(() {
    TranslationService.clearCache();
    TranslationService.debugBackendOverride = (text, _) async {
      final replacements = <String, String>{
        'Senior QA Engineer': 'Ingeniera QA Senior',
        'City, Country': 'Ciudad, pais',
        'Build reliable mobile releases for global users.':
            'Creo lanzamientos moviles confiables para usuarios globales.',
        'QA Lead': 'Lider de QA',
        'Most Recent Company': 'Empresa mas reciente',
        'Previous Company': 'Empresa anterior',
        'Built Flutter test automation for checkout flows.':
            'Construi automatizacion de pruebas de Flutter para flujos de pago.',
        'Increased release confidence across iOS and Android.':
            'Aumente la confianza de lanzamiento en iOS y Android.',
        'Your University / College': 'Tu universidad o instituto',
        'Bachelor of Science': 'Licenciatura en Ciencias',
        'Computer Science': 'Informatica',
        'Built a resume parser and job tracker.':
            'Construi un analizador de curriculums y un rastreador de empleos.',
        'Mobile App Development': 'Desarrollo de aplicaciones moviles',
        'Project Management': 'Gestion de proyectos',
        'English': 'Ingles',
        'Spanish': 'Espanol',
        'Hiking': 'Senderismo',
        'Director of Quality': 'Director de Calidad',
        'Volunteer Experience': 'Experiencia de Voluntariado',
        'QA Mentor': 'Mentor de QA',
        'Mentored junior testers.': 'Mentorice a testers junior.',
      };

      var translated = text;
      replacements.forEach((source, target) {
        translated = translated.replaceAll(source, target);
      });
      return translated;
    };
  });

  tearDown(() {
    TranslationService.debugBackendOverride = null;
    TranslationService.clearCache();
  });

  test('translateResume translates narrative fields and preserves proper nouns',
      () async {
    final translated = await TranslationService.translateResume(
      _buildResume(),
      'Spanish',
    );

    expect(translated.personalInfo.jobTitle, 'Ingeniera QA Senior');
    expect(
      translated.objective,
      'Creo lanzamientos moviles confiables para usuarios globales.',
    );
    expect(translated.experience.first.position, 'Lider de QA');
    expect(translated.experience.first.company, 'Acme Corp');
    expect(translated.experience.first.location, 'Remoto');
    expect(
      translated.experience.first.description,
      'Construi automatizacion de pruebas de Flutter para flujos de pago.',
    );
    expect(
      translated.experience.first.achievements.single,
      'Aumente la confianza de lanzamiento en iOS y Android.',
    );
    expect(translated.education.first.degree, 'Licenciatura en Ciencias');
    expect(translated.education.first.fieldOfStudy, 'Informatica');
    expect(translated.education.first.institution, 'University of Lagos');
    expect(translated.education.first.location, 'Remoto');
    expect(translated.skills.first.name, 'Flutter');
    expect(translated.projects.first.title, 'Resume Builder');
    expect(
      translated.projects.first.description,
      'Construi un analizador de curriculums y un rastreador de empleos.',
    );
    expect(
      translated.certifications.first.name,
      'AWS Certified Cloud Practitioner',
    );
    expect(translated.certifications.first.issuer, 'Amazon Web Services');
    expect(translated.languages.first.name, 'Ingles');
    expect(translated.languages.first.proficiency, 'fluido');
    expect(translated.references.first.name, 'John Manager');
    expect(translated.references.first.company, 'Acme Corp');
    expect(translated.references.first.position, 'Director de Calidad');
    expect(translated.customSections.first.title, 'Experiencia de Voluntariado');
    expect(
      translated.customSections.first.items.first.title,
      'Mentor de QA',
    );
    expect(
      translated.customSections.first.items.first.description,
      'Mentorice a testers junior.',
    );
  });

  test('translateResume converts placeholders and descriptive labels for Spanish resumes',
      () async {
    final resume = _buildResume().copyWith(
      personalInfo: _buildResume().personalInfo.copyWith(address: 'City, Country'),
      experience: <Experience>[
        Experience(
          id: 'exp-1',
          company: 'Most Recent Company',
          position: 'QA Lead',
          location: 'City, Country',
          startDate: DateTime(2023, 1, 1),
          isCurrentlyWorking: true,
          description: 'Built Flutter test automation for checkout flows.',
          achievements: const <String>[
            'Increased release confidence across iOS and Android.',
          ],
        ),
      ],
      education: <Education>[
        Education(
          id: 'edu-1',
          institution: 'Your University / College',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          location: 'City, Country',
          startDate: DateTime(2018, 1, 1),
        ),
      ],
      skills: <Skill>[
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Mobile App Development'),
        Skill(id: 'skill-3', name: 'Project Management'),
      ],
      languages: <Language>[
        Language(id: 'lang-1', name: 'English', proficiency: 'Fluent'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
    );

    final translated = await TranslationService.translateResume(resume, 'Spanish');

    expect(translated.personalInfo.address, 'Ciudad, pais');
    expect(translated.experience.first.company, 'Empresa mas reciente');
    expect(translated.experience.first.location, 'Ciudad, pais');
    expect(translated.education.first.institution, 'Tu universidad o instituto');
    expect(translated.education.first.location, 'Ciudad, pais');
    expect(translated.skills[0].name, 'Flutter');
    expect(translated.skills[1].name, 'Desarrollo de aplicaciones moviles');
    expect(translated.skills[2].name, 'Gestion de proyectos');
    expect(translated.languages[0].name, 'Ingles');
    expect(translated.languages[0].proficiency, 'fluido');
    expect(translated.languages[1].name, 'Espanol');
    expect(translated.languages[1].proficiency, 'profesional');
  });

  test('translateResume localizes language proficiency without machine translating names',
      () async {
    final resume = _buildResume().copyWith(
      languages: <Language>[
        Language(id: 'lang-1', name: 'English', proficiency: 'Fluent'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Beginner'),
      ],
    );

    final translated = await TranslationService.translateResume(resume, 'Spanish');

    expect(translated.languages[0].name, 'Ingles');
    expect(translated.languages[0].proficiency, 'fluido');
    expect(translated.languages[1].name, 'German');
    expect(translated.languages[1].proficiency, 'principiante');
  });

  test('translateResume translates project titles and certification names for Spanish',
      () async {
    final original = _buildResume().copyWith(
      projects: <Project>[
        Project(
          id: 'proj-1',
          title: 'AI Resume Builder',
          description: 'Built a resume parser and job tracker.',
        ),
      ],
      certifications: <Certification>[
        Certification(
          id: 'cert-1',
          name: 'ISTQB Certification',
          issuer: 'ISTQB',
        ),
      ],
    );

    TranslationService.clearCache();
    TranslationService.debugBackendOverride = (text, _) async {
      final replacements = <String, String>{
        'AI Resume Builder': 'Constructor de curriculums con IA',
        'Built a resume parser and job tracker.':
            'Construi un analizador de curriculums y un rastreador de empleos.',
        'ISTQB Certification': 'Certificacion ISTQB',
      };

      var translated = text;
      replacements.forEach((source, target) {
        translated = translated.replaceAll(source, target);
      });
      return translated;
    };

    final translated = await TranslationService.translateResume(original, 'Spanish');

    expect(translated.projects.first.title, 'Constructor de curriculums con IA');
    expect(translated.certifications.first.name, 'Certificacion ISTQB');
  });

  test('translateResume polishes literal Spanish phrasing into natural resume language',
      () async {
    final original = _buildResume().copyWith(
      objective:
          'Mobile developer oriented to results with a proven track record of delivering high-impact solutions, leveraging expertise to drive innovation and growth.',
      experience: <Experience>[
        Experience(
          id: 'exp-1',
          company: 'Most Recent Company',
          position: 'Senior Mobile Developer',
          location: 'City, Country',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Collaborated with cross-functional stakeholders to ensure seamless project execution.',
          achievements: const <String>[
            'Mentored junior developers, elevating team capabilities.',
            'Implemented process improvements, resulting in a 15% reduction in project timelines.',
          ],
        ),
      ],
      skills: <Skill>[
        Skill(id: 'skill-1', name: 'Mentorship'),
        Skill(id: 'skill-2', name: 'Client Relationship Management'),
      ],
      languages: <Language>[
        Language(id: 'lang-1', name: 'English', proficiency: 'Fluent'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
    );

    TranslationService.clearCache();
    TranslationService.debugBackendOverride = (text, _) async {
      final replacements = <String, String>{
        'Mobile developer oriented to results with a proven track record of delivering high-impact solutions, leveraging expertise to drive innovation and growth.':
            'Desarrollador móvil orientado a resultados con una trayectoria comprobada en la entrega de soluciones de alto impacto, aprovechando la experiencia para impulsar la innovación y el crecimiento.',
        'Senior Mobile Developer': 'Desarrollador Móvil Sénior',
        'Most Recent Company': 'Empresa más reciente',
        'City, Country': 'Ciudad, País',
        'Collaborated with cross-functional stakeholders to ensure seamless project execution.':
            'Colaboré con partes interesadas multifuncionales para garantizar una ejecución perfecta del proyecto.',
        'Mentored junior developers, elevating team capabilities.':
            'Fui mentor de desarrolladores junior, elevando las capacidades del equipo.',
        'Implemented process improvements, resulting in a 15% reduction in project timelines.':
            'Implementé mejoras en los procesos, lo que resultó en una reducción del 15 % en los plazos del proyecto.',
        'Mentorship': 'Tutoría',
        'Client Relationship Management': 'Gestión de relaciones con el cliente',
        'English': 'Inglés',
        'Spanish': 'Español',
      };

      var translated = text;
      replacements.forEach((source, target) {
        translated = translated.replaceAll(source, target);
      });
      return translated;
    };

    final translated = await TranslationService.translateResume(original, 'Spanish');

    expect(
      translated.objective,
      contains('aprovechando mi experiencia'),
    );
    expect(
      translated.experience.first.description,
      contains('equipos y partes interesadas de distintas áreas'),
    );
    expect(
      translated.experience.first.description,
      contains('ejecución fluida del proyecto'),
    );
    expect(
      translated.experience.first.achievements.first,
      startsWith('Guié a desarrolladores junior'),
    );
    expect(
      translated.experience.first.achievements.last,
      contains('mejoras de proceso'),
    );
    expect(
      translated.experience.first.achievements.last,
      contains('redujo los plazos del proyecto en 15 %'),
    );
    expect(translated.skills[0].name, 'Mentoría');
    expect(translated.skills[1].name, 'Gestión de relaciones con clientes');
    expect(translated.languages[0].proficiency, 'fluido');
    expect(translated.languages[1].proficiency, 'profesional');
  });

  test('translateResume leaves English resumes unchanged', () async {
    final original = _buildResume();
    final translated = await TranslationService.translateResume(original, 'English');

    expect(translated.personalInfo.jobTitle, original.personalInfo.jobTitle);
    expect(translated.experience.first.description, original.experience.first.description);
    expect(translated.education.first.degree, original.education.first.degree);
    expect(translated.languages.first.proficiency, original.languages.first.proficiency);
  });

  test('translateResume uses supported backend code for Norwegian', () async {
    late String capturedTarget;
    TranslationService.debugBackendOverride = (text, backendLangCode) async {
      capturedTarget = backendLangCode;
      return text.replaceAll('Senior QA Engineer', 'Senior QA-ingenior');
    };

    final translated = await TranslationService.translateResume(
      _buildResume(),
      'Norwegian',
    );

    expect(capturedTarget, 'nb');
    expect(translated.personalInfo.jobTitle, 'Senior QA-ingenior');
  });

  test('translateBatch falls back to per-item translation when chunk request fails', () async {
    TranslationService.clearCache();
    var batchAttempted = false;
    TranslationService.debugBackendOverride = (text, _) async {
      if (text.contains('¶¶¶')) {
        batchAttempted = true;
        throw Exception('chunk failed');
      }

      return text
          .replaceAll('Senior QA Engineer', 'Ingeniera QA Senior')
          .replaceAll(
            'Build reliable mobile releases for global users.',
            'Creo lanzamientos moviles confiables para usuarios globales.',
          );
    };

    final translated = await TranslationService.translateResume(
      _buildResume(),
      'Spanish',
    );

    expect(batchAttempted, isTrue);
    expect(translated.personalInfo.jobTitle, 'Ingeniera QA Senior');
    expect(
      translated.objective,
      'Creo lanzamientos moviles confiables para usuarios globales.',
    );
  });
}