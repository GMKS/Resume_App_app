import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/ai_resume_service.dart';
import 'package:resume_builder/core/services/app_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Flutter client can generate AI bullet points through live backend',
      () async {
    await AppConfigService.initialize();

    final health = await AiResumeService.validateAvailability(
      forceRefresh: true,
    );

    expect(health.configured, isTrue);
    expect(health.reachable, isTrue, reason: health.message);

    final result = await AiResumeService.generateBulletPoints(
      jobTitle: 'Software Engineer',
      company: 'Example Corp',
      industry: 'Technology',
      existingDescription:
          'Built internal tools for operations reporting and reduced manual spreadsheet work.',
    );

    final bullets = (result['bullets'] as List?)?.cast<Object?>() ?? const [];

    expect(bullets, isNotEmpty);
    expect(
      bullets.every((bullet) => bullet.toString().trim().isNotEmpty),
      isTrue,
    );
  });
}
