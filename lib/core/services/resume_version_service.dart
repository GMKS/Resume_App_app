import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/resume_model.dart';
import 'resume_json.dart';

/// Service for managing resume version history in Firestore.
/// Automatically saves previous versions before AI tailoring.
class ResumeVersionService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'resume_versions';
  static const _prefKey = 'sync_device_id';
  static const _syncCodeKey = 'sync_account_code';
  static const _maxVersionsPerResume = 10;

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

  // ── Key Management (reuses sync code logic) ──

  static Future<String?> _getSyncCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_syncCodeKey);
    return (code != null && code.trim().isNotEmpty) ? code.trim() : null;
  }

  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefKey, id);
    }
    return id;
  }

  static Future<String> _activeKey() async {
    final code = await _getSyncCode();
    if (code != null) return 'code_$code';
    return _getDeviceId();
  }

  // ── Auth ──

  static Future<void> _ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  static Future<CollectionReference<Map<String, dynamic>>> _versionsRef(
    String resumeId,
  ) async {
    final key = await _activeKey();
    return _db
        .collection(_collection)
        .doc(key)
        .collection('resumes')
        .doc(resumeId)
        .collection('versions');
  }

  // ── Save Version ──

  /// Saves a snapshot of the resume before making AI-powered changes.
  /// Returns the version ID if successful.
  static Future<String?> saveVersion({
    required ResumeModel resume,
    required String changeType,
    String? description,
  }) async {
    try {
      await _ensureSignedIn();
      final ref = await _versionsRef(resume.id);
      final versionId = const Uuid().v4();

      final versionData = {
        'versionId': versionId,
        'resumeId': resume.id,
        'resumeData': ResumeJson.toMap(resume),
        'changeType': changeType, // 'ai_tailor', 'ai_generate', 'manual'
        'description': description ?? 'Auto-saved before AI changes',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.doc(versionId).set(versionData);

      // Cleanup old versions (keep only last N)
      await _cleanupOldVersions(resume.id);

      return versionId;
    } catch (e) {
      // Silently fail - don't block the main operation
      return null;
    }
  }

  /// Removes old versions beyond the limit
  static Future<void> _cleanupOldVersions(String resumeId) async {
    try {
      final ref = await _versionsRef(resumeId);
      final snapshot = await ref
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.length > _maxVersionsPerResume) {
        final toDelete = snapshot.docs.sublist(_maxVersionsPerResume);
        for (final doc in toDelete) {
          await doc.reference.delete();
        }
      }
    } catch (_) {}
  }

  // ── Load Versions ──

  /// Gets all saved versions for a resume, ordered by most recent first.
  static Future<List<ResumeVersion>> getVersions(String resumeId) async {
    try {
      await _ensureSignedIn();
      final ref = await _versionsRef(resumeId);
      final snapshot = await ref
          .orderBy('createdAt', descending: true)
          .limit(_maxVersionsPerResume)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ResumeVersion(
          versionId: data['versionId'] as String,
          resumeId: data['resumeId'] as String,
          resume: ResumeJson.fromMap(data['resumeData'] as Map<String, dynamic>),
          changeType: data['changeType'] as String? ?? 'unknown',
          description: data['description'] as String?,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets a specific version by ID
  static Future<ResumeVersion?> getVersion({
    required String resumeId,
    required String versionId,
  }) async {
    try {
      await _ensureSignedIn();
      final ref = await _versionsRef(resumeId);
      final doc = await ref.doc(versionId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return ResumeVersion(
        versionId: data['versionId'] as String,
        resumeId: data['resumeId'] as String,
        resume: ResumeJson.fromMap(data['resumeData'] as Map<String, dynamic>),
        changeType: data['changeType'] as String? ?? 'unknown',
        description: data['description'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Restore Version ──

  /// Returns the ResumeModel from a specific version for restoration
  static Future<ResumeModel?> restoreVersion({
    required String resumeId,
    required String versionId,
  }) async {
    final version = await getVersion(resumeId: resumeId, versionId: versionId);
    return version?.resume;
  }

  // ── Delete Versions ──

  /// Deletes all versions for a resume (call when deleting the resume)
  static Future<void> deleteAllVersions(String resumeId) async {
    try {
      await _ensureSignedIn();
      final ref = await _versionsRef(resumeId);
      final snapshot = await ref.get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  static Future<void> deleteAllCloudData() async {
    try {
      await _ensureSignedIn();
      final key = await _activeKey();
      final rootDoc = _db.collection(_collection).doc(key);
      final resumeDocs = await rootDoc.collection('resumes').get();

      for (final resumeDoc in resumeDocs.docs) {
        final versions = await resumeDoc.reference.collection('versions').get();
        await _deleteDocumentsInBatches(versions.docs);
        await resumeDoc.reference.delete();
      }

      await rootDoc.delete();
    } catch (_) {}
  }
}

/// Model representing a saved resume version
class ResumeVersion {
  final String versionId;
  final String resumeId;
  final ResumeModel resume;
  final String changeType;
  final String? description;
  final DateTime createdAt;

  ResumeVersion({
    required this.versionId,
    required this.resumeId,
    required this.resume,
    required this.changeType,
    this.description,
    required this.createdAt,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get changeTypeLabel {
    switch (changeType) {
      case 'ai_tailor':
        return 'AI Tailored';
      case 'ai_generate':
        return 'AI Generated';
      case 'manual':
        return 'Manual Edit';
      default:
        return 'Saved';
    }
  }
}
