import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'user-custom-section-lifecycle-regression',
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

  Future<void> pumpTestApp(
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

  Future<void> settleUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<String> createUserSection(
    WidgetTester tester, {
    required String title,
    required String content,
  }) async {
    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), title);
    await tester.enterText(textFields.at(1), content);

    await tester.tap(find.text('Create Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    expect(savedResume, isNotNull);

    return savedResume!.customSections
        .firstWhere((section) => section.title == title)
        .id;
  }

  testWidgets('user custom section back, cancel, and save stay stable', (
    tester,
  ) async {
    final sectionId = await createUserSection(
      tester,
      title: 'Personal Details',
      content: 'Current role highlights',
    );

    final route =
        '/editor/$resumeEditorCustomSectionResumeId/user-custom/$sectionId';

    await pumpTestApp(tester, initialLocation: route);

    await tester.tap(find.byIcon(Iconsax.arrow_left).first);
    await settleUi(tester);

    expect(find.text('Editor Test Resume'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpTestApp(tester, initialLocation: route);

    await tester.tap(find.widgetWithText(FilledButton, 'Add Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byIcon(Iconsax.close_circle).last);
    await settleUi(tester);

    expect(find.text('Description / Content'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Add Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(
        find.byType(TextFormField).first, 'Led hiring panel');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Entry'));
    await settleUi(tester);

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    final savedSection = savedResume!.customSections.firstWhere(
      (section) => section.id == sectionId,
    );

    expect(savedSection.items, isNotEmpty);
    expect(
      savedSection.items.any(
        (item) => item.title.contains('Led hiring panel'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await disposeTestWidgetTree(tester);
  });
}
