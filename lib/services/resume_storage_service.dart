import 'package:flutter/foundation.dart';
import '../models/saved_resume.dart';
import 'premium_service.dart';
import 'node_api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeStorageService {
  ResumeStorageService._();
  static final ResumeStorageService instance = ResumeStorageService._();

  final ValueNotifier<List<SavedResume>> resumes =
      ValueNotifier<List<SavedResume>>([]);

  bool _isInitialized = false;
  // Map local resume ids -> remote (backend) ids
  final Map<String, String> _remoteIdMap = {};

  // Initialize with cloud data
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load remote id map
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('remote_id_map');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v is String) _remoteIdMap[k] = v;
          });
        }
      }
    } catch (_) {}

    // If premium and authenticated, pull latest resumes from backend
    if (PremiumService.hasCloudSync && ApiService.isAuthenticated) {
      try {
        final result = await ApiService.getResumes(page: 1, limit: 100);
        if (result['success'] == true && result['data'] is List) {
          final List data = result['data'] as List;
          final list = <SavedResume>[];
          for (final item in data) {
            if (item is Map) {
              final map = item.cast<String, dynamic>();
              // Expecting server fields similar to our model
              final id = (map['id'] ?? map['_id'] ?? '').toString();
              if (id.isEmpty) continue;
              final createdAtRaw =
                  (map['createdAt'] ??
                          map['created_at'] ??
                          DateTime.now().toIso8601String())
                      .toString();
              final updatedAtRaw =
                  (map['updatedAt'] ?? map['updated_at'] ?? createdAtRaw)
                      .toString();
              final r = SavedResume(
                id: id, // Use remote id directly for simplicity
                title: (map['title'] ?? 'Untitled').toString(),
                template: (map['template'] ?? 'Classic').toString(),
                createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
                updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
                data: {
                  'personalInfo': map['personalInfo'] ?? {},
                  'workExperience': map['workExperience'] ?? [],
                  'education': map['education'] ?? [],
                  'skills': map['skills'] ?? [],
                  if (map['data'] is Map)
                    ...Map<String, dynamic>.from(map['data']),
                },
              );
              list.add(r);
              _remoteIdMap[id] = id; // direct mapping when pulling from cloud
            }
          }
          resumes.value = list;
          await _persistRemoteIdMap();
        }
      } catch (_) {}
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

    // Cloud sync via Node API for premium users
    if (PremiumService.hasCloudSync && ApiService.isAuthenticated) {
      try {
        final payload = {
          'title': resume.title,
          'template': resume.template,
          'personalInfo': resume.personalInfo,
          if (resume.data['summary'] != null) 'summary': resume.data['summary'],
          'workExperience': resume.workExperience,
          'education': resume.education,
          // Convert skills (List<String>) into a list of maps expected by API if needed
          'skills': resume.skills
              .map((s) => {'label': s, 'rating': 0})
              .toList(),
          'updatedAt': resume.updatedAt.toIso8601String(),
        };

        final remoteId = _remoteIdMap[resume.id];
        if (remoteId != null && remoteId.isNotEmpty) {
          // Try update first
          final result = await ApiService.updateResume(
            resumeId: remoteId,
            updateData: payload,
          );
          if (result['success'] != true) {
            // Fallback: create if update failed
            final createRes = await ApiService.createResume(
              title: resume.title,
              template: resume.template,
              personalInfo: resume.personalInfo,
              summary: resume.data['summary'],
              workExperience: resume.workExperience,
              education: resume.education,
              skills: resume.skills
                  .map((s) => {'label': s, 'rating': 0})
                  .toList(),
            );
            final newId = _extractId(createRes['data']);
            if (newId != null) {
              _remoteIdMap[resume.id] = newId;
              await _persistRemoteIdMap();
            }
          }
        } else {
          // No remote id yet – create
          final createRes = await ApiService.createResume(
            title: resume.title,
            template: resume.template,
            personalInfo: resume.personalInfo,
            summary: resume.data['summary'],
            workExperience: resume.workExperience,
            education: resume.education,
            skills: resume.skills
                .map((s) => {'label': s, 'rating': 0})
                .toList(),
          );
          final newId = _extractId(createRes['data']);
          if (newId != null) {
            _remoteIdMap[resume.id] = newId;
            await _persistRemoteIdMap();
          }
        }
      } catch (_) {
        // ignore network errors for now
      }
    } else if (PremiumService.hasCloudSync) {
      // Fallback for offline state: persist a JSON copy to app documents as a placeholder
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/resumes_${resume.id}.json');
        await f.writeAsString(jsonEncode(resume.toJson()));
      } catch (_) {}
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

    // Cloud sync rename
    if (PremiumService.hasCloudSync && ApiService.isAuthenticated) {
      try {
        final remoteId = _remoteIdMap[id];
        if (remoteId != null && remoteId.isNotEmpty) {
          await ApiService.updateResume(
            resumeId: remoteId,
            updateData: {
              'title': newTitle,
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }
      } catch (_) {}
    }
  }

  // Delete resume from both local and cloud
  Future<void> deleteResume(String id) async {
    final list = [...resumes.value];
    list.removeWhere((r) => r.id == id);
    resumes.value = list;

    // Cloud delete
    if (PremiumService.hasCloudSync) {
      try {
        if (ApiService.isAuthenticated) {
          final remoteId = _remoteIdMap[id] ?? id;
          await ApiService.deleteResume(remoteId);
        }

        // Remove local placeholder file if any
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/resumes_$id.json');
        if (await f.exists()) await f.delete();

        // Remove mapping
        _remoteIdMap.remove(id);
        await _persistRemoteIdMap();
      } catch (_) {}
    }
  }

  // Sync with cloud (useful after login)
  Future<void> syncWithCloud() async {
    if (!(PremiumService.hasCloudSync && ApiService.isAuthenticated)) return;
    try {
      final result = await ApiService.getResumes(page: 1, limit: 100);
      if (result['success'] == true && result['data'] is List) {
        final List data = result['data'] as List;
        final list = <SavedResume>[];
        for (final item in data) {
          if (item is Map) {
            final map = item.cast<String, dynamic>();
            final id = (map['id'] ?? map['_id'] ?? '').toString();
            if (id.isEmpty) continue;
            final createdAtRaw =
                (map['createdAt'] ??
                        map['created_at'] ??
                        DateTime.now().toIso8601String())
                    .toString();
            final updatedAtRaw =
                (map['updatedAt'] ?? map['updated_at'] ?? createdAtRaw)
                    .toString();
            final r = SavedResume(
              id: id,
              title: (map['title'] ?? 'Untitled').toString(),
              template: (map['template'] ?? 'Classic').toString(),
              createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
              updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
              data: {
                'personalInfo': map['personalInfo'] ?? {},
                'workExperience': map['workExperience'] ?? [],
                'education': map['education'] ?? [],
                'skills': map['skills'] ?? [],
                if (map['data'] is Map)
                  ...Map<String, dynamic>.from(map['data']),
              },
            );
            list.add(r);
            _remoteIdMap[id] = id;
          }
        }
        resumes.value = list;
        await _persistRemoteIdMap();
      }
    } catch (_) {}
  }

  Future<void> _persistRemoteIdMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('remote_id_map', jsonEncode(_remoteIdMap));
    } catch (_) {}
  }

  String? _extractId(dynamic data) {
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      final flatId = map['id'] ?? map['_id'];
      if (flatId is String && flatId.isNotEmpty) return flatId;
      // common nested shapes: { data: { id: ... } } or { resume: { id: ... } }
      for (final key in ['data', 'resume']) {
        final nested = map[key];
        if (nested is Map) {
          final nid = (nested['id'] ?? nested['_id']);
          if (nid is String && nid.isNotEmpty) return nid;
        }
      }
    }
    return null;
  }
}
