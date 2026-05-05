import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/resume_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../templates/screens/template_selection_screen.dart';

/// Available font families for resume PDF rendering.
const kResumeFonts = <String, String>{
  'Roboto': 'Clean & modern, great for tech resumes',
  'Open Sans': 'Friendly & readable, suits all industries',
  'Lato': 'Elegant & professional, ideal for corporate',
  'Montserrat': 'Bold & geometric, perfect for creative roles',
  'Playfair Display': 'Sophisticated serif, great for executives',
  'Merriweather': 'Classic serif, excellent for academic CVs',
  'Raleway': 'Sleek & thin, modern design aesthetic',
  'Poppins': 'Round & approachable, startup-friendly',
};

TextStyle _resumeFontTextStyle(
  String fontFamily, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  switch (fontFamily) {
    case 'Open Sans':
      return GoogleFonts.openSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Lato':
      return GoogleFonts.lato(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Montserrat':
      return GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Playfair Display':
      return GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Merriweather':
      return GoogleFonts.merriweather(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Raleway':
      return GoogleFonts.raleway(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Poppins':
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    case 'Roboto':
    default:
      return GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
  }
}

/// Available color themes with index → (name, color) mapping.
const kResumeColorThemes = <int, ({String name, Color color})>{
  0: (name: 'Indigo', color: Color(0xFF6366F1)),
  1: (name: 'Emerald', color: Color(0xFF10B981)),
  2: (name: 'Sky Blue', color: Color(0xFF0EA5E9)),
  3: (name: 'Violet', color: Color(0xFF8B5CF6)),
  4: (name: 'Amber', color: Color(0xFFF59E0B)),
  5: (name: 'Pink', color: Color(0xFFEC4899)),
  6: (name: 'Red', color: Color(0xFFEF4444)),
  7: (name: 'Slate', color: Color(0xFF64748B)),
};

/// Available layout styles.
const kResumeLayouts =
    <String, ({String label, String description, IconData icon})>{
  'standard': (
    label: 'Standard',
    description: 'Classic single-column layout',
    icon: Iconsax.document_text,
  ),
  'two_column': (
    label: 'Two Column',
    description: 'Sidebar + main content',
    icon: Iconsax.grid_2,
  ),
  'compact': (
    label: 'Compact',
    description: 'Dense layout, fits more info',
    icon: Iconsax.maximize_3,
  ),
  'modern': (
    label: 'Modern',
    description:
        'Clean, minimal, lots of whitespace, focus on headings and sections.',
    icon: Iconsax.star,
  ),
  'creative': (
    label: 'Creative',
    description:
        'Uses color blocks, icons, or graphics for a visually striking resume.',
    icon: Iconsax.brush_2,
  ),
  'timeline': (
    label: 'Timeline',
    description:
        'Work experience and education shown as a vertical or horizontal timeline.',
    icon: Iconsax.clock,
  ),
  'functional': (
    label: 'Functional',
    description:
        'Focuses on skills and achievements, less on chronological order.',
    icon: Iconsax.briefcase,
  ),
  'infographic': (
    label: 'Infographic',
    description:
        'Uses charts, graphs, and visual elements to represent skills and experience.',
    icon: Iconsax.chart_21,
  ),
  'photo_avatar': (
    label: 'Photo/Avatar',
    description: 'Includes a section for a profile photo or avatar.',
    icon: Iconsax.profile_2user,
  ),
  'left_sidebar': (
    label: 'Left Sidebar',
    description:
        'Sidebar on the left for contact info and skills, main content on the right.',
    icon: Iconsax.sidebar_left,
  ),
  'right_sidebar': (
    label: 'Right Sidebar',
    description:
        'Sidebar on the right for additional info, main content on the left.',
    icon: Iconsax.sidebar_right,
  ),
  'grid': (
    label: 'Grid',
    description:
        'Uses a grid layout for sections, allowing for more modular arrangement.',
    icon: Iconsax.layer,
  ),
  'minimalist': (
    label: 'Minimalist',
    description: 'Ultra-simple, text-focused, no graphics or color.',
    icon: Iconsax.minus_cirlce,
  ),
};

const kResumeLayoutTemplateFamilies =
    <String, ({String defaultTemplateId, List<String> templateIds})>{
  'standard': (
    defaultTemplateId: 'modern',
    templateIds: [
      'modern',
      'classic',
      'creative',
      'minimal',
      'developer',
      'executive',
      'academic',
      'sales',
      'elegant_pink',
      'startup',
      'modern_aesthetic',
      'classic_ats',
      'classic2',
      'education_resume',
      'modern_resume',
      'professional_accountant',
      'one_page_resume',
      'classic_temp',
      'emerald_executive',
      'cool_blue',
      'multicolor',
      'entry_level',
      'ats_optimized_clean',
      'ats_standard_format',
      'ats_friendly_modern',
      'executive_classic',
      'mono_nova',
      'forest_edge',
      'forest_edge_classic',
    ],
  ),
  'two_column': (
    defaultTemplateId: 'two_column',
    templateIds: [
      'two_column',
      'blue_gray',
      'professional',
      'corporate_template',
      'slate_arc',
      'graphite_column',
      'bluewave_tech',
      'balanced_two_column_layout',
      'corporate_navy',
      'professional_tone',
    ],
  ),
  'compact': (
    defaultTemplateId: 'classic2',
    templateIds: [
      'classic2',
      'one_page_resume',
      'classic_temp',
      'ats_optimized_clean',
      'ats_standard_format',
      'ats_friendly_modern',
      'classic_ats',
    ],
  ),
  'modern': (
    defaultTemplateId: 'modern',
    templateIds: [
      'modern',
      'startup',
      'modern_aesthetic',
      'modern_resume',
      'cool_blue',
      'multicolor',
      'emerald_executive',
    ],
  ),
  'creative': (
    defaultTemplateId: 'creative',
    templateIds: [
      'creative',
      'elegant_pink',
      'designer_profile',
      'creative_professional',
      'elegant_design',
    ],
  ),
  'timeline': (
    defaultTemplateId: 'vertical_timeline',
    templateIds: ['vertical_timeline'],
  ),
  'functional': (
    defaultTemplateId: 'professional',
    templateIds: [
      'professional',
      'developer',
      'executive',
      'executive_classic',
      'sales',
      'professional_accountant',
    ],
  ),
  'infographic': (
    defaultTemplateId: 'infographic',
    templateIds: ['infographic'],
  ),
  'photo_avatar': (
    defaultTemplateId: 'modern_edge',
    templateIds: [
      'blue_gray',
      'professional',
      'vertical_timeline',
      'corporate_template',
      'slate_arc',
      'editorial_frame',
      'graphite_column',
      'rosewood_panel',
      'designer_profile',
      'modern_edge',
      'professional_tone',
      'elegant_design',
      'creative_professional',
      'bluewave_tech',
      'balanced_two_column_layout',
      'elegant_gold_layout',
      'corporate_navy',
    ],
  ),
  'left_sidebar': (
    defaultTemplateId: 'two_column',
    templateIds: [
      'two_column',
      'blue_gray',
      'corporate_template',
      'slate_arc',
      'bluewave_tech',
      'balanced_two_column_layout',
      'corporate_navy',
      'professional_tone',
    ],
  ),
  'right_sidebar': (
    defaultTemplateId: 'graphite_column',
    templateIds: ['graphite_column', 'forest_edge_classic'],
  ),
  'grid': (
    defaultTemplateId: 'startup',
    templateIds: ['startup', 'blue_gray', 'infographic', 'forest_edge'],
  ),
  'minimalist': (
    defaultTemplateId: 'minimal',
    templateIds: [
      'minimal',
      'mono_nova',
      'academic',
      'ats_standard_format',
      'ats_optimized_clean',
      'classic_temp',
    ],
  ),
};

String resolveTemplateForLayoutStyle({
  required String layoutStyle,
  required String currentTemplateId,
}) {
  final config = kResumeLayoutTemplateFamilies[layoutStyle];
  if (config == null) {
    return currentTemplateId;
  }

  if (config.templateIds.contains(currentTemplateId)) {
    return currentTemplateId;
  }

  return config.defaultTemplateId;
}

String previewTemplateForLayoutStyle({
  required String layoutStyle,
  required String currentLayout,
  required String currentTemplateId,
}) {
  final config = kResumeLayoutTemplateFamilies[layoutStyle];
  if (config == null) {
    return currentTemplateId.isNotEmpty ? currentTemplateId : 'modern';
  }

  if (layoutStyle == currentLayout &&
      config.templateIds.contains(currentTemplateId)) {
    return currentTemplateId;
  }

  return config.defaultTemplateId;
}

Color _layoutPreviewAccentColor(ResumeModel resume) {
  return kResumeColorThemes[resume.colorScheme]?.color ?? AppColors.primary;
}

Widget _buildLayoutThumbnail({
  required String layoutId,
  required bool selected,
  required ResumeModel resume,
}) {
  final previewTemplateId = previewTemplateForLayoutStyle(
    layoutStyle: layoutId,
    currentLayout: resume.layoutStyle,
    currentTemplateId: resume.templateId,
  );

  return AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: selected
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      border: Border.all(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.2)
            : Colors.grey.shade200,
      ),
    ),
    child: TemplatePreviewThumbnail(
      templateId: previewTemplateId,
      accentColor: _layoutPreviewAccentColor(resume),
      width: 58,
      showShadow: false,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
  );
}

/// Shows a bottom sheet for selecting the resume font family.
void showFontPicker({
  required BuildContext context,
  required String currentFont,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Iconsax.text, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Font Family',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose a font for your resume PDF',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: kResumeFonts.length,
                itemBuilder: (_, i) {
                  final entry = kResumeFonts.entries.elementAt(i);
                  final selected = entry.key == currentFont;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                          child: Text('Aa',
                            style: _resumeFontTextStyle(entry.key,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary))),
                    ),
                    title: Text(entry.key,
                        style: _resumeFontTextStyle(entry.key,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Text(entry.value,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    trailing: selected
                        ? const Icon(Iconsax.tick_circle,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      onSelected(entry.key);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows a bottom sheet for selecting the resume color theme.
void showColorThemePicker({
  required BuildContext context,
  required int currentScheme,
  required ValueChanged<int> onSelected,
  Set<int>? allowedSchemes,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Iconsax.colorfilter,
                  size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Color Theme',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pick an accent color for your resume',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kResumeColorThemes.entries
                .where((e) =>
                    allowedSchemes == null || allowedSchemes.contains(e.key))
                .map((e) {
              final selected = e.key == currentScheme;
              return GestureDetector(
                onTap: () {
                  onSelected(e.key);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: e.value.color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: AppColors.textPrimary, width: 3)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: e.value.color.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(e.value.name,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

/// Shows a bottom sheet for selecting the resume layout style.
void showLayoutPicker({
  required BuildContext context,
  required String currentLayout,
  required ResumeModel resume,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Iconsax.grid_1, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Layout Style',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how your resume content is arranged',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: kResumeLayouts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final entry = kResumeLayouts.entries.elementAt(i);
                    final selected = entry.key == currentLayout;
                    return InkWell(
                      onTap: () {
                        onSelected(entry.key);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.10)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLayoutThumbnail(
                              layoutId: entry.key,
                              selected: selected,
                              resume: resume,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        entry.value.icon,
                                        color: selected
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: selected
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (selected)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Iconsax.tick_circle,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
