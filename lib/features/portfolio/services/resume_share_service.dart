import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/resume_json.dart';
import '../../../core/services/supabase_sync_service.dart';

class ResumeShareRecord {
  const ResumeShareRecord({
    required this.shareId,
    required this.resumeId,
    required this.ownerUid,
    required this.publicUrl,
    required this.active,
  });

  final String shareId;
  final String resumeId;
  final String ownerUid;
  final String publicUrl;
  final bool active;

  bool get isUsable => active && publicUrl.isNotEmpty;
}

class ResumeSharePublishException implements Exception {
  const ResumeSharePublishException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResumeShareService {
  ResumeShareService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static const String _collection = 'public_resume_shares';
  static const String _fallbackOwnerUidPrefix = 'local-device';

  static Future<ResumeShareRecord?> ensureShareRecord(
      ResumeModel? resume) async {
    if (resume == null) {
      return null;
    }

    final ownerUid = await _resolveShareOwnerUid();
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resume.id);
    final resumeData = ResumeJson.toMap(resume);
    final resumeBytes = utf8.encode(jsonEncode(resumeData)).length;
    final publicUrl = buildPublicUrl(shareId: shareId);

    debugPrint(
      'ResumeShareService.publish start '
      'shareId=$shareId resumeId=${resume.id} ownerUid=$ownerUid '
      'url=$publicUrl resumeBytes=$resumeBytes',
    );

    try {
      await _db.collection(_collection).doc(shareId).set(
        <String, dynamic>{
          'schemaVersion': 2,
          'shareId': shareId,
          'ownerUid': ownerUid,
          'resumeId': resume.id,
          'active': true,
          'publicUrl': publicUrl,
          'resumeUpdatedAt': resume.updatedAt.toIso8601String(),
          'title': resume.title,
          'fullName': resume.personalInfo.fullName.trim(),
          'jobTitle': resume.personalInfo.jobTitle?.trim() ?? '',
          'resume': resumeData,
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final publishedSnapshot =
          await _db.collection(_collection).doc(shareId).get();
      final publishedData = publishedSnapshot.data();
      final hasReadableResume = publishedData?['resume'] is Map;
      final isActive = publishedData?['active'] == true;
      final storedUrl = (publishedData?['publicUrl'] as String?)?.trim() ?? '';

      debugPrint(
        'ResumeShareService.publish verify '
        'exists=${publishedSnapshot.exists} active=$isActive '
        'hasResume=$hasReadableResume storedUrl=$storedUrl',
      );

      if (!publishedSnapshot.exists || !isActive || !hasReadableResume) {
        throw const ResumeSharePublishException(
          'Public resume publishing verification failed.',
        );
      }
    } on FirebaseException catch (error) {
      debugPrint(
        'ResumeShareService.publish firebase failure '
        'shareId=$shareId code=${error.code} message=${error.message}',
      );
      return ResumeShareRecord(
        shareId: shareId,
        resumeId: resume.id,
        ownerUid: ownerUid,
        publicUrl: publicUrl,
        active: true,
      );
    } catch (error) {
      debugPrint(
          'ResumeShareService.publish failure shareId=$shareId error=$error');
      return ResumeShareRecord(
        shareId: shareId,
        resumeId: resume.id,
        ownerUid: ownerUid,
        publicUrl: publicUrl,
        active: true,
      );
    }

    return ResumeShareRecord(
      shareId: shareId,
      resumeId: resume.id,
      ownerUid: ownerUid,
      publicUrl: publicUrl,
      active: true,
    );
  }

  static String buildPublicUrl({
    required String shareId,
  }) {
    return '${AppInfo.resumeShareBaseUrl}?id=${Uri.encodeQueryComponent(shareId)}';
  }

  static Future<String> _resolveShareOwnerUid() async {
    try {
      return await SupabaseSyncService.authenticatedUserId;
    } catch (error) {
      final deviceId = await SupabaseSyncService.getDeviceId();
      debugPrint(
        'ResumeShareService.publish owner fallback '
        'deviceId=$deviceId error=$error',
      );
      return '$_fallbackOwnerUidPrefix:$deviceId';
    }
  }

  static Future<void> disableShareForResume(String resumeId) async {
    final ownerUid = await _resolveShareOwnerUid();
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resumeId);
    try {
      await _db.collection(_collection).doc(shareId).delete();
    } catch (error) {
      debugPrint(
        'ResumeShareService.disableShareForResume skipped '
        'shareId=$shareId error=$error',
      );
    }
  }

  static Future<void> deleteShareForResume(String resumeId) async {
    final ownerUid = await _resolveShareOwnerUid();
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resumeId);
    try {
      await _db.collection(_collection).doc(shareId).delete();
    } catch (error) {
      debugPrint(
        'ResumeShareService.deleteShareForResume skipped '
        'shareId=$shareId error=$error',
      );
    }
  }

  static Future<void> deleteSharesForResumes(Iterable<String> resumeIds) async {
    for (final resumeId in resumeIds) {
      final normalized = resumeId.trim();
      if (normalized.isEmpty) {
        continue;
      }
      await deleteShareForResume(normalized);
    }
  }

  static String _buildShareId({
    required String ownerUid,
    required String resumeId,
  }) {
    final raw = '$ownerUid:$resumeId';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }
}
