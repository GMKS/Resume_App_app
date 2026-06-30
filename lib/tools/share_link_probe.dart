import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/models/resume_model.dart';
import '../core/services/storage_service.dart';
import '../features/portfolio/services/portfolio_profile_service.dart';
import '../features/portfolio/services/resume_share_service.dart';
import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await Hive.initFlutter();
    await StorageService.init();

    final resumes = StorageService.getAllResumes()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    print('SHARE_PROBE resumeCount=${resumes.length}');

    final resume = PortfolioProfileService.selectSourceResume(resumes);
    if (resume == null) {
      print('SHARE_PROBE error=no-resumes-found');
      exitCode = 2;
      exit(2);
    }

    print('SHARE_PROBE resumeId=${resume.id}');
    print('SHARE_PROBE resumeTitle=${resume.title}');
    print(
      'SHARE_PROBE resumeName=${resume.personalInfo.fullName.trim()}',
    );

    final record = await ResumeShareService.ensureShareRecord(resume);
    final shareUrl = record?.publicUrl.trim() ?? '';
    if (shareUrl.isEmpty) {
      print('SHARE_PROBE error=empty-share-url');
      exitCode = 3;
      exit(3);
    }

    print('SHARE_PROBE shareId=${record!.shareId}');
    print('SHARE_PROBE shareUrl=$shareUrl');
    exit(0);
  } catch (error, stackTrace) {
    print('SHARE_PROBE exception=$error');
    print('SHARE_PROBE stack=$stackTrace');
    exitCode = 1;
    exit(1);
  }
}
