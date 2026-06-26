import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_sync_service.dart';

class AnalyzedSkill {
  const AnalyzedSkill({
    required this.id,
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.marketDemand,
    required this.isUserAdded,
    required this.createdAt,
    required this.updatedAt,
    this.yearsOfExperience,
  });

  final String id;
  final String name;
  final String category;
  final int currentLevel;
  final int marketDemand;
  final double? yearsOfExperience;
  final bool isUserAdded;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get status {
    if (currentLevel >= 80) {
      return 'Strong';
    }
    if (currentLevel >= 65) {
      return 'Good';
    }
    return 'Needs Improvement';
  }

  AnalyzedSkill copyWith({
    String? id,
    String? name,
    String? category,
    int? currentLevel,
    int? marketDemand,
    double? yearsOfExperience,
    bool clearYearsOfExperience = false,
    bool? isUserAdded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalyzedSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentLevel: currentLevel ?? this.currentLevel,
      marketDemand: marketDemand ?? this.marketDemand,
      yearsOfExperience: clearYearsOfExperience
          ? null
          : (yearsOfExperience ?? this.yearsOfExperience),
      isUserAdded: isUserAdded ?? this.isUserAdded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'currentLevel': currentLevel,
      'marketDemand': marketDemand,
      'yearsOfExperience': yearsOfExperience,
      'isUserAdded': isUserAdded,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnalyzedSkill.fromMap(Map<String, dynamic> map) {
    return AnalyzedSkill(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString().trim() ?? '',
      category: map['category']?.toString().trim() ?? 'Other',
      currentLevel: (map['currentLevel'] as num?)?.round() ?? 0,
      marketDemand: (map['marketDemand'] as num?)?.round() ?? 75,
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toDouble(),
      isUserAdded: map['isUserAdded'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SkillAnalyzerState {
  const SkillAnalyzerState({
    required this.isLoading,
    required this.userSkills,
    this.errorMessage,
  });

  final bool isLoading;
  final List<AnalyzedSkill> userSkills;
  final String? errorMessage;

  SkillAnalyzerState copyWith({
    bool? isLoading,
    List<AnalyzedSkill>? userSkills,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SkillAnalyzerState(
      isLoading: isLoading ?? this.isLoading,
      userSkills: userSkills ?? this.userSkills,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const SkillAnalyzerState initial = SkillAnalyzerState(
    isLoading: true,
    userSkills: <AnalyzedSkill>[],
  );
}

class SkillAnalyzerService {
  const SkillAnalyzerService();

  static const String _storageKeyPrefix = 'skill_analyzer_entries_';
  static const String _localFallbackKey = '${_storageKeyPrefix}local';
  static const String _cloudCollection = 'skill_analyzer';
  static const String _cloudField = 'skills';
  static const Uuid _uuid = Uuid();

  static final List<AnalyzedSkill> defaultSkills = <AnalyzedSkill>[
    AnalyzedSkill(
      id: 'default_flutter_development',
      name: 'Flutter Development',
      category: 'Technical',
      currentLevel: 85,
      marketDemand: 90,
      isUserAdded: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    AnalyzedSkill(
      id: 'default_project_management',
      name: 'Project Management',
      category: 'Leadership',
      currentLevel: 70,
      marketDemand: 85,
      isUserAdded: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    AnalyzedSkill(
      id: 'default_ui_ux_design',
      name: 'UI/UX Design',
      category: 'Design',
      currentLevel: 60,
      marketDemand: 95,
      isUserAdded: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    AnalyzedSkill(
      id: 'default_communication',
      name: 'Communication',
      category: 'Soft Skills',
      currentLevel: 75,
      marketDemand: 80,
      isUserAdded: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    AnalyzedSkill(
      id: 'default_data_analysis',
      name: 'Data Analysis',
      category: 'Technical',
      currentLevel: 50,
      marketDemand: 90,
      isUserAdded: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
  ];

  Future<String> _storageKey() async {
    final userId = await SupabaseSyncService.currentUserId;
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return _localFallbackKey;
    }
    return '$_storageKeyPrefix$normalized';
  }

  Future<List<String>> _storageKeysForRead() async {
    final primary = await _storageKey();
    if (primary == _localFallbackKey) {
      return const <String>[_localFallbackKey];
    }
    return <String>[primary, _localFallbackKey];
  }

  Future<List<String>> _storageKeysForWrite() async {
    final primary = await _storageKey();
    if (primary == _localFallbackKey) {
      return const <String>[_localFallbackKey];
    }
    return <String>[primary, _localFallbackKey];
  }

  Future<List<AnalyzedSkill>> loadUserSkills() async {
    final local = await _loadFromLocal();
    if (local.isNotEmpty) {
      return local;
    }

    final restored = await _loadFromCloud();
    if (restored.isNotEmpty) {
      await persistUserSkills(restored);
    }
    return restored;
  }

  Future<void> persistUserSkills(List<AnalyzedSkill> skills) async {
    final payload = skills.map((skill) => skill.toMap()).toList(growable: false);
    final encoded = jsonEncode(payload);
    final keys = await _storageKeysForWrite();
    for (final key in keys) {
      await StorageService.prefs.setString(key, encoded);
    }

    await SupabaseSyncService.manualBackupJsonList(
      collection: _cloudCollection,
      field: _cloudField,
      items: payload,
    );
  }

  AnalyzedSkill buildUserSkill({
    required String name,
    required String category,
    required int currentLevel,
    double? yearsOfExperience,
    String? existingId,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return AnalyzedSkill(
      id: existingId ?? _uuid.v4(),
      name: name.trim(),
      category: category.trim(),
      currentLevel: currentLevel.clamp(0, 100),
      marketDemand: _defaultMarketDemandFor(category),
      yearsOfExperience: yearsOfExperience,
      isUserAdded: true,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  List<AnalyzedSkill> insertOrUpdate({
    required List<AnalyzedSkill> skills,
    required AnalyzedSkill candidate,
  }) {
    final updated = <AnalyzedSkill>[];
    var replaced = false;

    for (final skill in skills) {
      if (skill.id == candidate.id) {
        updated.add(candidate);
        replaced = true;
      } else {
        updated.add(skill);
      }
    }

    if (!replaced) {
      updated.insert(0, candidate);
    }

    updated.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return updated;
  }

  List<AnalyzedSkill> deleteSkill({
    required List<AnalyzedSkill> skills,
    required String skillId,
  }) {
    return skills.where((skill) => skill.id != skillId).toList(growable: false);
  }

  Future<List<AnalyzedSkill>> _loadFromLocal() async {
    final keys = await _storageKeysForRead();
    for (final key in keys) {
      final raw = StorageService.prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          continue;
        }

        final skills = decoded
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
            .map(AnalyzedSkill.fromMap)
            .where((skill) => skill.name.isNotEmpty)
            .toList(growable: false)
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

        if (skills.isNotEmpty) {
          return skills;
        }
      } catch (_) {
        continue;
      }
    }

    return const <AnalyzedSkill>[];
  }

  Future<List<AnalyzedSkill>> _loadFromCloud() async {
    try {
      final items = await SupabaseSyncService.manualRestoreJsonList(
        collection: _cloudCollection,
        field: _cloudField,
      );

      return items
          .map(AnalyzedSkill.fromMap)
          .where((skill) => skill.name.isNotEmpty)
          .toList(growable: false)
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    } catch (_) {
      return const <AnalyzedSkill>[];
    }
  }

  static int _defaultMarketDemandFor(String category) {
    switch (category.trim()) {
      case 'Technical':
        return 90;
      case 'Leadership':
        return 85;
      case 'Soft Skills':
        return 80;
      case 'Domain':
        return 88;
      case 'Design':
        return 84;
      default:
        return 75;
    }
  }
}

final skillAnalyzerServiceProvider = Provider<SkillAnalyzerService>((ref) {
  return const SkillAnalyzerService();
});

class SkillAnalyzerController extends StateNotifier<SkillAnalyzerState> {
  SkillAnalyzerController(this._service) : super(SkillAnalyzerState.initial) {
    load();
  }

  final SkillAnalyzerService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userSkills = await _service.loadUserSkills();
      state = state.copyWith(
        isLoading: false,
        userSkills: userSkills,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> saveSkill(AnalyzedSkill draft) async {
    final updated = _service.insertOrUpdate(
      skills: state.userSkills,
      candidate: draft,
    );
    await _service.persistUserSkills(updated);
    state = state.copyWith(userSkills: updated, clearError: true);
  }

  Future<void> deleteSkill(String skillId) async {
    final updated = _service.deleteSkill(
      skills: state.userSkills,
      skillId: skillId,
    );
    await _service.persistUserSkills(updated);
    state = state.copyWith(userSkills: updated, clearError: true);
  }
}

final skillAnalyzerControllerProvider = StateNotifierProvider<
    SkillAnalyzerController,
    SkillAnalyzerState>((ref) {
  return SkillAnalyzerController(ref.read(skillAnalyzerServiceProvider));
});