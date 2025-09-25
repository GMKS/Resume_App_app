import 'package:flutter/foundation.dart';
import '../models/saved_resume.dart';
import 'cloud_resume_service.dart';
import 'premium_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeStorageService {
  ResumeStorageService._();
  static final ResumeStorageService instance = ResumeStorageService._();

  final ValueNotifier<List<SavedResume>> resumes =
      ValueNotifier<List<SavedResume>>([]);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  // Initialize with cloud data
  Future<void> initialize() async {
    if (_isInitialized) return;

    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Load resumes from cloud
        final cloudResumes = await CloudResumeService.instance.all;
        resumes.value = cloudResumes;

        // Listen to real-time updates
        CloudResumeService.instance.resumesStream.listen((cloudResumes) {
          resumes.value = cloudResumes;
        });
      } catch (e) {
        print('Error loading cloud resumes: $e');
      }
    }

    _isInitialized = true;
  }

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Add new or replace existing (by id) - Now saves to both local and cloud
  Future<void> saveOrUpdate(SavedResume resume) async {
    // Update local storage immediately for quick UI response
    final list = [...resumes.value];
    final idx = list.indexWhere((r) => r.id == resume.id);
    if (idx >= 0) {
      list[idx] = resume;
    } else {
      list.add(resume);
    }
    resumes.value = list;

    // Save to cloud if user is authenticated
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await CloudResumeService.instance.uploadResume(resume);
        print('Resume saved to cloud successfully');
      } catch (e) {
        print('Error saving to cloud: $e');
        // Note: Local version is still saved, so user doesn't lose data
      }
    }
  }

  SavedResume? getById(String id) {
    try {
      return resumes.value.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Keep existing helper if you still use it elsewhere
  bool canCreateNewResume() {
    return PremiumService.canCreateMoreResumes(resumes.value.length);
  }

  void saveEmptyTemplate(String templateName) {
    // Check if user can create more resumes
    if (!canCreateNewResume()) {
      throw Exception(
        'Resume limit reached. Upgrade to Premium for unlimited resumes.',
      );
    }

    final now = DateTime.now();
    final r = SavedResume(
      id: generateId(),
      title: '$templateName Resume',
      template: templateName,
      createdAt: now,
      updatedAt: now,
      data: {},
    );
    resumes.value = [...resumes.value, r];
  }

  Future<void> renameResume(String id, String newTitle) async {
    final list = [...resumes.value];
    final idx = list.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final old = list[idx];
    final updated = old.copyWith(title: newTitle, updatedAt: DateTime.now());
    list[idx] = updated;
    resumes.value = list;

    // Save to cloud if user is authenticated
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await CloudResumeService.instance.uploadResume(updated);
      } catch (e) {
        print('Error updating resume in cloud: $e');
      }
    }
  }

  // Delete resume from both local and cloud
  Future<void> deleteResume(String id) async {
    final list = [...resumes.value];
    list.removeWhere((r) => r.id == id);
    resumes.value = list;

    // Delete from cloud if user is authenticated
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await CloudResumeService.instance.deleteResume(id);
      } catch (e) {
        print('Error deleting resume from cloud: $e');
      }
    }
  }

  // Sync with cloud (useful after login)
  Future<void> syncWithCloud() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final cloudResumes = await CloudResumeService.instance.all;
        resumes.value = cloudResumes;
      } catch (e) {
        print('Error syncing with cloud: $e');
      }
    }
  }
}
