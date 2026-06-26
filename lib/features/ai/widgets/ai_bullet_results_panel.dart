import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/theme/app_theme.dart';

class AiBulletResultsPanel extends StatelessWidget {
  final List<String> bullets;
  final Set<int> selectedIndexes;
  final Set<int> copiedIndexes;
  final List<ResumeModel> resumes;
  final String? selectedResumeId;
  final ValueChanged<String?> onResumeChanged;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<int> onCopyBullet;
  final VoidCallback onToggleSelectAll;
  final VoidCallback? onCopySelected;
  final VoidCallback? onAddSelectedToResume;

  const AiBulletResultsPanel({
    super.key,
    required this.bullets,
    required this.selectedIndexes,
    required this.copiedIndexes,
    required this.resumes,
    required this.selectedResumeId,
    required this.onResumeChanged,
    required this.onToggleSelection,
    required this.onCopyBullet,
    required this.onToggleSelectAll,
    required this.onCopySelected,
    required this.onAddSelectedToResume,
  });

  bool get _allSelected =>
      bullets.isNotEmpty && selectedIndexes.length == bullets.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Generated Bullets',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${bullets.length} bullets',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select multiple bullet points to copy or add directly to a resume entry.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onToggleSelectAll,
                    icon: Icon(_allSelected
                        ? Iconsax.close_circle
                        : Iconsax.tick_square),
                    label: Text(_allSelected ? 'Deselect All' : 'Select All'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onCopySelected,
                    icon: const Icon(Iconsax.copy),
                    label: Text(
                      selectedIndexes.isEmpty
                          ? 'Copy Selected'
                          : 'Copy Selected (${selectedIndexes.length})',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onAddSelectedToResume,
                    icon: const Icon(Iconsax.document_text_1),
                    label: const Text('Add Selected to Resume'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resumes.isEmpty)
                Text(
                  'Create a resume first to enable Add Selected to Resume.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('bullet-target-${selectedResumeId ?? 'none'}'),
                  initialValue: selectedResumeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Iconsax.document_text_1),
                    labelText: 'Target Resume',
                    hintText: 'Select a resume to update',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: resumes
                      .map(
                        (resume) => DropdownMenuItem<String>(
                          value: resume.id,
                          child: Text(
                            resume.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onResumeChanged,
                ),
              const SizedBox(height: 10),
              Text(
                selectedIndexes.isEmpty
                    ? 'No bullets selected yet.'
                    : '${selectedIndexes.length} bullet${selectedIndexes.length == 1 ? '' : 's'} selected.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...bullets.asMap().entries.map((entry) {
          final index = entry.key;
          final bullet = entry.value;
          final isSelected = selectedIndexes.contains(index);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.primary.withValues(alpha: 0.2),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onToggleSelection(index),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Checkbox.adaptive(
                        value: isSelected,
                        onChanged: (_) => onToggleSelection(index),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy bullet',
                      onPressed: () => onCopyBullet(index),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: copiedIndexes.contains(index)
                            ? const Icon(
                                Iconsax.tick_circle,
                                key: ValueKey('done'),
                                color: Color(0xFF10B981),
                                size: 20,
                              )
                            : const Icon(
                                Iconsax.copy,
                                key: ValueKey('copy'),
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
