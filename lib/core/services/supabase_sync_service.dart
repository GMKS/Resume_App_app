import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/resume_model.dart';
import 'free_plan_service.dart';
import 'resume_json.dart';

class CloudIdentityStatus {
  const CloudIdentityStatus({
    required this.uid,
    required this.displayLabel,
    required this.isAnonymous,
    required this.deviceId,
    required this.legacySharedSyncDetected,
  });

  final String uid;
  final String displayLabel;
  final bool isAnonymous;
  final String deviceId;
  final bool legacySharedSyncDetected;

  bool get hasSharedCloudAccess => uid.isNotEmpty && !isAnonymous;
}

/// Syncs user data to Firestore using the authenticated Firebase user identity.
class SupabaseSyncService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static const _usersCollection = 'users';
  static const _resumeCollection = 'resumes';
  static const _settingsCollection = 'settings';
  static const _backupsCollection = 'backups';
  static const _prefKey = 'sync_device_id';
  static const _syncCodeKey = 'sync_account_code';

  static Future<void> _deleteDocumentsInBatches(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    const batchSize = 400;
    for (var start = 0; start < docs.length; start += batchSize) {
      final batch = _db.batch();
      for (final doc in docs.skip(start).take(batchSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  static Future<String?> getSyncCode() async {
    return null;
  }

  static Future<void> setSyncCode(String? code) async {
    await clearLegacySharedSyncCode();
  }

  static Future<bool> hasLegacySharedSyncCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_syncCodeKey)?.trim() ?? '';
    return code.isNotEmpty;
  }

  static Future<void> clearLegacySharedSyncCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncCodeKey);
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefKey, id);
    }
    return id;
  }

  static Future<CloudIdentityStatus> getCloudIdentityStatus() async {
    await ensureSignedIn();
    final user = _auth.currentUser!;
    final legacySharedSyncDetected = await hasLegacySharedSyncCode();
    final deviceId = await getDeviceId();

    final displayLabel = () {
      final email = user.email?.trim() ?? '';
      if (email.isNotEmpty) {
        return email;
      }

      final phone = user.phoneNumber?.trim() ?? '';
      if (phone.isNotEmpty) {
        return phone;
      }

      final name = user.displayName?.trim() ?? '';
      if (name.isNotEmpty) {
        return name;
      }

      if (user.isAnonymous) {
        return 'Guest workspace';
      }

      return user.uid;
    }();

    return CloudIdentityStatus(
      uid: user.uid,
      displayLabel: displayLabel,
      isAnonymous: user.isAnonymous,
      deviceId: deviceId,
      legacySharedSyncDetected: legacySharedSyncDetected,
    );
  }

  static Future<void> ensureSignedIn() async {
    if (Firebase.apps.isEmpty) {
      throw Exception(
          'Firebase is not initialized. Check your firebase_options.dart config.');
    }
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  static Future<String> _cloudUserId() async {
    await ensureSignedIn();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      throw Exception(
          'Cloud sync is unavailable because no authenticated workspace is active.');
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection(_usersCollection).doc(uid);
  }

  static Future<CollectionReference<Map<String, dynamic>>> _resumesRef() async {
    final uid = await _cloudUserId();
    return _userDoc(uid).collection(_resumeCollection);
  }

  static Future<DocumentReference<Map<String, dynamic>>> _settingsDoc(
    String name,
  ) async {
    final uid = await _cloudUserId();
    return _userDoc(uid).collection(_settingsCollection).doc(name);
  }

  static Future<DocumentReference<Map<String, dynamic>>> _backupDoc(
    String name,
  ) async {
    final uid = await _cloudUserId();
    return _userDoc(uid).collection(_backupsCollection).doc(name);
  }

  static Future<void> _touchWorkspace({
    bool markBackup = false,
    bool markRestore = false,
  }) async {
    final status = await getCloudIdentityStatus();
    await _userDoc(status.uid).set(
      <String, dynamic>{
        'uid': status.uid,
        'isAnonymous': status.isAnonymous,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await (await _settingsDoc('sync_state')).set(
      <String, dynamic>{
        'workspaceLabel': status.displayLabel,
        'isAnonymous': status.isAnonymous,
        if (markBackup) 'lastBackupAt': FieldValue.serverTimestamp(),
        if (markRestore) 'lastRestoreAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<List<ResumeModel>> loadAll() async {
    if (!FreePlanService.canUseCloudSync) {
      return [];
    }
    try {
      await ensureSignedIn();
      final ref = await _resumesRef();
      final snapshot = await ref.get();
      return snapshot.docs
          .map((doc) => ResumeJson.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> save(ResumeModel resume) async {
    if (!FreePlanService.canUseCloudSync) {
      return;
    }
    try {
      await ensureSignedIn();
      final ref = await _resumesRef();
      await ref.doc(resume.id).set(ResumeJson.toMap(resume));
      await _touchWorkspace(markBackup: true);
    } catch (_) {}
  }

  static Future<void> delete(String resumeId) async {
    if (!FreePlanService.canUseCloudSync) {
      return;
    }
    try {
      await ensureSignedIn();
      final ref = await _resumesRef();
      await ref.doc(resumeId).delete();
    } catch (_) {}
  }

  static Future<String?> manualBackupAll(List<ResumeModel> resumes) async {
    if (!FreePlanService.canUseCloudSync) {
      return FreePlanService.premiumCloudSyncMessage;
    }
    try {
      await ensureSignedIn();
      final ref = await _resumesRef();
      final batch = _db.batch();
      for (final resume in resumes) {
        batch.set(ref.doc(resume.id), ResumeJson.toMap(resume));
      }
      await batch.commit();
      await _touchWorkspace(markBackup: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<ResumeModel>> manualRestoreAll() async {
    if (!FreePlanService.canUseCloudSync) {
      throw Exception(FreePlanService.premiumCloudSyncMessage);
    }
    await ensureSignedIn();
    final ref = await _resumesRef();
    final snapshot = await ref.get();
    await _touchWorkspace(markRestore: true);
    return snapshot.docs.map((doc) => ResumeJson.fromMap(doc.data())).toList();
  }

  static Future<String?> manualBackupJsonList({
    required String collection,
    required String field,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!FreePlanService.canUseCloudSync) {
      return FreePlanService.premiumCloudSyncMessage;
    }
    try {
      await ensureSignedIn();
      final doc = await _backupDoc(collection);
      await doc.set(<String, dynamic>{
        field: items,
        'ownerUid': _auth.currentUser?.uid ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _touchWorkspace(markBackup: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<Map<String, dynamic>>> manualRestoreJsonList({
    required String collection,
    required String field,
  }) async {
    if (!FreePlanService.canUseCloudSync) {
      throw Exception(FreePlanService.premiumCloudSyncMessage);
    }
    await ensureSignedIn();
    final doc = await _backupDoc(collection);
    final snapshot = await doc.get();
    final data = snapshot.data();
    await _touchWorkspace(markRestore: true);
    final rawItems = data?[field];
    if (rawItems is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  static Future<String> get currentUserId async {
    final currentUser = _auth.currentUser;
    final uid = currentUser?.uid.trim() ?? '';
    if (uid.isNotEmpty) {
      return uid;
    }
    return getDeviceId();
  }

  static Future<void> deleteAllCloudData() async {
    try {
      await ensureSignedIn();
      final uid = await _cloudUserId();
      final userDoc = _userDoc(uid);

      final resumeItems = await userDoc.collection(_resumeCollection).get();
      await _deleteDocumentsInBatches(resumeItems.docs);

      final backupDocs = await userDoc.collection(_backupsCollection).get();
      await _deleteDocumentsInBatches(backupDocs.docs);

      final settingsDocs = await userDoc.collection(_settingsCollection).get();
      await _deleteDocumentsInBatches(settingsDocs.docs);

      await userDoc.delete();
    } catch (_) {}
  }
}
