import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';

class AiReviewNotice extends StatelessWidget {
  const AiReviewNotice({
    super.key,
    this.message =
        'AI-generated content should be reviewed before use. It does not guarantee interviews, job offers, or resume success.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}