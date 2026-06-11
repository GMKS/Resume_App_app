import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_model.dart';
import '../models/subscription_model.dart';
import 'app_scope_service.dart';
import 'resume_version_service.dart';
import 'supabase_sync_service.dart';

class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(AppScopeService.prefKey(key));

  int? getInt(String key) => _prefs.getInt(AppScopeService.prefKey(key));

  bool? getBool(String key) => _prefs.getBool(AppScopeService.prefKey(key));

  double? getDouble(String key) => _prefs.getDouble(AppScopeService.prefKey(key));

  Future<bool> setString(String key, String value) {
    return _prefs.setString(AppScopeService.prefKey(key), value);
  }

  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(AppScopeService.prefKey(key), value);
  }

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(AppScopeService.prefKey(key), value);
  }

  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(AppScopeService.prefKey(key), value);
  }

  Future<bool> remove(String key) {
    return _prefs.remove(AppScopeService.prefKey(key));
  }

  bool containsKey(String key) {
    return _prefs.containsKey(AppScopeService.prefKey(key));
  }

  Set<String> getKeys() {
    final prefix = AppScopeService.prefPrefix;
    return _prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toSet();
  }

  Future<bool> clear() async {
    final scopedKeys = _prefs
        .getKeys()
        .where((key) => key.startsWith(AppScopeService.prefPrefix))
        .toList(growable: false);

    var success = true;
    for (final key in scopedKeys) {
      success = await _prefs.remove(key) && success;
    }
    return success;
  }
}

class StorageService {
  static late Box<ResumeModel> _resumeBox;
  static late SharedPreferences _rawPrefs;
  static late AppPreferences _prefs;

  static String get resumeBoxName => AppScopeService.boxName('resumes');

  static Future<void> init() async {
    AppScopeService.initialize();

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
    _rawPrefs = await SharedPreferences.getInstance();
    _prefs = AppPreferences(_rawPrefs);
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
    // Removed implicit cloud uploads on local save.
  }

  static ResumeModel? getResume(String id) {
    return _resumeBox.get(id);
  }

  static List<ResumeModel> getAllResumes() {
    return _resumeBox.values.toList();
  }

  static bool hasResumeTitle(
    String title, {
    String? excludingId,
  }) {
    final normalizedTitle = title.trim().toLowerCase();
    if (normalizedTitle.isEmpty) {
      return false;
    }

    return _resumeBox.values.any(
      (resume) => resume.id != excludingId &&
          resume.title.trim().toLowerCase() == normalizedTitle,
    );
  }

  static bool isPremiumUser() {
    final planName = _prefs.getString('subscription_plan');
    final expiryStr = _prefs.getString('subscription_expiry');
    final providerName = _prefs.getString('subscription_provider');

    if (providerName == BillingProvider.googlePlay.name) {
      return planName != null &&
          planName != SubscriptionPlan.free.name &&
          (_prefs.getBool('subscription_active') ?? true);
    }

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
    ResumeVersionService.deleteAllVersions(id);
  }

  static Future<void> deleteAllResumes() async {
    await _resumeBox.clear();
  }

  // Preferences operations
  static SharedPreferences get rawPrefs => _rawPrefs;

  static AppPreferences get prefs => _prefs;

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
