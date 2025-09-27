import 'package:flutter/foundation.dart';
import '../models/saved_resume.dart';
import 'premium_service.dart';

class ResumeStorageService {
  ResumeStorageService._();
  static final ResumeStorageService instance = ResumeStorageService._();

  final ValueNotifier<List<SavedResume>> resumes =
      ValueNotifier<List<SavedResume>>([]);

  bool _isInitialized = false;

  // Initialize with cloud data
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Cloud sync disabled in this build. Keep local-only store.

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

    // Cloud sync disabled in this build
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

    // Cloud sync disabled in this build
  }

  // Delete resume from both local and cloud
  Future<void> deleteResume(String id) async {
    final list = [...resumes.value];
    list.removeWhere((r) => r.id == id);
    resumes.value = list;

    // Cloud sync disabled in this build
  }

  // Sync with cloud (useful after login)
  Future<void> syncWithCloud() async {
    // Cloud sync disabled in this build
  }
}
