import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resume_model.dart';
import 'libretranslate_service.dart';

typedef TranslationBackendOverride = Future<String> Function(
  String text,
  String backendLangCode,
);

/// Translation service for resume content translation.
///
/// LibreTranslate is the active backend by default. Google Translate remains
/// available as a fallback implementation if the backend is switched later.
class TranslationService {
  /// LibreTranslate is enabled by default for all translation requests.
  static bool useLibreTranslate = true;
  static const String _cacheVersion = 'v5';
  static TranslationBackendOverride? debugBackendOverride;
  // Google Translate "gtx" endpoint — free, no auth, no hard rate limit
  static const String _gtApi =
      'https://translate.googleapis.com/translate_a/single';

  // Separator inserted between individual texts when concatenating.
  // ¶¶¶ is rarely used in natural language and almost never translated.
  static const String _sep = '\n¶¶¶\n';

  // Keep each concatenated request under this char limit (practical GT limit ~5000)
  static const int _maxCharsPerRequest = 4500;

  static final Map<String, String> _cache = {};

  // Languages that should use only static label localization (none for now).
  static const Set<String> _staticLocalizationOnlyLanguages = {};

  static const Set<String> _genericPlaceholderTexts = {
    'most recent company',
    'previous company',
    'current company',
    'company name',
    'city, country',
    'city / country',
    'your university / college',
    'your university/college',
    'your university',
    'your college',
    'your school',
  };

  static const Map<String, Map<String, String>> _exactTextLocalizations = {
    'Spanish': {
      'Computers': 'Informatica',
      'Computer Science': 'Informatica',
      'Resumix AI': 'Resumix AI',
      'E-commerce Web Application': 'Aplicacion web de comercio electronico',
    },
  };

  static const Set<String> _technicalSkillPhrases = {
    'flutter',
    'dart',
    'firebase',
    'react',
    'react native',
    'node.js',
    'node',
    'javascript',
    'typescript',
    'python',
    'java',
    'kotlin',
    'swift',
    'c#',
    'c++',
    'sql',
    'nosql',
    'graphql',
    'rest api',
    'rest',
    'api',
    'apis',
    'aws',
    'azure',
    'gcp',
    'docker',
    'kubernetes',
    'git',
    'github',
    'gitlab',
    'ci/cd',
    'html',
    'css',
    'figma',
    'adobe xd',
    'photoshop',
    'illustrator',
    'jira',
    'selenium',
    'playwright',
    'cypress',
    'postgresql',
    'postgres',
    'mysql',
    'mongodb',
    'linux',
    'ios',
    'android',
  };

  static const Set<String> _technicalSkillTokens = {
    'flutter',
    'dart',
    'firebase',
    'react',
    'native',
    'node',
    'node.js',
    'javascript',
    'typescript',
    'python',
    'java',
    'kotlin',
    'swift',
    'sql',
    'nosql',
    'graphql',
    'rest',
    'api',
    'apis',
    'aws',
    'azure',
    'gcp',
    'docker',
    'kubernetes',
    'git',
    'github',
    'gitlab',
    'ci',
    'cd',
    'html',
    'css',
    'figma',
    'adobe',
    'xd',
    'photoshop',
    'illustrator',
    'jira',
    'selenium',
    'playwright',
    'cypress',
    'postgresql',
    'postgres',
    'mysql',
    'mongodb',
    'linux',
    'ios',
    'android',
    'qa',
    'ux',
    'ui',
    'crm',
    'erp',
  };

  static const Map<String, Map<String, String>>
      _languageProficiencyLocalizations = {
    'Spanish': {
      'Native': 'nativo',
      'Fluent': 'fluido',
      'Professional': 'profesional',
      'Conversational': 'conversacional',
      'Intermediate': 'intermedio',
      'Advanced': 'avanzado',
      'Beginner': 'principiante',
      'Basic': 'basico',
    },
    'French': {
      'Native': 'Natif',
      'Fluent': 'Courant',
      'Professional': 'Professionnel',
      'Conversational': 'Conversationnel',
      'Intermediate': 'Intermediaire',
      'Advanced': 'Avance',
      'Beginner': 'Debutant',
      'Basic': 'Basique',
    },
    'German': {
      'Native': 'Muttersprachlich',
      'Fluent': 'Fliessend',
      'Professional': 'Beruflich',
      'Conversational': 'Konversationssicher',
      'Intermediate': 'Mittelstufe',
      'Advanced': 'Fortgeschritten',
      'Beginner': 'Anfaenger',
      'Basic': 'Grundkenntnisse',
    },
    'Portuguese': {
      'Native': 'Nativo',
      'Fluent': 'Fluente',
      'Professional': 'Profissional',
      'Conversational': 'Conversacional',
      'Intermediate': 'Intermediario',
      'Advanced': 'Avancado',
      'Beginner': 'Iniciante',
      'Basic': 'Basico',
    },
    'Italian': {
      'Native': 'Madrelingua',
      'Fluent': 'Fluente',
      'Professional': 'Professionale',
      'Conversational': 'Conversazionale',
      'Intermediate': 'Intermedio',
      'Advanced': 'Avanzato',
      'Beginner': 'Principiante',
      'Basic': 'Base',
    },
    'Dutch': {
      'Native': 'Moedertaal',
      'Fluent': 'Vloeiend',
      'Professional': 'Professioneel',
      'Conversational': 'Conversationeel',
      'Intermediate': 'Gemiddeld',
      'Advanced': 'Gevorderd',
      'Beginner': 'Beginner',
      'Basic': 'Basis',
    },
    'Swedish': {
      'Native': 'Modersmal',
      'Fluent': 'Flytande',
      'Professional': 'Professionell',
      'Conversational': 'Konversation',
      'Intermediate': 'Medel',
      'Advanced': 'Avancerad',
      'Beginner': 'Nyborjare',
      'Basic': 'Grundlaggande',
    },
    'Norwegian': {
      'Native': 'Morsmal',
      'Fluent': 'Flytende',
      'Professional': 'Profesjonell',
      'Conversational': 'Samtalebasert',
      'Intermediate': 'Mellomniva',
      'Advanced': 'Avansert',
      'Beginner': 'Nybegynner',
      'Basic': 'Grunnleggende',
    },
    'Danish': {
      'Native': 'Modersmal',
      'Fluent': 'Flydende',
      'Professional': 'Professionel',
      'Conversational': 'Samtaleniveau',
      'Intermediate': 'Mellemniveau',
      'Advanced': 'Avanceret',
      'Beginner': 'Begynder',
      'Basic': 'Grundlaeggende',
    },
    'Finnish': {
      'Native': 'Aidinkieli',
      'Fluent': 'Sujuva',
      'Professional': 'Ammatillinen',
      'Conversational': 'Keskusteleva',
      'Intermediate': 'Keskitaso',
      'Advanced': 'Edistynyt',
      'Beginner': 'Aloittelija',
      'Basic': 'Perustaso',
    },
    'Polish': {
      'Native': 'Ojczysty',
      'Fluent': 'Biegly',
      'Professional': 'Profesjonalny',
      'Conversational': 'Konwersacyjny',
      'Intermediate': 'Sredniozaawansowany',
      'Advanced': 'Zaawansowany',
      'Beginner': 'Poczatkujacy',
      'Basic': 'Podstawowy',
    },
    'Czech': {
      'Native': 'Rodily mluvci',
      'Fluent': 'Plynuly',
      'Professional': 'Profesionalni',
      'Conversational': 'Konverzacni',
      'Intermediate': 'Stredne pokrocily',
      'Advanced': 'Pokrocily',
      'Beginner': 'Zacatecnik',
      'Basic': 'Zakladni',
    },
    'Romanian': {
      'Native': 'Nativ',
      'Fluent': 'Fluent',
      'Professional': 'Profesional',
      'Conversational': 'Conversational',
      'Intermediate': 'Intermediar',
      'Advanced': 'Avansat',
      'Beginner': 'Incepator',
      'Basic': 'De baza',
    },
    'Turkish': {
      'Native': 'Ana dil',
      'Fluent': 'Akici',
      'Professional': 'Profesyonel',
      'Conversational': 'Gunluk konusma',
      'Intermediate': 'Orta seviye',
      'Advanced': 'Ileri seviye',
      'Beginner': 'Baslangic',
      'Basic': 'Temel',
    },
  };

  static const Map<String, Map<String, String>> _workModeLocalizations = {
    'Spanish': {
      'Remote': 'Remoto',
      'Hybrid': 'Hibrido',
      'On-site': 'Presencial',
      'Onsite': 'Presencial',
    },
    'French': {
      'Remote': 'A distance',
      'Hybrid': 'Hybride',
      'On-site': 'Sur site',
      'Onsite': 'Sur site',
    },
    'German': {
      'Remote': 'Remote',
      'Hybrid': 'Hybrid',
      'On-site': 'Vor Ort',
      'Onsite': 'Vor Ort',
    },
    'Portuguese': {
      'Remote': 'Remoto',
      'Hybrid': 'Hibrido',
      'On-site': 'Presencial',
      'Onsite': 'Presencial',
    },
    'Italian': {
      'Remote': 'Remoto',
      'Hybrid': 'Ibrido',
      'On-site': 'In sede',
      'Onsite': 'In sede',
    },
    'Dutch': {
      'Remote': 'Op afstand',
      'Hybrid': 'Hybride',
      'On-site': 'Op locatie',
      'Onsite': 'Op locatie',
    },
    'Swedish': {
      'Remote': 'Distans',
      'Hybrid': 'Hybrid',
      'On-site': 'Pa plats',
      'Onsite': 'Pa plats',
    },
    'Norwegian': {
      'Remote': 'Fjernarbeid',
      'Hybrid': 'Hybrid',
      'On-site': 'Pa stedet',
      'Onsite': 'Pa stedet',
    },
    'Danish': {
      'Remote': 'Fjernarbejde',
      'Hybrid': 'Hybrid',
      'On-site': 'Pa stedet',
      'Onsite': 'Pa stedet',
    },
    'Finnish': {
      'Remote': 'Eta',
      'Hybrid': 'Hybridi',
      'On-site': 'Paikan paalla',
      'Onsite': 'Paikan paalla',
    },
    'Polish': {
      'Remote': 'Zdalnie',
      'Hybrid': 'Hybrydowo',
      'On-site': 'Na miejscu',
      'Onsite': 'Na miejscu',
    },
    'Czech': {
      'Remote': 'Na dalku',
      'Hybrid': 'Hybridni',
      'On-site': 'Na miste',
      'Onsite': 'Na miste',
    },
    'Romanian': {
      'Remote': 'La distanta',
      'Hybrid': 'Hibrid',
      'On-site': 'La sediu',
      'Onsite': 'La sediu',
    },
    'Turkish': {
      'Remote': 'Uzaktan',
      'Hybrid': 'Hibrit',
      'On-site': 'Ofiste',
      'Onsite': 'Ofiste',
    },
  };

  static const Map<String, String> _langCodes = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Portuguese': 'pt',
    'Italian': 'it',
    'Dutch': 'nl',
    'Swedish': 'sv',
    'Norwegian': 'nb',
    'Danish': 'da',
    'Finnish': 'fi',
    'Polish': 'pl',
    'Czech': 'cs',
    'Romanian': 'ro',
    'Turkish': 'tr',
    'Arabic': 'ar',
    'Mandarin Chinese': 'zh-CN',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Hindi': 'hi',
    'Russian': 'ru',
    'Ukrainian': 'uk',
    'Greek': 'el',
  };

  // ---------------------------------------------------------------------------
  // Core single-request call (used by translate() and translateBatch())
  // ---------------------------------------------------------------------------

  /// Calls Google Translate and returns the translated text.
  /// Throws on network error so callers can handle retries / fallback.
  static Future<String> _gtTranslate(String text, String langCode) async {
    final url = Uri.parse(
      '$_gtApi?client=gtx&sl=en&tl=${Uri.encodeComponent(langCode)}'
      '&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Response: [[["translatedSegment","original",...], ...], ...]
      final segments = data[0] as List;
      return segments
          .map((s) => s is List && s.isNotEmpty ? (s[0] as String? ?? '') : '')
          .join();
    }
    throw Exception('Google Translate returned ${response.statusCode}');
  }

  static String _backendLangCode(String langCode) {
    if (!useLibreTranslate) return langCode;

    switch (langCode) {
      case 'zh-CN':
        return 'zh-Hans';
      default:
        return langCode;
    }
  }

  static bool _canUseLibreTranslate(String backendLangCode) {
    return useLibreTranslate &&
        LibreTranslateService.hasApiKey &&
        LibreTranslateService.supportsTargetLanguage(backendLangCode);
  }

  static String _polishSpanishText(String text) {
    var polished = text.trim();
    if (polished.isEmpty) {
      return polished;
    }

    final replacements = <MapEntry<Pattern, String>>[
      MapEntry(RegExp(r'\baprovechando la experiencia\b', caseSensitive: false),
          'aprovechando mi experiencia'),
      MapEntry(
        RegExp(
          r'\bBusco un puesto desafiante en el que pueda aprovechar\b',
          caseSensitive: false,
        ),
        'Busco un puesto desafiante donde pueda aprovechar',
      ),
      MapEntry(
        RegExp(
          r'\bComprometido a permanecer a la vanguardia de las tendencias de la tecnología\b',
          caseSensitive: false,
        ),
        'Comprometido con mantenerme a la vanguardia de las tendencias en tecnología',
      ),
      MapEntry(
        RegExp(
          r'\bComprometida a permanecer a la vanguardia de las tendencias de la tecnología\b',
          caseSensitive: false,
        ),
        'Comprometida con mantenerme a la vanguardia de las tendencias en tecnología',
      ),
      MapEntry(
        RegExp(r'\bpartes interesadas multifuncionales\b', caseSensitive: false),
        'equipos y partes interesadas de distintas áreas',
      ),
      MapEntry(
        RegExp(r'\bgarantizar una ejecución perfecta del proyecto\b', caseSensitive: false),
        'garantizar una ejecución fluida del proyecto',
      ),
      MapEntry(
        RegExp(r'\bFui mentor de\b', caseSensitive: false),
        'Guié a',
      ),
      MapEntry(
        RegExp(r'\bdentro del presupuesto y el alcance\b', caseSensitive: false),
        'dentro del presupuesto y del alcance definidos',
      ),
      MapEntry(
        RegExp(r'\bmejoras en los procesos\b', caseSensitive: false),
        'mejoras de proceso',
      ),
      MapEntry(
        RegExp(r'\bTutoría\b', caseSensitive: false),
        'Mentoría',
      ),
      MapEntry(
        RegExp(r'\bGestión de relaciones con el cliente\b', caseSensitive: false),
        'Gestión de relaciones con clientes',
      ),
      MapEntry(
        RegExp(r'\bincorporación de extremo a extremo\b', caseSensitive: false),
        'procesos integrales de incorporación',
      ),
      MapEntry(
        RegExp(r'\bherramientas y automatización HRIS\b', caseSensitive: false),
        'herramientas de HRIS y automatización',
      ),
      MapEntry(
        RegExp(r'\bSocio colaborador de la alta dirección\b', caseSensitive: false),
        'Socio estratégico de la alta dirección',
      ),
      MapEntry(
        RegExp(r'\bAsistencia en el desarrollo de\b', caseSensitive: false),
        'Colaboré en el desarrollo de',
      ),
      MapEntry(
        RegExp(r'\bControl de versiones aprendido usando\b', caseSensitive: false),
        'Aprendí control de versiones con',
      ),
      MapEntry(
        RegExp(r'\bRendimiento de API mejorado en un\b', caseSensitive: false),
        'Mejoré el rendimiento de la API en un',
      ),
    ];

    for (final replacement in replacements) {
      polished = polished.replaceAll(replacement.key, replacement.value);
    }

    polished = polished.replaceAllMapped(
      RegExp(
        r'\blo que resultó en una reducción del ([0-9]+ ?%) en los plazos del proyecto\b',
        caseSensitive: false,
      ),
      (match) => 'lo que redujo los plazos del proyecto en ${match.group(1)}',
    );

    polished = polished.replaceAll(RegExp(r'\s+'), ' ').trim();
    polished = polished
        .replaceAll('  %', ' %')
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.');

    return polished;
  }

  static String _polishTranslatedText(String text, String targetLanguage) {
    switch (targetLanguage) {
      case 'Spanish':
        return _polishSpanishText(text);
      default:
        return text;
    }
  }

  static String _normalizeTranslationResult(
    String text,
    String targetLanguage,
  ) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    return _polishTranslatedText(normalized, targetLanguage);
  }

  static Future<String> _translateWithBackend(String text, String langCode) {
    final backendLangCode = _backendLangCode(langCode);
    final override = debugBackendOverride;
    if (override != null) {
      return override(text, backendLangCode);
    }
    if (_canUseLibreTranslate(backendLangCode)) {
      return LibreTranslateService.translate(
        text: text,
        sourceLang: 'en',
        targetLang: backendLangCode,
      );
    }
    return _gtTranslate(text, backendLangCode);
  }

  static String _localizeExactMatch(
    String text,
    String targetLanguage,
    Map<String, Map<String, String>> table,
  ) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return text;
    }

    final localized = table[targetLanguage];
    if (localized == null) {
      return text;
    }

    for (final entry in localized.entries) {
      if (entry.key.toLowerCase() == normalized.toLowerCase()) {
        return _polishTranslatedText(entry.value, targetLanguage);
      }
    }

    return text;
  }

  static String _localizeLanguageProficiency(
    String proficiency,
    String targetLanguage,
  ) {
    return _localizeExactMatch(
      proficiency,
      targetLanguage,
      _languageProficiencyLocalizations,
    );
  }

  static String? _localizeWorkMode(
    String? location,
    String targetLanguage,
  ) {
    if (location == null || location.trim().isEmpty) {
      return location;
    }

    return _localizeExactMatch(
      location,
      targetLanguage,
      _workModeLocalizations,
    );
  }

  static String _localizeKnownText(String text, String targetLanguage) {
    return _localizeExactMatch(
      text,
      targetLanguage,
      _exactTextLocalizations,
    );
  }

  static String _preferKnownLocalization(
    String original,
    String translated,
    String targetLanguage,
  ) {
    final localized = _localizeKnownText(original, targetLanguage);
    if (localized != original) {
      return localized;
    }
    return translated;
  }

  static bool _isGenericPlaceholderText(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    if (_genericPlaceholderTexts.contains(normalized)) {
      return true;
    }

    if (normalized.startsWith('your ') &&
        (normalized.contains('university') ||
            normalized.contains('college') ||
            normalized.contains('school'))) {
      return true;
    }

    if ((normalized.contains('company') &&
            (normalized.contains('recent') ||
                normalized.contains('previous') ||
                normalized.contains('current'))) ||
        normalized == 'city, country' ||
        normalized == 'city / country') {
      return true;
    }

    return false;
  }

  static bool _isLikelyTechnicalSkill(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    if (_technicalSkillPhrases.contains(normalized)) {
      return true;
    }

    final tokens = normalized
        .split(RegExp(r'[^a-z0-9+#./-]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return false;
    }

    return tokens.every(
      (token) => _technicalSkillTokens.contains(token) ||
          RegExp(r'^[a-z]?[0-9]+$').hasMatch(token),
    );
  }

  static bool _shouldTranslateSkillLabel(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (_isGenericPlaceholderText(normalized)) {
      return true;
    }

    return !_isLikelyTechnicalSkill(normalized);
  }

  static bool _shouldTranslateLocationLikeText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return false;
    }

    return _isGenericPlaceholderText(text);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Translate a single [text] to [targetLanguage].
  static Future<String> translate(String text, String targetLanguage) async {
    if (text.isEmpty || targetLanguage == 'English') return text;
    final langCode = _langCodes[targetLanguage];
    if (langCode == null) return text;

    final backendLangCode = _backendLangCode(langCode);
    final cacheKey = '${_cacheVersion}_${text}_$backendLangCode';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final translated = await _translateWithBackend(text, langCode);
      final normalized = _normalizeTranslationResult(
        translated,
        targetLanguage,
      );
      _cache[cacheKey] = normalized;
      return normalized;
    } catch (_) {
      return text;
    }
  }

  /// Translate all [texts] in as few HTTP requests as possible.
  ///
  /// Strategy:
  ///  1. Deduplicate — identical strings are only translated once.
  ///  2. Concatenate unique strings with [_sep] into chunks ≤ [_maxCharsPerRequest].
  ///  3. Fire all chunks concurrently — typically just 1–2 requests for a resume.
  ///  4. Split results back and map to original list order.
  ///
  /// Typical resume (50–70 fields) → **1–3 requests → 1–3 seconds**.
  static Future<List<String>> translateBatch(
    List<String> texts,
    String targetLanguage,
  ) async {
    if (texts.isEmpty) return [];
    if (targetLanguage == 'English') return texts;
    final langCode = _langCodes[targetLanguage];
    if (langCode == null) return texts;

    // Step 1 – Deduplicate while preserving insertion order
    final uniqueTexts = <String>[];
    final textToUniqueIdx = <String, int>{};
    for (final t in texts) {
      if (!textToUniqueIdx.containsKey(t)) {
        textToUniqueIdx[t] = uniqueTexts.length;
        uniqueTexts.add(t);
      }
    }

    // Step 2 – Group unique texts into URL-safe chunks
    final chunks = <List<int>>[]; // list of (unique index lists)
    var current = <int>[];
    var currentLen = 0;
    for (int i = 0; i < uniqueTexts.length; i++) {
      final addLen = uniqueTexts[i].length + _sep.length;
      if (currentLen + addLen > _maxCharsPerRequest && current.isNotEmpty) {
        chunks.add(current);
        current = [];
        currentLen = 0;
      }
      current.add(i);
      currentLen += addLen;
    }
    if (current.isNotEmpty) chunks.add(current);

    final backendLangCode = _backendLangCode(langCode);

    // Step 3 – Translate all chunks concurrently
    final uniqueResults = List<String>.from(uniqueTexts); // default = original

    await Future.wait(chunks.map((idxList) async {
      final joined = idxList.map((i) => uniqueTexts[i]).join(_sep);
      final cacheKey = '${_cacheVersion}_${joined}_$backendLangCode';

      String translatedJoined;
      if (_cache.containsKey(cacheKey)) {
        translatedJoined = _cache[cacheKey]!;
      } else {
        try {
          translatedJoined = await _translateWithBackend(joined, langCode);
          _cache[cacheKey] = translatedJoined;
        } catch (_) {
          await Future.wait(idxList.map((idx) async {
            try {
              uniqueResults[idx] =
                  await translate(uniqueTexts[idx], targetLanguage);
            } catch (_) {
              uniqueResults[idx] = uniqueTexts[idx];
            }
          }));
          return;
        }
      }

      // Step 4 – Split back using the synthetic separator.
      final parts = translatedJoined.split(RegExp(r'\n?¶+\n?'));
      if (parts.length == idxList.length) {
        for (int j = 0; j < idxList.length; j++) {
          final result = _normalizeTranslationResult(
            parts[j],
            targetLanguage,
          );
          uniqueResults[idxList[j]] =
              result.isEmpty ? uniqueTexts[idxList[j]] : result;
          // Cache individual translations for future single-translate() calls
          final singleKey =
              '${_cacheVersion}_${uniqueTexts[idxList[j]]}_$backendLangCode';
          _cache[singleKey] = uniqueResults[idxList[j]];
        }
      } else {
        // Separator was mangled → fall back to individual requests for this chunk
        await Future.wait(idxList.map((idx) async {
          uniqueResults[idx] =
              await translate(uniqueTexts[idx], targetLanguage);
        }));
      }
    }));

    // Step 5 – Reconstruct original-order list
    return texts.map((t) => uniqueResults[textToUniqueIdx[t]!]).toList();
  }

  /// Translate an entire resume
  static Future<ResumeModel> translateResume(
    ResumeModel resume,
    String targetLanguage,
  ) async {
    if (targetLanguage == 'English' ||
        _staticLocalizationOnlyLanguages.contains(targetLanguage)) {
      return resume;
    }

    try {
      // Collect all texts to translate
      final textsToTranslate = <String>[];

      void addText(String text) {
        if (text.isEmpty) return;
        textsToTranslate.add(text);
      }

      // Personal info - only jobTitle
      if (resume.personalInfo.jobTitle?.isNotEmpty ?? false) {
        addText(resume.personalInfo.jobTitle!);
      }
      if (_shouldTranslateLocationLikeText(resume.personalInfo.address)) {
        addText(resume.personalInfo.address);
      }

      // Objective
      if (resume.objective?.isNotEmpty ?? false) {
        addText(resume.objective!);
      }

      // Experience
      for (final exp in resume.experience) {
        addText(exp.position);
        if (_isGenericPlaceholderText(exp.company)) {
          addText(exp.company);
        }
        if (_shouldTranslateLocationLikeText(exp.location)) {
          addText(exp.location!);
        }
        if (exp.description.isNotEmpty) addText(exp.description);
        for (final achievement in exp.achievements) {
          addText(achievement);
        }
      }

      // Education
      for (final edu in resume.education) {
        if (_isGenericPlaceholderText(edu.institution)) {
          addText(edu.institution);
        }
        addText(edu.degree);
        addText(edu.fieldOfStudy);
        if (_shouldTranslateLocationLikeText(edu.location)) {
          addText(edu.location!);
        }
        if (edu.grade?.isNotEmpty ?? false) {
          addText(edu.grade!);
        }
        if (edu.description?.isNotEmpty ?? false) addText(edu.description!);
      }

      // Projects
      for (final proj in resume.projects) {
        if (proj.title.trim().isNotEmpty) {
          addText(proj.title);
        }
        if (proj.description.isNotEmpty) {
          addText(proj.description);
        }
        for (final technology in proj.technologies) {
          if (_shouldTranslateSkillLabel(technology)) {
            addText(technology);
          }
        }
      }

      // Certifications
      for (final cert in resume.certifications) {
        if (cert.name.trim().isNotEmpty) {
          addText(cert.name);
        }
      }

      // Skills
      for (final skill in resume.skills) {
        if (_shouldTranslateSkillLabel(skill.name)) {
          addText(skill.name);
        }
      }

      // Languages
      for (final lang in resume.languages) {
        if (lang.name.trim().isNotEmpty) {
          addText(lang.name);
        }
      }

      // Hobbies
      for (final hobby in resume.hobbies) {
        addText(hobby);
      }

      // References
      for (final ref in resume.references) {
        if (ref.position.trim().isNotEmpty) {
          addText(ref.position);
        }
        if (ref.relationship?.trim().isNotEmpty ?? false) {
          addText(ref.relationship!);
        }
      }

      // Custom Sections
      for (final section in resume.customSections) {
        addText(section.title);
        for (final item in section.items) {
          if (item.title.trim().isNotEmpty) {
            addText(item.title);
          }
          if (item.description?.isNotEmpty ?? false) addText(item.description!);
        }
      }

      // Translate all at once
      final translated = await translateBatch(textsToTranslate, targetLanguage);

      // Rebuild resume with translated content
      int idx = 0;

      String nextValue(String original) {
        if (original.isEmpty) return original;
        return translated[idx++];
      }

      var newPersonalInfo = resume.personalInfo.copyWith(
        jobTitle: resume.personalInfo.jobTitle?.isNotEmpty ?? false
            ? nextValue(resume.personalInfo.jobTitle!)
            : null,
        address: _shouldTranslateLocationLikeText(resume.personalInfo.address)
            ? nextValue(resume.personalInfo.address)
            : _localizeWorkMode(
                resume.personalInfo.address,
                targetLanguage,
              ) ??
                resume.personalInfo.address,
      );

      var newObjective = resume.objective?.isNotEmpty ?? false
          ? nextValue(resume.objective!)
          : resume.objective;

      final newExperience = resume.experience.map((exp) {
        final position = nextValue(exp.position);
        final company = _isGenericPlaceholderText(exp.company)
          ? nextValue(exp.company)
          : exp.company;
        final location = _shouldTranslateLocationLikeText(exp.location)
          ? nextValue(exp.location!)
          : _localizeWorkMode(exp.location, targetLanguage);
        final description = exp.description.isNotEmpty
            ? nextValue(exp.description)
            : exp.description;
        final achievements = <String>[];
        for (final achievement in exp.achievements) {
          achievements.add(nextValue(achievement));
        }
        return exp.copyWith(
          company: company,
          position: position,
          location: location,
          description: description,
          achievements: achievements,
        );
      }).toList();

      final newEducation = resume.education.map((edu) {
        final institution = _isGenericPlaceholderText(edu.institution)
          ? nextValue(edu.institution)
          : edu.institution;
        final degree = _preferKnownLocalization(
          edu.degree,
          nextValue(edu.degree),
          targetLanguage,
        );
        final fieldOfStudy = _preferKnownLocalization(
          edu.fieldOfStudy,
          nextValue(edu.fieldOfStudy),
          targetLanguage,
        );
        final location = _shouldTranslateLocationLikeText(edu.location)
          ? nextValue(edu.location!)
          : _localizeWorkMode(edu.location, targetLanguage);
        final grade =
            edu.grade?.isNotEmpty ?? false ? nextValue(edu.grade!) : edu.grade;
        final description = edu.description?.isNotEmpty ?? false
            ? nextValue(edu.description!)
            : edu.description;
        return edu.copyWith(
          institution: institution,
          degree: degree,
          fieldOfStudy: fieldOfStudy,
          location: location,
          grade: grade,
          description: description,
        );
      }).toList();

      final newProjects = resume.projects.map((proj) {
        final title = proj.title.trim().isNotEmpty
            ? _preferKnownLocalization(
                proj.title,
                nextValue(proj.title),
                targetLanguage,
              )
            : proj.title;
        final description = proj.description.isNotEmpty
            ? nextValue(proj.description)
            : proj.description;
        final technologies = proj.technologies.map((technology) {
          if (_shouldTranslateSkillLabel(technology)) {
            return nextValue(technology);
          }
          return technology;
        }).toList(growable: false);
        return proj.copyWith(
          title: title,
          description: description,
          technologies: technologies,
        );
      }).toList();

      final newCertifications = resume.certifications.map((cert) {
        final name = cert.name.trim().isNotEmpty
            ? _preferKnownLocalization(
                cert.name,
                nextValue(cert.name),
                targetLanguage,
              )
            : cert.name;
        return cert.copyWith(name: name);
      }).toList();

      final newSkills = resume.skills.map((skill) {
        if (_shouldTranslateSkillLabel(skill.name)) {
          return skill.copyWith(name: nextValue(skill.name));
        }
        return skill;
      }).toList();

      final newLanguages = resume.languages.map((lang) {
        return lang.copyWith(
          name: lang.name.trim().isNotEmpty ? nextValue(lang.name) : lang.name,
          proficiency: _localizeLanguageProficiency(
            lang.proficiency,
            targetLanguage,
          ),
        );
      }).toList();

      final newHobbies =
          resume.hobbies.map((hobby) => nextValue(hobby)).toList();

      final newReferences = resume.references.map((ref) {
        final position = ref.position.trim().isNotEmpty
            ? nextValue(ref.position)
            : ref.position;
        final relationship = ref.relationship?.trim().isNotEmpty ?? false
            ? nextValue(ref.relationship!)
            : ref.relationship;
        return ref.copyWith(
          position: position,
          relationship: relationship,
        );
      }).toList();

      final newCustomSections = resume.customSections.map((section) {
        final title = nextValue(section.title);
        final items = section.items.map((item) {
          final itemTitle = item.title.trim().isNotEmpty
              ? nextValue(item.title)
              : item.title;
          final description = item.description?.isNotEmpty ?? false
              ? nextValue(item.description!)
              : item.description;
          return item.copyWith(
            title: itemTitle,
            description: description,
          );
        }).toList();
        return section.copyWith(
          title: title,
          items: items,
        );
      }).toList();

      return resume.copyWith(
        personalInfo: newPersonalInfo,
        objective: newObjective,
        experience: newExperience,
        education: newEducation,
        projects: newProjects,
        certifications: newCertifications,
        skills: newSkills,
        languages: newLanguages,
        hobbies: newHobbies,
        references: newReferences,
        customSections: newCustomSections,
      );
    } catch (_) {
      return resume; // Return original resume if translation fails
    }
  }

  /// Clear the translation cache
  static void clearCache() {
    _cache.clear();
  }
}
