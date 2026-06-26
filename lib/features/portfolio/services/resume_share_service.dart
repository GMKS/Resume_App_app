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

class ResumeShareService {
  ResumeShareService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'public_resume_shares';

  static Future<ResumeShareRecord?> ensureShareRecord(ResumeModel? resume) async {
    if (resume == null) {
      return null;
    }

    try {
      await SupabaseSyncService.ensureSignedIn();
    } catch (error) {
      debugPrint('ResumeShareService.ensureShareRecord sign-in fallback: $error');
    }

    final ownerUid = await SupabaseSyncService.currentUserId;
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resume.id);
    final publicUrl = buildPublicUrl(shareId: shareId, resume: resume);
    final resumePayload = base64UrlEncode(
      utf8.encode(jsonEncode(ResumeJson.toMap(resume))),
    );

    try {
      await _db.collection(_collection).doc(shareId).set(
        <String, dynamic>{
          'shareId': shareId,
          'ownerUid': ownerUid,
          'resumeId': resume.id,
          'active': true,
          'publicUrl': publicUrl,
          'resumeUpdatedAt': resume.updatedAt.toIso8601String(),
          'title': resume.title,
          'fullName': resume.personalInfo.fullName.trim(),
          'jobTitle': resume.personalInfo.jobTitle?.trim() ?? '',
          'resume': ResumeJson.toMap(resume),
          'resumePayload': resumePayload,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('ResumeShareService.ensureShareRecord sync warning: $error');
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
    required ResumeModel resume,
  }) {
    return '${AppInfo.resumeShareBaseUrl}?id=${Uri.encodeQueryComponent(shareId)}';
  }

  static Future<void> disableShareForResume(String resumeId) async {
    final ownerUid = await SupabaseSyncService.currentUserId;
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resumeId);
    final doc = _db.collection(_collection).doc(shareId);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      return;
    }

    await doc.set(
      <String, dynamic>{
        'active': false,
        'disabledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> deleteShareForResume(String resumeId) async {
    final ownerUid = await SupabaseSyncService.currentUserId;
    final shareId = _buildShareId(ownerUid: ownerUid, resumeId: resumeId);
    await _db.collection(_collection).doc(shareId).delete();
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