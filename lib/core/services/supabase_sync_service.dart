import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/resume_model.dart';
import 'free_plan_service.dart';
import 'resume_json.dart';

/// Syncs resumes to/from Firebase Firestore using anonymous authentication.
///
/// **How cross-device sync works:**
/// By default, each device generates a random UUID stored in SharedPreferences.
/// That UUID is the Firestore document key, so two devices never share data unless
/// they have the same key.
///
/// To share data between mobile and Chrome (or any two devices), the user sets a
/// **Sync Code** — a short string they choose. Once set, that code becomes the
/// Firestore path key on that device, replacing the random UUID. Setting the SAME
/// code on two devices makes them read/write the same cloud data.
class SupabaseSyncService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'resumes';
  static const _prefKey = 'sync_device_id';
  static const _syncCodeKey = 'sync_account_code';

  // ── Sync Code (user-set, cross-device) ────────────────────────────────────

  /// Returns the current sync code, or null if the user hasn't set one yet.
  static Future<String?> getSyncCode() async {
    if (!FreePlanService.canUseCloudSync) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_syncCodeKey);
    return (code != null && code.trim().isNotEmpty) ? code.trim() : null;
  }

  /// Sets a user-chosen sync code. Both devices must use the same code to share
  /// data. Pass null to clear the code and revert to the device-only UUID.
  static Future<void> setSyncCode(String? code) async {
    if (!FreePlanService.canUseCloudSync) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.trim().isEmpty) {
      await prefs.remove(_syncCodeKey);
    } else {
      await prefs.setString(_syncCodeKey, code.trim().toLowerCase());
    }
  }

  // ── Device ID fallback ────────────────────────────────────────────────────

  /// Returns the persistent device UUID (created once per device/browser).
  /// Used only when no sync code is set.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefKey, id);
    }
    return id;
  }

  /// Returns the active Firestore document key:
  /// - The user-set sync code if one exists, OR
  /// - The per-device UUID otherwise.
  static Future<String> _activeKey() async {
    final code = await getSyncCode();
    if (code != null) return 'code_$code';
    return getDeviceId();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Ensures a Firebase session exists (anonymous sign-in on first use).
  /// Throws if Firebase was not initialized (bad config).
  static Future<void> ensureSignedIn() async {
    // Guard: ensure Firebase app is initialized before using Auth.
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase is not initialized. Check your firebase_options.dart config.');
    }
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Helper to get the Firestore items subcollection for the active key
  /// (sync code if set, otherwise per-device UUID).
  static Future<CollectionReference<Map<String, dynamic>>> _itemsRef() async {
    final key = await _activeKey();
    return _db
        .collection(_collection)
        .doc(key)
        .collection('items');
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  /// Fetches all resumes for this device from Firestore.
  static Future<List<ResumeModel>> loadAll() async {
    if (!FreePlanService.canUseCloudSync) {
      return [];
    }
    try {
      await ensureSignedIn();
      final ref = await _itemsRef();
      final snapshot = await ref.get();
      return snapshot.docs
          .map((doc) => ResumeJson.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Saves a single resume to Firestore.
  static Future<void> save(ResumeModel resume) async {
    if (!FreePlanService.canUseCloudSync) {
      return;
    }
    try {
      await ensureSignedIn();
      final ref = await _itemsRef();
      await ref.doc(resume.id).set(ResumeJson.toMap(resume));
    } catch (_) {
      // Silently fail — local save already succeeded.
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes a resume from Firestore.
  static Future<void> delete(String resumeId) async {
    if (!FreePlanService.canUseCloudSync) {
      return;
    }
    try {
      await ensureSignedIn();
      final ref = await _itemsRef();
      await ref.doc(resumeId).delete();
    } catch (_) {}
  }

  // ── Manual Backup (with error reporting) ──────────────────────────────────

  /// Backs up all provided resumes to Firestore using a batch write.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> manualBackupAll(List<ResumeModel> resumes) async {
    if (!FreePlanService.canUseCloudSync) {
      return FreePlanService.premiumCloudSyncMessage;
    }
    try {
      await ensureSignedIn();
      final ref = await _itemsRef();
      final batch = _db.batch();
      for (final resume in resumes) {
        batch.set(ref.doc(resume.id), ResumeJson.toMap(resume));
      }
      await batch.commit();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Manual Restore (with error reporting) ─────────────────────────────────

  /// Loads all resumes from Firestore for this device.
  /// Returns an empty list if nothing is found, or throws on a real error.
  static Future<List<ResumeModel>> manualRestoreAll() async {
    if (!FreePlanService.canUseCloudSync) {
      throw Exception(FreePlanService.premiumCloudSyncMessage);
    }
    await ensureSignedIn();
    final ref = await _itemsRef();
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => ResumeJson.fromMap(doc.data()))
        .toList();
  }

  /// Returns the active key (sync code if set, otherwise device UUID).
  static Future<String> get currentUserId async => _activeKey();
}
