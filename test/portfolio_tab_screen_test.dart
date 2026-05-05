import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/subscription_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/core/services/subscription_service.dart';
import 'package:resume_builder/features/portfolio/screens/portfolio_tab_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith((ref) {
          final service = SubscriptionService();
          service.upgradeToPlan(SubscriptionPlan.monthly);
          return service;
        }),
      ],
      child: const MaterialApp(
        home: PortfolioTabScreen(),
      ),
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp('portfolio-tab-test');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await StorageService.prefs.clear();
  });

  testWidgets('adding a project updates the UI and persists after rebuild', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('E-Commerce Platform'), findsOneWidget);

    final addButton = find.widgetWithText(TextButton, 'Add');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Project Title'),
      'Portfolio Case Study',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Description'),
      'Interactive resume and portfolio experience',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save Project'));
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Case Study'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Case Study'), findsOneWidget);
    expect(
      find.text('Interactive resume and portfolio experience'),
      findsOneWidget,
    );
  });
}