import 'package:flutter/material.dart';
import 'premium_service.dart';

class TemplateService {
  static const Map<String, TemplateInfo> _templates = {
    'Classic': TemplateInfo(
      name: 'Classic',
      isPremium: false,
      description: 'Traditional resume format perfect for corporate roles',
      features: [
        'Clean, professional layout',
        'ATS-friendly format',
        'Standard sections',
        'Easy to customize',
      ],
      bestFor: ['Corporate jobs', 'Finance', 'Government', 'Healthcare'],
      previewImage: 'assets/templates/classic_preview.png',
      category: TemplateCategory.professional,
    ),
    'Minimal': TemplateInfo(
      name: 'Minimal',
      isPremium: false,
      description: 'Clean and simple design that highlights your content',
      features: [
        'Minimalist design',
        'Focus on content',
        'Modern typography',
        'Spacious layout',
      ],
      bestFor: ['Tech', 'Design', 'Startups', 'Freelancers'],
      previewImage: 'assets/templates/minimal_preview.png',
      category: TemplateCategory.modern,
    ),
    'Modern': TemplateInfo(
      name: 'Modern',
      isPremium: true,
      description: 'Contemporary design with subtle color accents',
      features: [
        'Color customization',
        'Modern typography',
        'Visual hierarchy',
        'Custom sections',
      ],
      bestFor: ['Marketing', 'Sales', 'Tech', 'Creative'],
      previewImage: 'assets/templates/modern_preview.png',
      category: TemplateCategory.modern,
    ),
    'Professional': TemplateInfo(
      name: 'Professional',
      isPremium: true,
      description: 'Executive-level template for senior positions',
      features: [
        'Executive summary section',
        'Skills matrix',
        'Achievement highlights',
        'Professional styling',
      ],
      bestFor: ['Executive', 'Management', 'Consulting', 'Legal'],
      previewImage: 'assets/templates/professional_preview.png',
      category: TemplateCategory.executive,
    ),
    'Creative': TemplateInfo(
      name: 'Creative',
      isPremium: true,
      description: 'Bold design for creative professionals',
      features: [
        'Unique layout',
        'Portfolio integration',
        'Color themes',
        'Creative sections',
      ],
      bestFor: ['Design', 'Art', 'Photography', 'Media'],
      previewImage: 'assets/templates/creative_preview.png',
      category: TemplateCategory.creative,
    ),
    'OnePage': TemplateInfo(
      name: 'One Page',
      isPremium: true,
      description: 'Compact format that fits everything on one page',
      features: [
        'Optimized layout',
        'Compact sections',
        'Quick overview',
        'Space efficient',
      ],
      bestFor: ['Entry-level', 'Internships', 'Quick applications'],
      previewImage: 'assets/templates/onepage_preview.png',
      category: TemplateCategory.compact,
    ),
  };

  // Get all available templates based on user's premium status
  static List<TemplateInfo> getAvailableTemplates() {
    if (PremiumService.isPremium) {
      return _templates.values.toList();
    }
    return _templates.values.where((t) => !t.isPremium).toList();
  }

  // Get premium templates only
  static List<TemplateInfo> getPremiumTemplates() {
    return _templates.values.where((t) => t.isPremium).toList();
  }

  // Get free templates only
  static List<TemplateInfo> getFreeTemplates() {
    return _templates.values.where((t) => !t.isPremium).toList();
  }

  // Get template by name
  static TemplateInfo? getTemplate(String name) {
    return _templates[name];
  }

  // Check if user can access template
  static bool canAccessTemplate(String name) {
    final template = _templates[name];
    if (template == null) return false;
    return !template.isPremium || PremiumService.isPremium;
  }

  // Get templates by category
  static List<TemplateInfo> getTemplatesByCategory(TemplateCategory category) {
    return _templates.values.where((t) => t.category == category).toList();
  }

  // Get premium features for template
  static List<String> getPremiumFeatures() {
    return [
      'Access to all 6 professional templates',
      'Color customization for all templates',
      'Font selection (10+ professional fonts)',
      'Custom section ordering',
      'Logo upload and branding',
      'Unlimited template switching',
      'Export without watermarks',
      'Multiple file formats (PDF, DOCX, TXT)',
      'Cloud sync across devices',
      'Priority customer support',
    ];
  }
}

class TemplateInfo {
  final String name;
  final bool isPremium;
  final String description;
  final List<String> features;
  final List<String> bestFor;
  final String previewImage;
  final TemplateCategory category;

  const TemplateInfo({
    required this.name,
    required this.isPremium,
    required this.description,
    required this.features,
    required this.bestFor,
    required this.previewImage,
    required this.category,
  });

  Widget getPremiumBadge() {
    if (!isPremium) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color getCategoryColor() {
    switch (category) {
      case TemplateCategory.professional:
        return Colors.blue;
      case TemplateCategory.modern:
        return Colors.green;
      case TemplateCategory.creative:
        return Colors.orange;
      case TemplateCategory.executive:
        return Colors.purple;
      case TemplateCategory.compact:
        return Colors.teal;
    }
  }
}

enum TemplateCategory { professional, modern, creative, executive, compact }

extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.professional:
        return 'Professional';
      case TemplateCategory.modern:
        return 'Modern';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.executive:
        return 'Executive';
      case TemplateCategory.compact:
        return 'Compact';
    }
  }
}
