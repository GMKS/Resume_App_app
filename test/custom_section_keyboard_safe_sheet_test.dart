import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'custom-section-keyboard-safe',
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

  testWidgets(
      'add custom section sheet stays stable on a compact screen with keyboard insets',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await openAddCustomSectionSheet(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final textFields = find.byType(TextFormField);
  await tester.ensureVisible(textFields.at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Create Section'), findsOneWidget);
    expect(find.text('Description / Content'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeTestWidgetTree(tester);
  });
}