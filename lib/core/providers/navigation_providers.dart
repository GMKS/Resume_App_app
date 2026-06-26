import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected bottom navigation tab index.
final currentTabProvider = StateProvider<int>((ref) => 0);

enum ResumeListFilter { all, completed, inProgress }

final resumeListFilterProvider =
	StateProvider<ResumeListFilter>((ref) => ResumeListFilter.all);
