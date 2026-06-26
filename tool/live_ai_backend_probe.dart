import 'package:flutter/material.dart';

import 'package:resume_builder/core/services/ai_resume_service.dart';
import 'package:resume_builder/core/services/app_config_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _LiveAiBackendProbeApp());
}

class _LiveAiBackendProbeApp extends StatelessWidget {
  const _LiveAiBackendProbeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _LiveAiBackendProbeScreen(),
    );
  }
}

class _LiveAiBackendProbeScreen extends StatefulWidget {
  const _LiveAiBackendProbeScreen();

  @override
  State<_LiveAiBackendProbeScreen> createState() =>
      _LiveAiBackendProbeScreenState();
}

class _LiveAiBackendProbeScreenState extends State<_LiveAiBackendProbeScreen> {
  String _status = 'Starting live AI backend probe...';

  @override
  void initState() {
    super.initState();
    _runProbe();
  }

  Future<void> _runProbe() async {
    try {
      await AppConfigService.initialize();

      final health = await AiResumeService.validateAvailability(
        forceRefresh: true,
      );

      if (!health.available) {
        setState(() {
          _status = 'HEALTH_CHECK_FAILED\n${health.message}';
        });
        return;
      }

      final result = await AiResumeService.generateBulletPoints(
        jobTitle: 'Software Engineer',
        company: 'Example Corp',
        industry: 'Technology',
        existingDescription:
            'Built internal tools for operations reporting and reduced manual spreadsheet work.',
      );

      final bullets = (result['bullets'] as List?)
              ?.map((bullet) => bullet.toString().trim())
              .where((bullet) => bullet.isNotEmpty)
              .toList() ??
          <String>[];

      if (bullets.isEmpty) {
        setState(() {
          _status = 'EMPTY_RESULT\nThe backend responded, but no bullets were returned.';
        });
        return;
      }

      setState(() {
        _status = 'SUCCESS\n${bullets.first}';
      });
    } catch (error) {
      setState(() {
        _status = 'EXCEPTION\n${AiResumeService.describeUnexpectedError(error)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            _status,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}