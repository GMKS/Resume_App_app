// Feature name constants
class SubscriptionFeatures {
  static const String createResume = 'create_resume';
  static const String basicTemplates = 'basic_templates';
  static const String allTemplates = 'all_templates';
  static const String exportPdf = 'export_pdf';
  static const String exportDocx = 'export_docx';
  static const String exportTxt = 'export_txt';
  static const String aiAssistant = 'ai_assistant';
  static const String atsOptimization = 'ats_optimization';
  static const String coverLetterGenerator = 'cover_letter';
  static const String jobTracker = 'job_tracker';
  static const String portfolio = 'portfolio';
  static const String unlimitedExports = 'unlimited_exports';
  static const String prioritySupport = 'priority_support';
  static const String interviewPrep = 'interview_prep';
  static const String skillAnalyzer = 'skill_analyzer';
  static const String careerPath = 'career_path';
  static const String premiumSections = 'premium_sections';
  static const String mediaSupport = 'media_support';
  static const String signatureSupport = 'signature_support';
  static const String cloudSync = 'cloud_sync';
}

enum SubscriptionPlan {
  free,
  weekly,
  monthly,
  quarterly,
  yearly,
}

class SubscriptionModel {
  final SubscriptionPlan plan;
  final DateTime? expiryDate;
  final bool isActive;
  final List<String> features;

  const SubscriptionModel({
    required this.plan,
    this.expiryDate,
    required this.isActive,
    required this.features,
  });

  bool hasFeature(String featureName) {
    return features.contains(featureName);
  }

  bool isPremium() {
    return plan != SubscriptionPlan.free;
  }

  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      plan: SubscriptionPlan.free,
      isActive: true,
      features: [
        'create_resume',
        'basic_templates',
        'export_pdf',
        'ai_assistant',
      ],
    );
  }

  factory SubscriptionModel.weekly() {
    return SubscriptionModel(
      plan: SubscriptionPlan.weekly,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      features: [
        SubscriptionFeatures.createResume,
        SubscriptionFeatures.allTemplates,
        SubscriptionFeatures.exportPdf,
        SubscriptionFeatures.exportDocx,
        SubscriptionFeatures.exportTxt,
        SubscriptionFeatures.aiAssistant,
        SubscriptionFeatures.atsOptimization,
        SubscriptionFeatures.coverLetterGenerator,
        SubscriptionFeatures.jobTracker,
        SubscriptionFeatures.portfolio,
        SubscriptionFeatures.unlimitedExports,
        SubscriptionFeatures.premiumSections,
        SubscriptionFeatures.mediaSupport,
        SubscriptionFeatures.signatureSupport,
        SubscriptionFeatures.cloudSync,
        SubscriptionFeatures.prioritySupport,
        SubscriptionFeatures.interviewPrep,
        SubscriptionFeatures.skillAnalyzer,
        SubscriptionFeatures.careerPath,
      ],
    );
  }

  factory SubscriptionModel.monthly() {
    return SubscriptionModel(
      plan: SubscriptionPlan.monthly,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      features: [
        SubscriptionFeatures.createResume,
        SubscriptionFeatures.allTemplates,
        SubscriptionFeatures.exportPdf,
        SubscriptionFeatures.exportDocx,
        SubscriptionFeatures.exportTxt,
        SubscriptionFeatures.aiAssistant,
        SubscriptionFeatures.atsOptimization,
        SubscriptionFeatures.coverLetterGenerator,
        SubscriptionFeatures.jobTracker,
        SubscriptionFeatures.portfolio,
        SubscriptionFeatures.unlimitedExports,
        SubscriptionFeatures.premiumSections,
        SubscriptionFeatures.mediaSupport,
        SubscriptionFeatures.signatureSupport,
        SubscriptionFeatures.cloudSync,
        SubscriptionFeatures.prioritySupport,
        SubscriptionFeatures.interviewPrep,
        SubscriptionFeatures.skillAnalyzer,
        SubscriptionFeatures.careerPath,
      ],
    );
  }

  factory SubscriptionModel.quarterly() {
    return SubscriptionModel(
      plan: SubscriptionPlan.quarterly,
      expiryDate: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
      features: [
        SubscriptionFeatures.createResume,
        SubscriptionFeatures.allTemplates,
        SubscriptionFeatures.exportPdf,
        SubscriptionFeatures.exportDocx,
        SubscriptionFeatures.exportTxt,
        SubscriptionFeatures.aiAssistant,
        SubscriptionFeatures.atsOptimization,
        SubscriptionFeatures.coverLetterGenerator,
        SubscriptionFeatures.jobTracker,
        SubscriptionFeatures.portfolio,
        SubscriptionFeatures.unlimitedExports,
        SubscriptionFeatures.prioritySupport,
        SubscriptionFeatures.premiumSections,
        SubscriptionFeatures.mediaSupport,
        SubscriptionFeatures.signatureSupport,
        SubscriptionFeatures.cloudSync,
        SubscriptionFeatures.interviewPrep,
        SubscriptionFeatures.skillAnalyzer,
        SubscriptionFeatures.careerPath,
      ],
    );
  }

  factory SubscriptionModel.yearly() {
    return SubscriptionModel(
      plan: SubscriptionPlan.yearly,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      isActive: true,
      features: [
        SubscriptionFeatures.createResume,
        SubscriptionFeatures.allTemplates,
        SubscriptionFeatures.exportPdf,
        SubscriptionFeatures.exportDocx,
        SubscriptionFeatures.exportTxt,
        SubscriptionFeatures.aiAssistant,
        SubscriptionFeatures.atsOptimization,
        SubscriptionFeatures.coverLetterGenerator,
        SubscriptionFeatures.jobTracker,
        SubscriptionFeatures.portfolio,
        SubscriptionFeatures.unlimitedExports,
        SubscriptionFeatures.prioritySupport,
        SubscriptionFeatures.premiumSections,
        SubscriptionFeatures.mediaSupport,
        SubscriptionFeatures.signatureSupport,
        SubscriptionFeatures.cloudSync,
        SubscriptionFeatures.interviewPrep,
        SubscriptionFeatures.skillAnalyzer,
        SubscriptionFeatures.careerPath,
      ],
    );
  }

  String get displayName {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.weekly:
        return 'Weekly Pro';
      case SubscriptionPlan.monthly:
        return 'Monthly Pro';
      case SubscriptionPlan.quarterly:
        return 'Quarterly Pro';
      case SubscriptionPlan.yearly:
        return 'Yearly Pro';
    }
  }

  String get price {
    switch (plan) {
      case SubscriptionPlan.free:
        return '\$0';
      case SubscriptionPlan.weekly:
        return '\$4.99/week';
      case SubscriptionPlan.monthly:
        return '\$9.99/month';
      case SubscriptionPlan.quarterly:
        return '\$24.99/quarter';
      case SubscriptionPlan.yearly:
        return '\$79.99/year';
    }
  }
}
