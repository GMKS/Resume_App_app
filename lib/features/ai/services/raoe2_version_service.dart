import '../../../core/services/storage_service.dart';

/// Service to store and retrieve optimized resume versions for RAOE 2
class RAOE2VersionService {
  static const _keyPrefix = 'raoe2_optimized_';

  /// Save an optimized resume version for a given resumeId
  static Future<void> saveOptimizedVersion({
    required String resumeId,
    required String optimizedText,
  }) async {
    final prefs = StorageService.prefs;
    await prefs.setString('$_keyPrefix$resumeId', optimizedText);
  }

  /// Retrieve an optimized resume version for a given resumeId
  static Future<String?> getOptimizedVersion(String resumeId) async {
    final prefs = StorageService.prefs;
    return prefs.getString('$_keyPrefix$resumeId');
  }
}
