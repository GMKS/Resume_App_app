import 'storage_service.dart';

class FreePlanService {
  static const int maxTrialResumes = 1;
  static const int maxTrialPdfExports = 1;
  static const int maxAiSuggestions = 5;
  static const int trialDays = 3;

  static const String _trialStartedAtKey = 'trial_started_at';

  static const Set<String> basicTemplateIds = {
    'classic',
    'minimal',
    'classic2',
  };

  static const Set<String> freeEditableSectionKeys = {
    'personal',
    'summary',
    'education',
    'experience',
    'skills',
    'custom_sections',
  };

  static const Set<int> freeColorSchemeIds = {0, 7};

  static const Set<String> freeAiToolKeys = {
    'content_enhancer',
    'summary_generator',
    'bullet_generator',
  };

    static const String recommendedUpgradeMessage =
      'Unlock premium templates, unlimited resumes, and watermark-free exports.';

  static const String resumeLimitMessage =
      'Your starter access includes 1 resume. Upgrade to create and manage multiple resumes.';
  static const String premiumTemplateMessage =
      recommendedUpgradeMessage;
  static const String premiumSectionMessage =
      'Premium feature. Upgrade to edit this section.';
  static const String exportLimitMessage =
      recommendedUpgradeMessage;
  static const String trialExportUsedMessage =
      recommendedUpgradeMessage;
  static const String advancedExportMessage =
      'Print, email, and full PDF sharing are premium features.';
  static const String premiumDocxMessage =
      'DOCX export is available on premium plans only.';
  static const String premiumTxtMessage =
      'TXT export is available on premium plans only.';
  static const String aiLimitMessage =
      recommendedUpgradeMessage;
  static const String premiumAiToolMessage =
      recommendedUpgradeMessage;
  static const String premiumFontMessage =
      'Custom fonts are a premium feature.';
  static const String premiumLayoutMessage =
      'Advanced layouts and section positioning are premium features.';
  static const String premiumColorMessage =
      'Premium color palettes are locked on the free plan.';
  static const String premiumCloudSyncMessage =
      'Cloud sync and multi-device access are available on premium plans only.';
  static const String premiumPhotoMessage =
      'Photo upload is a premium feature.';
  static const String premiumSupportMessage =
      'Priority support is available on premium plans only.';

  static bool get isPremium => StorageService.isPremiumUser();

  static DateTime get trialStartedAt {
    final stored = StorageService.prefs.getInt(_trialStartedAtKey);
    if (stored != null) {
      return DateTime.fromMillisecondsSinceEpoch(stored);
    }
    final now = DateTime.now();
    StorageService.prefs.setInt(_trialStartedAtKey, now.millisecondsSinceEpoch);
    return now;
  }

  static DateTime get trialEndsAt =>
      trialStartedAt.add(const Duration(days: trialDays));

  static bool get isTrialActive => isPremium || DateTime.now().isBefore(trialEndsAt);

  static bool get isTrialExpired => !isPremium && !isTrialActive;

  static int get remainingTrialDays {
    if (isPremium) return 999999;
    final difference = trialEndsAt.difference(DateTime.now());
    if (difference.isNegative) return 0;
    final days = difference.inDays;
    return difference.inHours % 24 == 0 ? days : days + 1;
  }

  static String get trialStatusMessage {
    if (isPremium) {
      return 'Premium active';
    }
    if (isTrialExpired) {
      return 'Trial expired';
    }
    final days = remainingTrialDays;
    return days == 1 ? '1 day trial left' : '$days days trial left';
  }

  static bool canCreateResume({int? currentResumeCount}) {
    if (isPremium) return true;
    final count = currentResumeCount ?? StorageService.getAllResumes().length;
    return count < maxTrialResumes;
  }

  static bool isTemplateLocked(String templateId) {
    return !isPremium && !basicTemplateIds.contains(templateId);
  }

  static bool isPremiumTemplate(String templateId) {
    return !basicTemplateIds.contains(templateId);
  }

  static bool canExportResumeTemplate(String templateId) {
    if (isPremium) return true;
    return !isPremiumTemplate(templateId);
  }

  static String exportMessageForTemplate(String templateId) {
    if (!isPremium && isPremiumTemplate(templateId)) {
      return recommendedUpgradeMessage;
    }
    return currentExportMessage;
  }

  static bool canEditSection(String sectionKey) {
    return isPremium || freeEditableSectionKeys.contains(sectionKey);
  }

  static bool canUseColorScheme(int colorSchemeId) {
    return isPremium || freeColorSchemeIds.contains(colorSchemeId);
  }

  static bool get canCustomizeFonts => isPremium;

  static bool get canCustomizeLayouts => isPremium;

  static bool get canReorderSections => isPremium;

  static bool get canUseCloudSync => isPremium;

  static bool get canUploadPhoto => isPremium;

  static bool get canExportDocx => isPremium;

  static bool get canExportTxt => isPremium;

  static bool get hasPrioritySupport => isPremium;

  static bool get shouldShowWatermark => !isPremium;

  static int get pdfExportCount =>
      StorageService.prefs.getInt('free_plan_pdf_exports') ?? 0;

  static int get remainingPdfExports =>
      isPremium
          ? 999999
          : (maxTrialPdfExports - pdfExportCount)
              .clamp(0, maxTrialPdfExports);

  static bool get canExportPdf =>
      isPremium || (isTrialActive && pdfExportCount < maxTrialPdfExports);

  static String get currentExportMessage {
    if (isPremium) {
      return 'Unlimited PDF exports available.';
    }
    if (isTrialExpired) {
      return exportLimitMessage;
    }
    if (pdfExportCount >= maxTrialPdfExports) {
      return trialExportUsedMessage;
    }
    return '$remainingPdfExports trial PDF export left';
  }

  static Future<void> recordPdfExport() async {
    if (isPremium) return;
    await StorageService.prefs
        .setInt('free_plan_pdf_exports', pdfExportCount + 1);
  }

  static int get aiSuggestionCount =>
      StorageService.prefs.getInt('free_plan_ai_uses') ?? 0;

  static int get remainingAiSuggestions => isPremium
      ? 999999
      : (maxAiSuggestions - aiSuggestionCount).clamp(0, maxAiSuggestions);

  static bool canAccessAiTool(String toolKey) {
    return isPremium || freeAiToolKeys.contains(toolKey);
  }

  static bool get canUseAiSuggestion =>
      isPremium || aiSuggestionCount < maxAiSuggestions;

  static Future<bool> consumeAiSuggestion() async {
    if (isPremium) return true;
    if (!canUseAiSuggestion) return false;
    await StorageService.prefs
        .setInt('free_plan_ai_uses', aiSuggestionCount + 1);
    return true;
  }
}