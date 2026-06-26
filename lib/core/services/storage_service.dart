import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_model.dart';
import '../models/subscription_model.dart';
import 'resume_version_service.dart';
import 'supabase_sync_service.dart';
import '../../features/portfolio/services/resume_share_service.dart';

class StorageService {
  static late Box<ResumeModel> _resumeBox;
  static late SharedPreferences _prefs;

  static const String resumeBoxName = 'resumes';
  static const String _workspaceOwnerKey = 'local_workspace_owner_uid';
  static const List<String> _workspacePrefPrefixes = <String>[
    'job_tracker_entries_',
    'skill_analyzer_entries_',
  ];
  static const List<String> _workspaceScopedPrefs = <String>[
    'sync_last_backup_at',
    'sync_last_restore_at',
    'sync_device_id',
    'sync_account_code',
  ];

  static Future<void> init() async {
    // Guard every registration so hot-restarts in debug mode don't throw
    // "Adapter already registered" errors that prevent the box from opening.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ResumeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PersonalInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(EducationAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ExperienceAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SkillAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(CertificationAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(LanguageAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(ReferenceAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(CustomSectionAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CustomSectionItemAdapter());
    }

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
    unawaited(SupabaseSyncService.save(resume));
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
    final providerName = _prefs.getString('subscription_provider');
    final verified = _prefs.getBool('subscription_verified') ?? false;

    if (providerName == BillingProvider.googlePlay.name) {
      return planName != null &&
          planName != SubscriptionPlan.free.name &&
          (_prefs.getBool('subscription_active') ?? true);
    }

    if (!verified ||
        planName == null ||
        planName == 'free' ||
        expiryStr == null) {
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
    await SupabaseSyncService.delete(id);
    await ResumeVersionService.deleteAllVersions(id);
    unawaited(ResumeShareService.deleteShareForResume(id));
  }

  static Future<void> deleteAllResumes() async {
    final resumeIds = _resumeBox.keys
        .map((key) => key.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    await _resumeBox.clear();
    unawaited(ResumeShareService.deleteSharesForResumes(resumeIds));
  }

  static Future<void> ensureWorkspaceOwner(String ownerId) async {
    final normalized = ownerId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final currentOwner = _prefs.getString(_workspaceOwnerKey)?.trim() ?? '';
    if (currentOwner.isEmpty) {
      await _prefs.setString(_workspaceOwnerKey, normalized);
      return;
    }

    if (currentOwner == normalized) {
      return;
    }

    await clearLocalWorkspaceData();
    await _prefs.setString(_workspaceOwnerKey, normalized);
  }

  static Future<void> synchronizeWorkspaceOwnerWithAuthenticatedUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return;
    }

    await ensureWorkspaceOwner(uid);
  }

  static Future<void> clearWorkspaceOwner() async {
    await _prefs.remove(_workspaceOwnerKey);
  }

  static Future<void> clearLocalWorkspaceData() async {
    await _resumeBox.clear();

    final keys = _prefs.getKeys().where((key) {
      if (_workspaceScopedPrefs.contains(key)) {
        return true;
      }

      return _workspacePrefPrefixes.any(key.startsWith);
    }).toList(growable: false);

    for (final key in keys) {
      await _prefs.remove(key);
    }
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
