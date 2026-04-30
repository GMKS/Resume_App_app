import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_model.dart';
import 'supabase_sync_service.dart';

class StorageService {
  static late Box<ResumeModel> _resumeBox;
  static late SharedPreferences _prefs;

  static const String resumeBoxName = 'resumes';

  static Future<void> init() async {
    // Guard every registration so hot-restarts in debug mode don't throw
    // "Adapter already registered" errors that prevent the box from opening.
    if (!Hive.isAdapterRegistered(0))  Hive.registerAdapter(ResumeModelAdapter());
    if (!Hive.isAdapterRegistered(1))  Hive.registerAdapter(PersonalInfoAdapter());
    if (!Hive.isAdapterRegistered(2))  Hive.registerAdapter(EducationAdapter());
    if (!Hive.isAdapterRegistered(3))  Hive.registerAdapter(ExperienceAdapter());
    if (!Hive.isAdapterRegistered(4))  Hive.registerAdapter(SkillAdapter());
    if (!Hive.isAdapterRegistered(5))  Hive.registerAdapter(ProjectAdapter());
    if (!Hive.isAdapterRegistered(6))  Hive.registerAdapter(CertificationAdapter());
    if (!Hive.isAdapterRegistered(7))  Hive.registerAdapter(LanguageAdapter());
    if (!Hive.isAdapterRegistered(8))  Hive.registerAdapter(ReferenceAdapter());
    if (!Hive.isAdapterRegistered(9))  Hive.registerAdapter(CustomSectionAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(CustomSectionItemAdapter());

    // Open boxes — if the box is already open (hot-restart), reuse it
    _resumeBox = Hive.isBoxOpen(resumeBoxName)
        ? Hive.box<ResumeModel>(resumeBoxName)
        : await Hive.openBox<ResumeModel>(resumeBoxName);

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // Resume operations
  static Box<ResumeModel> get resumeBox => _resumeBox;

  static Future<void> saveResume(ResumeModel resume) async {
    final isNewResume = !_resumeBox.containsKey(resume.id);
    if (isNewResume && !canCreateAnotherResume()) {
      throw StateError(
        'Your starter access includes 1 resume. Upgrade to create and manage multiple resumes.',
      );
    }
    await _resumeBox.put(resume.id, resume);
    // Also sync to Supabase (cloud backup).
    SupabaseSyncService.save(resume);
  }

  static ResumeModel? getResume(String id) {
    return _resumeBox.get(id);
  }

  static List<ResumeModel> getAllResumes() {
    return _resumeBox.values.toList();
  }

  static bool isPremiumUser() {
    final planName = _prefs.getString('subscription_plan');
    final expiryStr = _prefs.getString('subscription_expiry');

    if (planName == null || planName == 'free' || expiryStr == null) {
      return false;
    }

    final expiryMillis = int.tryParse(expiryStr);
    if (expiryMillis == null) {
      return false;
    }

    return DateTime.fromMillisecondsSinceEpoch(expiryMillis)
        .isAfter(DateTime.now());
  }

  static bool canCreateAnotherResume() {
    return isPremiumUser() || _resumeBox.length < 1;
  }

  static Future<void> deleteResume(String id) async {
    await _resumeBox.delete(id);
    // Also delete from Supabase.
    SupabaseSyncService.delete(id);
  }

  static Future<void> deleteAllResumes() async {
    await _resumeBox.clear();
  }

  // Preferences operations
  static SharedPreferences get prefs => _prefs;

  static Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool('onboarding_complete', value);
  }

  static bool getOnboardingComplete() {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  static Future<void> setThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  static String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'system';
  }
}
