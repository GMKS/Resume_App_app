import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty_state_card.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const EmptyState({
    super.key,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: AppEmptyStateCard(
        icon: Iconsax.document_text_15,
        accentColor: AppColors.primary,
        title: 'No Resumes Yet',
        message:
            'Create your first professional resume and start applying for your dream jobs!',
        actionLabel: 'Create Resume',
        onAction: onCreateTap,
      ),
    );
  }
}
