import 'package:shared_preferences/shared_preferences.dart';

/// Service to store and retrieve optimized resume versions for RAOE 2
class RAOE2VersionService {
  static const _keyPrefix = 'raoe2_optimized_';

  /// Save an optimized resume version for a given resumeId
  static Future<void> saveOptimizedVersion({
    required String resumeId,
    required String optimizedText,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$resumeId', optimizedText);
  }

  /// Retrieve an optimized resume version for a given resumeId
  static Future<String?> getOptimizedVersion(String resumeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$resumeId');
  }
}
