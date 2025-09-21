import 'package:flutter/material.dart';
import '../services/cloud_resume_service.dart';

class ClassicCloudUsageBadge extends StatelessWidget {
  const ClassicCloudUsageBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final used = CloudResumeService.instance.all
        .where((r) => r.template == 'Classic')
        .length;
    return Chip(
      label: Text('Classic Cloud: $used / ${CloudResumeService.classicLimit}'),
      avatar: const Icon(Icons.cloud_outlined, size: 18),
    );
  }
}
