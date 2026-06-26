import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/ai/widgets/ai_bullet_results_panel.dart';

ResumeModel _resume(String id, String title) {
  final now = DateTime(2026, 6, 1);
  return ResumeModel(
    id: id,
    title: title,
    personalInfo: PersonalInfo(fullName: 'Jordan Smith'),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('results panel exposes multi-select and resume actions', (
    tester,
  ) async {
    var selectAllCalls = 0;
    var copyBulletIndex = -1;
    var toggledSelection = -1;
    var copySelectedCalls = 0;
    var addSelectedCalls = 0;
    String? selectedResumeId;

    final resumes = [_resume('r1', 'Resume One'), _resume('r2', 'Resume Two')];
    const bullets = [
      'Designed and implemented automated workflows using Flutter and Firebase to improve release quality and delivery speed.',
      'Built CI/CD scripts and deployment safeguards that reduced manual errors and accelerated release turnaround across teams.',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiBulletResultsPanel(
            bullets: bullets,
            selectedIndexes: const {0},
            copiedIndexes: const {},
            resumes: resumes,
            selectedResumeId: 'r1',
            onResumeChanged: (value) => selectedResumeId = value,
            onToggleSelection: (index) => toggledSelection = index,
            onCopyBullet: (index) => copyBulletIndex = index,
            onToggleSelectAll: () => selectAllCalls++,
            onCopySelected: () => copySelectedCalls++,
            onAddSelectedToResume: () => addSelectedCalls++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Copy Selected (1)'), findsOneWidget);

    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    expect(selectAllCalls, 1);

    await tester.tap(find.textContaining('Designed and implemented automated workflows'));
    await tester.pumpAndSettle();
    expect(toggledSelection, 0);

    await tester.tap(find.byTooltip('Copy bullet').first);
    await tester.pumpAndSettle();
    expect(copyBulletIndex, 0);

    await tester.tap(find.text('Copy Selected (1)'));
    await tester.pumpAndSettle();
    expect(copySelectedCalls, 1);

    await tester.tap(find.text('Add Selected to Resume'));
    await tester.pumpAndSettle();
    expect(addSelectedCalls, 1);

    await tester.tap(find.text('Resume One'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume Two').last);
    await tester.pumpAndSettle();
    expect(selectedResumeId, 'r2');
  });
}