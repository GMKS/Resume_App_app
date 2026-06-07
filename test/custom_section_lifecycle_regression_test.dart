import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'custom-section-lifecycle-regression',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
    await StorageService.prefs.setString('subscription_plan', 'premium');
    await StorageService.prefs.setString(
      'subscription_expiry',
      DateTime(2030, 1, 1).millisecondsSinceEpoch.toString(),
    );
  });

  Future<void> _pumpTestApp(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    await tester.pumpWidget(
      buildResumeEditorCustomSectionTestApp(
        initialLocation: initialLocation,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> _settleUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('built-in custom section back, cancel, and save stay stable', (
    tester,
  ) async {
    final route =
        '/editor/$resumeEditorCustomSectionResumeId/custom/startup_achievements';

    await _pumpTestApp(tester, initialLocation: route);

    await tester.tap(find.byIcon(Iconsax.arrow_left).first);
    await _settleUi(tester);

    expect(find.text('Editor Test Resume'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpTestApp(tester, initialLocation: route);

    final addFirstItemButton = find.text('Add First Item');
    if (addFirstItemButton.evaluate().isNotEmpty) {
      await tester.tap(addFirstItemButton);
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byIcon(Iconsax.close_circle).last);
    await _settleUi(tester);

    expect(find.text('Title'), findsNothing);
    expect(tester.takeException(), isNull);

    final addButtonAgain = find.text('Add First Item');
    if (addButtonAgain.evaluate().isNotEmpty) {
      await tester.tap(addButtonAgain);
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Launch Award');
    await tester.enterText(textFields.at(1), 'Release excellence');
    await tester.enterText(textFields.at(2), 'Reduced production regressions.');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Item'));
    await _settleUi(tester);

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    final savedSection = savedResume!.customSections.firstWhere(
      (section) => section.id == 'startup_achievements',
    );

    expect(savedSection.items.any((item) => item.title == 'Launch Award'), isTrue);
    expect(tester.takeException(), isNull);

    await disposeTestWidgetTree(tester);
  });
}