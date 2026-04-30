import 'dart:convert';
import 'package:http/http.dart' as http;

/// LibreTranslate translation service for Flutter/Dart.
///
/// The managed hosted endpoint requires an API key. If no key is configured,
/// callers should fall back to a different backend.
class LibreTranslateService {
  static const String _baseUrl = 'https://libretranslate.com/translate';

  static String apiKey = '';

  static const Set<String> supportedTargetLanguages = {
    'ar',
    'az',
    'bg',
    'bn',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'eo',
    'es',
    'et',
    'eu',
    'fa',
    'fi',
    'fr',
    'ga',
    'gl',
    'he',
    'hi',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ky',
    'lt',
    'lv',
    'ms',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt-BR',
    'ro',
    'ru',
    'sk',
    'sl',
    'sq',
    'sr',
    'sv',
    'th',
    'tl',
    'tr',
    'uk',
    'ur',
    'vi',
    'zh-Hans',
    'zh-Hant',
  };

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  static bool supportsTargetLanguage(String targetLang) =>
      supportedTargetLanguages.contains(targetLang);

  /// Translates [text] from [sourceLang] to [targetLang].
  /// Example: sourceLang = 'en', targetLang = 'es' (Spanish)
  static Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (!hasApiKey) {
      throw Exception('LibreTranslate API key is not configured');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
        'source': sourceLang,
        'target': targetLang,
        'format': 'text',
        'api_key': apiKey,
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['translatedText'] as String;
    } else {
      throw Exception('LibreTranslate failed: ${response.statusCode}');
    }
  }
}
