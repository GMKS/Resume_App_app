import 'package:flutter/material.dart';
// import '../services/cloud_resume_service.dart';

class ClassicCloudUsageBadge extends StatelessWidget {
  const ClassicCloudUsageBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Restore cloud functionality when Firebase services are working
    return const Chip(
      label: Text('Classic Cloud: 0 / 2'),
      avatar: Icon(Icons.cloud_outlined, size: 18),
    );

    /* TODO: Restore when cloud services are working
    return FutureBuilder<List<SavedResume>>(
      future: CloudResumeService.instance.all,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Chip(
            label: Text('Classic Cloud: ... / 2'),
            avatar: Icon(Icons.cloud_outlined, size: 18),
          );
        }
        
        final used = snapshot.data!
            .where((r) => r.template == 'Classic')
            .length;
        return Chip(
          label: Text('Classic Cloud: $used / ${CloudResumeService.classicLimit}'),
          avatar: const Icon(Icons.cloud_outlined, size: 18),
        );
      },
    );
    */
  }
}
