/// Translations for resume PDF section headers.
///
/// Latin-script languages are fully translated.
/// Non-Latin scripts (Arabic, Chinese, Japanese, Korean, Hindi, Russian, etc.)
/// fall back to English because the default PDF fonts only support Latin-1.
class ResumeTranslations {
  ResumeTranslations._();

  /// All languages available as resume writing languages (name → locale label).
  static const List<Map<String, String>> supportedLanguages = [
    {'name': 'English',    'flag': '🇬🇧'},
    {'name': 'Spanish',    'flag': '🇪🇸'},
    {'name': 'French',     'flag': '🇫🇷'},
    {'name': 'German',     'flag': '🇩🇪'},
    {'name': 'Portuguese', 'flag': '🇧🇷'},
    {'name': 'Italian',    'flag': '🇮🇹'},
    {'name': 'Dutch',      'flag': '🇳🇱'},
    {'name': 'Swedish',    'flag': '🇸🇪'},
    {'name': 'Norwegian',  'flag': '🇳🇴'},
    {'name': 'Danish',     'flag': '🇩🇰'},
    {'name': 'Finnish',    'flag': '🇫🇮'},
    {'name': 'Polish',     'flag': '🇵🇱'},
    {'name': 'Czech',      'flag': '🇨🇿'},
    {'name': 'Romanian',   'flag': '🇷🇴'},
    {'name': 'Turkish',    'flag': '🇹🇷'},
    // Non-Latin (section headers stay in English in PDFs)
    {'name': 'Arabic',            'flag': '🇸🇦'},
    {'name': 'Mandarin Chinese',  'flag': '🇨🇳'},
    {'name': 'Japanese',          'flag': '🇯🇵'},
    {'name': 'Korean',            'flag': '🇰🇷'},
    {'name': 'Hindi',             'flag': '🇮🇳'},
    {'name': 'Russian',           'flag': '🇷🇺'},
    {'name': 'Ukrainian',         'flag': '🇺🇦'},
    {'name': 'Greek',             'flag': '🇬🇷'},
  ];

  // ── Section header key constants ──────────────────────────────────────────
  static const kExperience   = 'WORK EXPERIENCE';
  static const kProExp       = 'PROFESSIONAL EXPERIENCE';
  static const kExpShort     = 'EXPERIENCE';
  static const kSummary      = 'PROFESSIONAL SUMMARY';
  static const kSummaryShort = 'SUMMARY';
  static const kEducation    = 'EDUCATION';
  static const kSkills       = 'SKILLS';
  static const kProjects     = 'PROJECTS';
  static const kCertif       = 'CERTIFICATIONS';
  static const kCertifShort  = 'CERTIFICATION';
  static const kLanguages    = 'LANGUAGES';
  static const kContact      = 'CONTACT';
  static const kReferences   = 'REFERENCES';
  static const kObjective    = 'OBJECTIVE';
  static const kPresent      = 'Present';
  static const kAboutMe      = 'ABOUT ME';
  static const kAbout        = 'ABOUT';
  static const kProfile      = 'PROFILE';
  static const kProfileSnapshot = 'PROFILE SNAPSHOT';
  static const kCareerExperience = 'CAREER EXPERIENCE';
  static const kCoreSkills   = 'CORE SKILLS';
  static const kCoreCompetencies = 'CORE COMPETENCIES';
  static const kSelectedProjects = 'SELECTED PROJECTS';
  static const kExperienceSummary = 'EXPERIENCE SUMMARY';
  static const kIssued       = 'Issued';
  static const kExpires      = 'Expires';
  static const kCredentialId = 'Credential ID';

  // ── Form field label keys ────────────────────────────────────────────────
  static const kFullName       = 'Full Name';
  static const kEmail          = 'Email Address';
  static const kPhone          = 'Phone Number';
  static const kJobTitle       = 'Job Title';
  static const kCompany        = 'Company';
  static const kLocation       = 'Location';
  static const kStartDate      = 'Start Date';
  static const kEndDate        = 'End Date';
  static const kDescription    = 'Description';
  static const kAchievements   = 'Key Achievements';
  static const kDegree         = 'Degree';
  static const kInstitution    = 'Institution';
  static const kSkillName      = 'Skill Name';
  static const kProficiency    = 'Proficiency Level';
  static const kProjectName    = 'Project Name';
  static const kCertName       = 'Certification Name';

  // ── Translation tables ────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _table = {
    'Spanish': {
      kExperience:   'EXPERIENCIA LABORAL',
      kProExp:       'EXPERIENCIA PROFESIONAL',
      kExpShort:     'EXPERIENCIA',
      kSummary:      'RESUMEN PROFESIONAL',
      kSummaryShort: 'RESUMEN',
      kEducation:    'EDUCACION',
      kSkills:       'HABILIDADES',
      kProjects:     'PROYECTOS',
      kCertif:       'CERTIFICACIONES',
      kCertifShort:  'CERTIFICACION',
      kLanguages:    'IDIOMAS',
      kContact:      'CONTACTO',
      kReferences:   'REFERENCIAS',
      kObjective:    'OBJETIVO',
      kPresent:      'Actualidad',
      kAboutMe:      'SOBRE MI',
      kAbout:        'SOBRE MI',
      kProfile:      'PERFIL',
      kProfileSnapshot: 'RESUMEN DEL PERFIL',
      kCareerExperience: 'EXPERIENCIA PROFESIONAL',
      kCoreSkills:   'HABILIDADES CLAVE',
      kCoreCompetencies: 'COMPETENCIAS CLAVE',
      kSelectedProjects: 'PROYECTOS DESTACADOS',
      kExperienceSummary: 'RESUMEN DE EXPERIENCIA',
      kIssued:       'Emitido',
      kExpires:      'Vence',
      kCredentialId: 'ID de credencial',
      // Field labels
      kFullName:     'Nombre Completo',
      kEmail:        'Correo Electrónico',
      kPhone:        'Número de Teléfono',
      kJobTitle:     'Puesto de Trabajo',
      kCompany:      'Empresa',
      kLocation:     'Ubicación',
      kStartDate:    'Fecha de Inicio',
      kEndDate:      'Fecha de Fin',
      kDescription:  'Descripción',
      kAchievements: 'Logros Clave',
      kDegree:       'Titulación',
      kInstitution:  'Institución',
      kSkillName:    'Nombre de Habilidad',
      kProficiency:  'Nivel de Competencia',
      kProjectName:  'Nombre del Proyecto',
      kCertName:     'Nombre de Certificación',
    },
    'French': {
      kExperience:   'EXPERIENCE PROFESSIONNELLE',
      kProExp:       'EXPERIENCE PROFESSIONNELLE',
      kExpShort:     'EXPERIENCE',
      kSummary:      'PROFIL PROFESSIONNEL',
      kSummaryShort: 'PROFIL',
      kEducation:    'FORMATION',
      kSkills:       'COMPETENCES',
      kProjects:     'PROJETS',
      kCertif:       'CERTIFICATIONS',
      kCertifShort:  'CERTIFICATION',
      kLanguages:    'LANGUES',
      kContact:      'CONTACT',
      kReferences:   'REFERENCES',
      kObjective:    'OBJECTIF',
      kPresent:      'Aujourd\'hui',
      // Field labels
      kFullName:     'Nom Complet',
      kEmail:        'Adresse E-mail',
      kPhone:        'Numéro de Téléphone',
      kJobTitle:     'Titre du Poste',
      kCompany:      'Entreprise',
      kLocation:     'Lieu',
      kStartDate:    'Date de Début',
      kEndDate:      'Date de Fin',
      kDescription:  'Description',
      kAchievements: 'Réalisations Clés',
      kDegree:       'Diplôme',
      kInstitution:  'Établissement',
      kSkillName:    'Nom de Compétence',
      kProficiency:  'Niveau de Compétence',
      kProjectName:  'Nom du Projet',
      kCertName:     'Nom de Certification',
    },
    'German': {
      kExperience:   'BERUFSERFAHRUNG',
      kProExp:       'BERUFLICHE ERFAHRUNG',
      kExpShort:     'ERFAHRUNG',
      kSummary:      'BERUFLICHES PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'AUSBILDUNG',
      kSkills:       'FAHIGKEITEN',
      kProjects:     'PROJEKTE',
      kCertif:       'ZERTIFIZIERUNGEN',
      kCertifShort:  'ZERTIFIZIERUNG',
      kLanguages:    'SPRACHEN',
      kContact:      'KONTAKT',
      kReferences:   'REFERENZEN',
      kObjective:    'ZIELSETZUNG',
      kPresent:      'Heute',
      // Field labels
      kFullName:     'Vollständiger Name',
      kEmail:        'E-Mail-Adresse',
      kPhone:        'Telefonnummer',
      kJobTitle:     'Jobtitel',
      kCompany:      'Unternehmen',
      kLocation:     'Ort',
      kStartDate:    'Startdatum',
      kEndDate:      'Enddatum',
      kDescription:  'Beschreibung',
      kAchievements: 'Hauptleistungen',
      kDegree:       'Abschluss',
      kInstitution:  'Bildungseinrichtung',
      kSkillName:    'Fähigkeitsname',
      kProficiency:  'Kompetenzstufe',
      kProjectName:  'Projektname',
      kCertName:     'Zertifikatsname',
    },
    'Portuguese': {
      kExperience:   'EXPERIENCIA PROFISSIONAL',
      kProExp:       'EXPERIENCIA PROFISSIONAL',
      kExpShort:     'EXPERIENCIA',
      kSummary:      'PERFIL PROFISSIONAL',
      kSummaryShort: 'PERFIL',
      kEducation:    'FORMACAO',
      kSkills:       'COMPETENCIAS',
      kProjects:     'PROJETOS',
      kCertif:       'CERTIFICACOES',
      kCertifShort:  'CERTIFICACAO',
      kLanguages:    'IDIOMAS',
      kContact:      'CONTATO',
      kReferences:   'REFERENCIAS',
      kObjective:    'OBJETIVO',
      kPresent:      'Presente',      // Field labels
      kFullName:     'Nome Completo',
      kEmail:        'Endereço de Email',
      kPhone:        'Número de Telefone',
      kJobTitle:     'Título da Função',
      kCompany:      'Empresa',
      kLocation:     'Localização',
      kStartDate:    'Data de Início',
      kEndDate:      'Data de Fim',
      kDescription:  'Descrição',
      kAchievements: 'Realizações Principais',
      kDegree:       'Grau',
      kInstitution:  'Instituição',
      kSkillName:    'Nome da Habilidade',
      kProficiency:  'Nível de Proficiência',
      kProjectName:  'Nome do Projeto',
      kCertName:     'Nome da Certificação',    },
    'Italian': {
      kExperience:   'ESPERIENZA LAVORATIVA',
      kProExp:       'ESPERIENZA PROFESSIONALE',
      kExpShort:     'ESPERIENZA',
      kSummary:      'PROFILO PROFESSIONALE',
      kSummaryShort: 'PROFILO',
      kEducation:    'ISTRUZIONE',
      kSkills:       'COMPETENZE',
      kProjects:     'PROGETTI',
      kCertif:       'CERTIFICAZIONI',
      kCertifShort:  'CERTIFICAZIONE',
      kLanguages:    'LINGUE',
      kContact:      'CONTATTI',
      kReferences:   'RIFERIMENTI',
      kObjective:    'OBIETTIVO',
      kPresent:      'Presente',
    },
    'Dutch': {
      kExperience:   'WERKERVARING',
      kProExp:       'PROFESSIONELE ERVARING',
      kExpShort:     'ERVARING',
      kSummary:      'PROFESSIONEEL PROFIEL',
      kSummaryShort: 'PROFIEL',
      kEducation:    'OPLEIDING',
      kSkills:       'VAARDIGHEDEN',
      kProjects:     'PROJECTEN',
      kCertif:       'CERTIFICATEN',
      kCertifShort:  'CERTIFICAAT',
      kLanguages:    'TALEN',
      kContact:      'CONTACT',
      kReferences:   'REFERENTIES',
      kObjective:    'DOELSTELLING',
      kPresent:      'Heden',
    },
    'Swedish': {
      kExperience:   'ARBETSLIVSERFARENHET',
      kProExp:       'YRKESERFARENHET',
      kExpShort:     'ERFARENHET',
      kSummary:      'PROFESSIONELL PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'UTBILDNING',
      kSkills:       'FARDIGHETER',
      kProjects:     'PROJEKT',
      kCertif:       'CERTIFIERINGAR',
      kCertifShort:  'CERTIFIERING',
      kLanguages:    'SPRAK',
      kContact:      'KONTAKT',
      kReferences:   'REFERENSER',
      kObjective:    'MAL',
      kPresent:      'Nu',
    },
    'Norwegian': {
      kExperience:   'ARBEIDSERFARING',
      kProExp:       'YRKESERFARING',
      kExpShort:     'ERFARING',
      kSummary:      'PROFESJONELL PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'UTDANNING',
      kSkills:       'FERDIGHETER',
      kProjects:     'PROSJEKTER',
      kCertif:       'SERTIFISERINGER',
      kCertifShort:  'SERTIFISERING',
      kLanguages:    'SPRAK',
      kContact:      'KONTAKT',
      kReferences:   'REFERANSER',
      kObjective:    'MAL',
      kPresent:      'Na',
    },
    'Danish': {
      kExperience:   'ERHVERVSERFARING',
      kProExp:       'FAGLIG ERFARING',
      kExpShort:     'ERFARING',
      kSummary:      'FAGLIG PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'UDDANNELSE',
      kSkills:       'KOMPETENCER',
      kProjects:     'PROJEKTER',
      kCertif:       'CERTIFICERINGER',
      kCertifShort:  'CERTIFICERING',
      kLanguages:    'SPROG',
      kContact:      'KONTAKT',
      kReferences:   'REFERENCER',
      kObjective:    'MAL',
      kPresent:      'Nu',
    },
    'Finnish': {
      kExperience:   'TYOKOKEMUS',
      kProExp:       'AMMATILLINEN KOKEMUS',
      kExpShort:     'KOKEMUS',
      kSummary:      'AMMATILLINEN PROFIILI',
      kSummaryShort: 'PROFIILI',
      kEducation:    'KOULUTUS',
      kSkills:       'TAIDOT',
      kProjects:     'PROJEKTIT',
      kCertif:       'SERTIFIKAATIT',
      kCertifShort:  'SERTIFIKAATTI',
      kLanguages:    'KIELET',
      kContact:      'YHTEYSTIEDOT',
      kReferences:   'SUOSITUKSET',
      kObjective:    'TAVOITE',
      kPresent:      'Nyt',
    },
    'Polish': {
      kExperience:   'DOSWIADCZENIE ZAWODOWE',
      kProExp:       'DOSWIADCZENIE PROFESJONALNE',
      kExpShort:     'DOSWIADCZENIE',
      kSummary:      'PROFIL ZAWODOWY',
      kSummaryShort: 'PROFIL',
      kEducation:    'WYKSZTALCENIE',
      kSkills:       'UMIEJETNOSCI',
      kProjects:     'PROJEKTY',
      kCertif:       'CERTYFIKATY',
      kCertifShort:  'CERTYFIKAT',
      kLanguages:    'JEZYKI',
      kContact:      'KONTAKT',
      kReferences:   'REFERENCJE',
      kObjective:    'CEL',
      kPresent:      'Obecnie',
    },
    'Czech': {
      kExperience:   'PRACOVNI ZKUSENOSTI',
      kProExp:       'ODBORNE ZKUSENOSTI',
      kExpShort:     'ZKUSENOSTI',
      kSummary:      'PROFESNI PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'VZDELANI',
      kSkills:       'DOVEDNOSTI',
      kProjects:     'PROJEKTY',
      kCertif:       'CERTIFIKATY',
      kCertifShort:  'CERTIFIKAT',
      kLanguages:    'JAZYKY',
      kContact:      'KONTAKT',
      kReferences:   'REFERENCE',
      kObjective:    'CIL',
      kPresent:      'Soucasnost',
    },
    'Romanian': {
      kExperience:   'EXPERIENTA PROFESIONALA',
      kProExp:       'EXPERIENTA PROFESIONALA',
      kExpShort:     'EXPERIENTA',
      kSummary:      'PROFIL PROFESIONAL',
      kSummaryShort: 'PROFIL',
      kEducation:    'EDUCATIE',
      kSkills:       'ABILITATI',
      kProjects:     'PROIECTE',
      kCertif:       'CERTIFICARI',
      kCertifShort:  'CERTIFICARE',
      kLanguages:    'LIMBI STRAINE',
      kContact:      'CONTACT',
      kReferences:   'REFERINTE',
      kObjective:    'OBIECTIV',
      kPresent:      'Prezent',
    },
    'Turkish': {
      kExperience:   'IS DENEYIMI',
      kProExp:       'MESLEKI DENEYIM',
      kExpShort:     'DENEYIM',
      kSummary:      'MESLEKI PROFIL',
      kSummaryShort: 'PROFIL',
      kEducation:    'EGITIM',
      kSkills:       'BECERILER',
      kProjects:     'PROJELER',
      kCertif:       'SERTIFIKALAR',
      kCertifShort:  'SERTIFIKA',
      kLanguages:    'DILLER',
      kContact:      'ILETISIM',
      kReferences:   'REFERANSLAR',
      kObjective:    'HEDEF',
      kPresent:      'Gunumuz',
    },
  };

  static const Map<String, String> _dateLocales = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Portuguese': 'pt',
    'Italian': 'it',
    'Dutch': 'nl',
    'Swedish': 'sv',
    'Norwegian': 'no',
    'Danish': 'da',
    'Finnish': 'fi',
    'Polish': 'pl',
    'Czech': 'cs',
    'Romanian': 'ro',
    'Turkish': 'tr',
    'Arabic': 'ar',
    'Mandarin Chinese': 'zh',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Hindi': 'hi',
    'Russian': 'ru',
    'Ukrainian': 'uk',
    'Greek': 'el',
  };

  /// Returns the translated string for [text] in [language].
  /// Tries exact match first, then uppercase key (so Title Case inputs work too).
  /// Falls back to [text] (original) if the language is not supported
  /// or the key is not found (also covers all non-Latin scripts).
  static String translate(String text, String language) {
    if (language == 'English') return text;
    final map = _table[language];
    if (map == null) return text;
    // Exact match first; then try uppercase key for Title Case inputs
    return map[text] ?? map[text.toUpperCase()] ?? text;
  }

  /// Returns a translated form field label based on the selected language.
  /// Example: getFieldLabel(ResumeTranslations.kFullName, 'Spanish') → 'Nombre Completo'
  static String getFieldLabel(String fieldKey, String language) {
    return translate(fieldKey, language);
  }

  /// Convenience: returns the "Present" label for a given language.
  static String present(String language) =>
      translate(kPresent, language);

    /// Locale code used for date formatting in preview/export flows.
    static String dateLocale(String language) =>
      _dateLocales[language] ?? 'en';
}
