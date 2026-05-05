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

enum BillingProvider {
  local,
  googlePlay,
}

class SubscriptionModel {
  final SubscriptionPlan plan;
  final DateTime? expiryDate;
  final bool isActive;
  final List<String> features;
  final bool cancelAtPeriodEnd;
  final BillingProvider billingProvider;

  static const List<String> _freeFeatures = <String>[
    SubscriptionFeatures.createResume,
    SubscriptionFeatures.basicTemplates,
    SubscriptionFeatures.exportPdf,
    SubscriptionFeatures.aiAssistant,
  ];

  static const List<String> _premiumFeatures = <String>[
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
    SubscriptionFeatures.interviewPrep,
    SubscriptionFeatures.skillAnalyzer,
    SubscriptionFeatures.careerPath,
    SubscriptionFeatures.premiumSections,
    SubscriptionFeatures.mediaSupport,
    SubscriptionFeatures.signatureSupport,
    SubscriptionFeatures.cloudSync,
  ];

  const SubscriptionModel({
    required this.plan,
    this.expiryDate,
    required this.isActive,
    required this.features,
    this.cancelAtPeriodEnd = false,
    this.billingProvider = BillingProvider.local,
  });

  bool hasFeature(String featureName) {
    return features.contains(featureName);
  }

  bool isPremium() {
    return plan != SubscriptionPlan.free;
  }

  bool get isStoreManaged => billingProvider != BillingProvider.local;

  static SubscriptionModel forPlan(
    SubscriptionPlan plan, {
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return SubscriptionModel.weekly(
          expiryDate: expiryDate,
          cancelAtPeriodEnd: cancelAtPeriodEnd,
          billingProvider: billingProvider,
        );
      case SubscriptionPlan.monthly:
        return SubscriptionModel.monthly(
          expiryDate: expiryDate,
          cancelAtPeriodEnd: cancelAtPeriodEnd,
          billingProvider: billingProvider,
        );
      case SubscriptionPlan.quarterly:
        return SubscriptionModel.quarterly(
          expiryDate: expiryDate,
          cancelAtPeriodEnd: cancelAtPeriodEnd,
          billingProvider: billingProvider,
        );
      case SubscriptionPlan.yearly:
        return SubscriptionModel.yearly(
          expiryDate: expiryDate,
          cancelAtPeriodEnd: cancelAtPeriodEnd,
          billingProvider: billingProvider,
        );
      case SubscriptionPlan.free:
        return SubscriptionModel.free();
    }
  }

  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      plan: SubscriptionPlan.free,
      isActive: true,
      features: _freeFeatures,
    );
  }

  factory SubscriptionModel.weekly({
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    return SubscriptionModel(
      plan: SubscriptionPlan.weekly,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      features: _premiumFeatures,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
    );
  }

  factory SubscriptionModel.monthly({
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    return SubscriptionModel(
      plan: SubscriptionPlan.monthly,
      expiryDate: expiryDate ??
          (billingProvider == BillingProvider.googlePlay
              ? null
              : DateTime.now().add(const Duration(days: 30))),
      isActive: true,
      features: _premiumFeatures,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
    );
  }

  factory SubscriptionModel.quarterly({
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    return SubscriptionModel(
      plan: SubscriptionPlan.quarterly,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 90)),
      isActive: true,
      features: _premiumFeatures,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
    );
  }

  factory SubscriptionModel.yearly({
    DateTime? expiryDate,
    bool cancelAtPeriodEnd = false,
    BillingProvider billingProvider = BillingProvider.local,
  }) {
    return SubscriptionModel(
      plan: SubscriptionPlan.yearly,
      expiryDate: expiryDate ??
          (billingProvider == BillingProvider.googlePlay
              ? null
              : DateTime.now().add(const Duration(days: 365))),
      isActive: true,
      features: _premiumFeatures,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      billingProvider: billingProvider,
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
        return '\$3.99/week';
      case SubscriptionPlan.monthly:
        return '\$12.99/month';
      case SubscriptionPlan.quarterly:
        return '\$29.99/3 months';
      case SubscriptionPlan.yearly:
        return '\$59.99/year';
    }
  }
}
