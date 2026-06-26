import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_info.dart';
import 'app_version_service.dart';
import 'supabase_sync_service.dart';
import 'user_session_service.dart';

class BugReportSubmission {
  const BugReportSubmission({
    required this.category,
    required this.screenName,
    required this.issueDescription,
    required this.viewport,
    this.screenshots = const <String>[],
  });

  final String category;
  final String screenName;
  final String issueDescription;
  final Map<String, dynamic> viewport;
  final List<String> screenshots;
}

class BugReportResult {
  const BugReportResult({
    required this.success,
    required this.message,
    this.reportId,
  });

  final bool success;
  final String message;
  final String? reportId;
}

class BugReportService {
  BugReportService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'support_bug_reports';

  static Future<BugReportResult> submit(BugReportSubmission submission) async {
    final trimmedDescription = submission.issueDescription.trim();
    if (trimmedDescription.isEmpty) {
      return const BugReportResult(
        success: false,
        message: 'Please describe the issue before submitting.',
      );
    }

    try {
      await SupabaseSyncService.ensureSignedIn();

      final prefs = await SharedPreferences.getInstance();
      final version = await AppVersionService.load();
      final user = _auth.currentUser;
      final identity = await SupabaseSyncService.getCloudIdentityStatus();

      final rawDisplayName = prefs.getString('display_name')?.trim() ?? '';
      final rawContact = UserSessionService.readStoredContact(prefs).trim();
      final authProvider = prefs.getString('auth_provider')?.trim() ?? '';
      final storedPhotoUrl = prefs.getString('photo_url')?.trim() ?? '';

      final report = <String, dynamic>{
        'type': submission.category,
        'status': 'new',
        'deliveryChannel': 'firestore',
        'destination': 'support_bug_reports',
        'screenName': submission.screenName,
        'issueDescription': trimmedDescription,
        'screenshots': submission.screenshots,
        'screenshotCount': submission.screenshots.length,
        'app': <String, dynamic>{
          'name': AppInfo.appName,
          'version': version.version,
          'buildNumber': version.buildNumber,
        },
        'user': <String, dynamic>{
          'uid': user?.uid ?? '',
          'isAnonymous': user?.isAnonymous ?? true,
          'displayName': rawDisplayName.isNotEmpty
              ? rawDisplayName
              : (user?.displayName ?? ''),
          'email': user?.email ?? '',
          'contact': rawContact,
          'phoneNumber': user?.phoneNumber ?? '',
          'authProvider': authProvider,
          'photoUrl': storedPhotoUrl.isNotEmpty
              ? storedPhotoUrl
              : (user?.photoURL ?? ''),
        },
        'syncContext': <String, dynamic>{
          'cloudUserId': identity.uid,
          'workspaceLabel': identity.displayLabel,
          'isAnonymous': identity.isAnonymous,
          'legacySharedSyncDetected': identity.legacySharedSyncDetected,
          'deviceId': identity.deviceId,
        },
        'device': <String, dynamic>{
          'platform': _platformLabel(),
          'isWeb': kIsWeb,
          'viewport': submission.viewport,
        },
        'timestamps': <String, dynamic>{
          'clientIso': DateTime.now().toUtc().toIso8601String(),
          'server': FieldValue.serverTimestamp(),
        },
      };

      final doc = await _db.collection(_collection).add(report);
      await doc.update(<String, dynamic>{'reportId': doc.id});

      return BugReportResult(
        success: true,
        message: 'Bug report submitted. Thank you!',
        reportId: doc.id,
      );
    } on FirebaseException catch (error) {
      return BugReportResult(
        success: false,
        message: _firebaseErrorMessage(error),
      );
    } catch (_) {
      return const BugReportResult(
        success: false,
        message: 'Could not submit the bug report right now. Please try again.',
      );
    }
  }

  static String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static String _firebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
        return 'Support is temporarily unavailable. Please check your connection and try again.';
      case 'permission-denied':
        return 'This report could not be submitted due to a permissions issue.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Could not submit the bug report right now. Please try again.';
    }
  }
}
