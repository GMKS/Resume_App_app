import 'package:flutter/foundation.dart';
import '../models/saved_resume.dart';

class ResumeStorageService {
  ResumeStorageService._();
  static final ResumeStorageService instance = ResumeStorageService._();

  final ValueNotifier<List<SavedResume>> resumes =
      ValueNotifier<List<SavedResume>>([]);

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Add new or replace existing (by id)
  Future<void> saveOrUpdate(SavedResume resume) async {
    final list = [...resumes.value];
    final idx = list.indexWhere((r) => r.id == resume.id);
    if (idx >= 0) {
      list[idx] = resume;
    } else {
      list.add(resume);
    }
    resumes.value = list;
  }

  SavedResume? getById(String id) => resumes.value.firstWhere(
    (r) => r.id == id,
    orElse: () => null as SavedResume,
  );

  // Keep existing helper if you still use it elsewhere
  void saveEmptyTemplate(String templateName) {
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
    list[idx] = old.copyWith(title: newTitle, updatedAt: DateTime.now());
    resumes.value = list;
  }

  Future<void> deleteResume(String id) async {
    resumes.value = resumes.value.where((r) => r.id != id).toList();
  }
}
