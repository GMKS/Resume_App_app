import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'resume_version_service.dart';
import 'storage_service.dart';
import 'supabase_sync_service.dart';

class DataDeletionService {
  const DataDeletionService._();

  static Future<void> deleteUserData({bool deleteCloudData = true}) async {
    final wasPremium = StorageService.isPremiumUser();
    debugPrint(
      'DataDeletionService.deleteUserData: deleteCloudData=$deleteCloudData '
      'premiumBefore=$wasPremium',
    );

    if (deleteCloudData) {
      await Future.wait([
        SupabaseSyncService.deleteAllCloudData(),
        ResumeVersionService.deleteAllCloudData(),
      ]);
    }

    await StorageService.clearLocalWorkspaceData();

    debugPrint(
      'DataDeletionService.deleteUserData: premiumAfter=${StorageService.isPremiumUser()} '
      'premiumCachePreserved=${StorageService.isPremiumUser() == wasPremium}',
    );

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}