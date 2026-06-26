import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/theme/app_theme.dart';
import 'package:resume_builder/features/home/widgets/stats_card.dart';

void main() {
  testWidgets('stats card exposes button semantics and handles taps',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: StatsCard(
                icon: Icons.description_outlined,
                title: '27',
                subtitle: 'Total Resumes',
                color: AppColors.primary,
                onTap: () => tapCount++,
                semanticLabel: 'Total resumes, 27',
                semanticHint: 'Opens the full resume list',
              ),
            ),
          ),
        ),
      ),
    );

    final semantics = SemanticsTester(tester);
    final statsCardFinder = find.byType(StatsCard);

    expect(
      semantics,
      includesNodeWith(
        label: 'Total resumes, 27',
        hint: 'Opens the full resume list',
        actions: <SemanticsAction>[SemanticsAction.tap],
        flags: <SemanticsFlag>[SemanticsFlag.isButton],
      ),
    );

    await tester.tapAt(tester.getCenter(statsCardFinder));
    await tester.pumpAndSettle();

    expect(tapCount, 1);

    semantics.dispose();
  });
}