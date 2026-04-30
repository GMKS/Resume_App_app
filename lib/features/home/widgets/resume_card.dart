import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';

class ResumeCard extends StatelessWidget {
  final ResumeModel resume;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const ResumeCard({
    super.key,
    required this.resume,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final progress = resume.completionPercentage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTemplateColor(resume.templateId),
                    _getTemplateColor(resume.templateId).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.document_text_1,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resume.personalInfo.fullName.isEmpty
                              ? 'No name set'
                              : resume.personalInfo.fullName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      _buildPopupItem(Iconsax.eye, 'Preview', 'preview'),
                      _buildPopupItem(
                          Iconsax.document_download, 'Download', 'download'),
                      _buildPopupItem(Iconsax.copy, 'Duplicate', 'duplicate'),
                      _buildPopupItem(Iconsax.trash, 'Delete', 'delete',
                          isDestructive: true),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'preview':
                          onPreview();
                          break;
                        case 'download':
                          onDownload();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '$progress%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _getProgressColor(progress),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progress),
                              ),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _StatItem(
                        icon: Iconsax.briefcase,
                        count: resume.experience.length,
                        label: 'Experience',
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Iconsax.teacher,
                        count: resume.education.length,
                        label: 'Education',
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Iconsax.code,
                        count: resume.skills.length,
                        label: 'Skills',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.calendar_1,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated ${_formatDate(resume.updatedAt)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTemplateColor(resume.templateId)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTemplateName(resume.templateId),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _getTemplateColor(resume.templateId),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String label,
    String value, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemplateColor(String templateId) {
    switch (templateId) {
      case 'modern':
        return AppColors.primary;
      case 'classic':
        return AppColors.secondary;
      case 'creative':
        return const Color(0xFFF59E0B);
      case 'minimal':
        return const Color(0xFF64748B);
      case 'professional':
        return const Color(0xFF0EA5E9);
      case 'developer':
        return const Color(0xFF8B5CF6);
      case 'infographic':
        return const Color(0xFFEC4899);
      case 'two_column':
        return const Color(0xFF14B8A6);
      case 'executive':
        return const Color(0xFF1E293B);
      case 'startup':
        return const Color(0xFFEF4444);
      case 'academic':
        return const Color(0xFF3730A3);
      case 'sales':
        return const Color(0xFFD946EF);
      case 'elegant_pink':
        return const Color(0xFFE91E8C);
      case 'blue_gray':
        return const Color(0xFF343d4d);
      case 'mono_nova':
        return const Color(0xFF57534E);
      case 'slate_arc':
        return const Color(0xFF7A818C);
      case 'editorial_frame':
        return const Color(0xFFB08863);
      case 'graphite_column':
        return const Color(0xFF55565A);
      case 'rosewood_panel':
        return const Color(0xFFC7A09B);
      case 'designer_profile':
        return const Color(0xFF35569C);
      case 'modern_edge':
        return const Color(0xFF6CB38E);
      case 'minimal_clean':
        return const Color(0xFF8FB0D6);
      case 'minimal_clean_ats':
        return const Color(0xFF7D2E2C);
      case 'professional_tone':
        return const Color(0xFF516785);
      case 'elegant_design':
        return const Color(0xFFC9935B);
      case 'creative_professional':
        return const Color(0xFF2D8C87);
      case 'bluewave_tech':
        return const Color(0xFF2F66B0);
      case 'balanced_two_column_layout':
        return const Color(0xFFB28B5C);
      case 'elegant_gold_layout':
        return const Color(0xFFC29A55);
      case 'corporate_navy':
        return const Color(0xFF2F4F75);
      case 'forest_edge_classic':
        return const Color(0xFFAEB8C2);
      case 'forest_edge':
        return const Color(0xFF9AA7B4);
      default:
        return AppColors.primary;
    }
  }

  String _getTemplateName(String templateId) {
    switch (templateId) {
      case 'modern':
        return 'Modern Nova';
      case 'classic':
        return 'Classic';
      case 'creative':
        return 'Creative';
      case 'minimal':
        return 'Minimal';
      case 'professional':
        return 'Professional';
      case 'developer':
        return 'Developer';
      case 'infographic':
        return 'Infographic';
      case 'two_column':
        return 'Two Column';
      case 'executive':
        return 'Business Management Resume';
      case 'startup':
        return 'Startup';
      case 'academic':
        return 'Academic';
      case 'sales':
        return 'Sales & Marketing';
      case 'elegant_pink':
        return 'Pink Rosé Modern';
      case 'blue_gray':
        return 'FlexColor Sidebar';
      case 'modern_aesthetic':
        return 'SharpLine Resume';
      case 'modern_resume':
        return 'Elite Resume';
      case 'mono_nova':
        return 'Black and White';
      case 'slate_arc':
        return 'Slate Arc';
      case 'editorial_frame':
        return 'Editorial Frame';
      case 'graphite_column':
        return 'Graphite Column';
      case 'rosewood_panel':
        return 'Rosewood Panel';
      case 'designer_profile':
        return 'Design/Creative Resume';
      case 'modern_edge':
        return 'Persona Pro CV';
      case 'minimal_clean':
        return 'Minimal Clean';
      case 'minimal_clean_ats':
        return 'Minimal Clean ATS';
      case 'professional_tone':
        return 'HealthCare Resume';
      case 'elegant_design':
        return 'Elegant design';
      case 'creative_professional':
        return 'Creative professional';
      case 'bluewave_tech':
        return 'Bluewave Tech';
      case 'balanced_two_column_layout':
        return 'Balanced two-column layout';
      case 'elegant_gold_layout':
        return 'Human Resources Resume';
      case 'corporate_navy':
        return 'Corporate Navy';
      case 'forest_edge_classic':
        return 'Forest Edge Classic';
      case 'forest_edge':
        return 'Forest Edge';
      default:
        return 'Modern';
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
