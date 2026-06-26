import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static Future<void> setCollectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_collection_enabled', enabled);
  }

  static Future<void> setSharingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_sharing_enabled', enabled);
  }
}
