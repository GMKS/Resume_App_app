import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/saved_resume.dart';

class ResumeStorageService {
  static const String _resumesKey = 'saved_resumes';

  static Future<List<SavedResume>> getResumes() async {
    final prefs = await SharedPreferences.getInstance();
    final resumesJson = prefs.getStringList(_resumesKey) ?? [];
    return resumesJson
        .map((json) => SavedResume.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveResume(
    SavedResume resume, {
    Function? showPremiumMessage,
    bool isPremiumUser = false,
    dynamic context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();

    if (resumes.length >= 5 && !isPremiumUser) {
      if (context != null && showPremiumMessage != null) {
        showPremiumMessage(context);
      }
      return;
    }

    final updatedResumes = [...resumes.where((r) => r.id != resume.id), resume];

    await prefs.setStringList(
      _resumesKey,
      updatedResumes.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<void> deleteResume(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();
    resumes.removeWhere((r) => r.id == id);
    await prefs.setStringList(
      _resumesKey,
      resumes.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
