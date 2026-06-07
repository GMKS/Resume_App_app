import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config_service.dart';

class AiApiKeyStorageService {
  AiApiKeyStorageService._();

  static const String _storageKey = 'gemini_api_key';
  static const String _managedConfigKey = 'GROQ_API_KEY';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> read() async {
    final managedValue = AppConfigService.read(_managedConfigKey);
    if (managedValue.isNotEmpty) {
      return managedValue;
    }

    final storedValue = (await _storage.read(key: _storageKey))?.trim() ?? '';
    if (storedValue.isNotEmpty) {
      return storedValue;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(_storageKey)?.trim() ?? '';
    if (legacyValue.isEmpty) {
      return '';
    }

    await _storage.write(key: _storageKey, value: legacyValue);
    await prefs.remove(_storageKey);
    return legacyValue;
  }

  static Future<void> save(String apiKey) async {
    final normalized = apiKey.trim();
    if (normalized.isEmpty) {
      await clear();
      return;
    }

    await _storage.write(key: _storageKey, value: normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _storageKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
