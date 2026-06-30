import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/models/subscription_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/core/services/subscription_service.dart';
import 'package:resume_builder/features/portfolio/screens/portfolio_tab_screen.dart';
import 'package:resume_builder/features/portfolio/services/portfolio_profile_service.dart';

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

  Future<void> pumpPortfolioScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
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
    await StorageService.resumeBox.clear();

    await StorageService.resumeBox.put(
      'resume-1',
      ResumeModel(
        id: 'resume-1',
        title: 'Mobile Resume',
        personalInfo: PersonalInfo(
          fullName: 'John Smith',
          email: 'john@example.com',
          phone: '555-0100',
          address: 'Bengaluru, IN',
          website: 'portfolio.johnsmith.dev',
          jobTitle: 'Flutter Developer',
        ),
        objective:
            'Flutter engineer focused on building polished mobile products with reliable release flows.',
        projects: <Project>[
          Project(
            id: 'project-1',
            title: 'Resume Portfolio',
            description: 'Interactive resume and portfolio experience',
            url: 'https://portfolio.johnsmith.dev',
            technologies: const <String>['Flutter', 'Firebase'],
          ),
        ],
        certifications: <Certification>[
          Certification(
            id: 'cert-1',
            name: 'Flutter Developer Certification',
            issuer: 'Google',
          ),
        ],
        experience: <Experience>[
          Experience(
            id: 'exp-1',
            company: 'Acme',
            position: 'Mobile Engineer',
            startDate: DateTime(2023, 1, 1),
            isCurrentlyWorking: true,
            description:
                'Built cross-platform product flows for customer-facing apps.',
            achievements: const <String>[
              'Improved onboarding completion by 22%',
            ],
          ),
        ],
        skills: <Skill>[
          Skill(id: 'skill-1', name: 'Flutter'),
          Skill(id: 'skill-2', name: 'Dart'),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      ),
    );
  });

  testWidgets('portfolio syncs resume data and manual highlights persist', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await pumpPortfolioScreen(tester);

    expect(find.text('John Smith'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('https://portfolio.johnsmith.dev'), findsOneWidget);
    expect(find.text('Resume Portfolio'), findsOneWidget);
    expect(find.text('Flutter Developer Certification'), findsOneWidget);

    expect(find.byType(QrImageView), findsOneWidget);

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
      findsWidgets,
    );
  });

  test('portfolio uses linkedin when no website or project url exists', () {
    final resume = ResumeModel(
      id: 'resume-1',
      title: 'LinkedIn Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jane Smith',
        email: 'jane@example.com',
        linkedIn: 'linkedin.com/in/jane-smith',
        jobTitle: 'Automation Lead',
      ),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    expect(
      PortfolioProfileService.resolvePortfolioUrl(resume),
      'https://linkedin.com/in/jane-smith',
    );
    expect(
      PortfolioProfileService.selectSourceResume(<ResumeModel>[resume])?.id,
      'resume-1',
    );
  });
}
