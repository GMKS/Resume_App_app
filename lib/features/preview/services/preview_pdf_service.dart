import 'dart:typed_data';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/resume_model.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/utils/resume_translations.dart';
import '../widgets/pdf_templates.dart';

class PreviewPdfService {
  static Future<pw.Document> generateDocument(ResumeModel resume) async {
    final accentColor = accentColorForScheme(resume.colorScheme);
    var resumeToUse = resume;
    if (resume.writingLanguage != 'English') {
      resumeToUse = await TranslationService.translateResume(
        resume,
        resume.writingLanguage,
      );
    }

    final previousLocale = Intl.defaultLocale;
    final targetLocale =
        ResumeTranslations.dateLocale(resumeToUse.writingLanguage);

    try {
      await initializeDateFormatting(targetLocale);
      Intl.defaultLocale = targetLocale;
      await initPdfSettings(resumeToUse);
      final template = PdfTemplateFactory.getTemplate(resumeToUse.templateId);
      return await template.generate(resumeToUse, accentColor);
    } finally {
      Intl.defaultLocale = previousLocale;
    }
  }

  static Future<Uint8List> generateBytes(ResumeModel resume) async {
    final pdf = await generateDocument(resume);
    return pdf.save();
  }

  static PdfColor accentColorForScheme(int colorScheme) {
    switch (colorScheme) {
      case 0:
        return PdfColor.fromHex('#6366F1');
      case 1:
        return PdfColor.fromHex('#10B981');
      case 2:
        return PdfColor.fromHex('#0EA5E9');
      case 3:
        return PdfColor.fromHex('#8B5CF6');
      case 4:
        return PdfColor.fromHex('#F59E0B');
      case 5:
        return PdfColor.fromHex('#EC4899');
      case 6:
        return PdfColor.fromHex('#EF4444');
      case 7:
        return PdfColor.fromHex('#64748B');
      default:
        return PdfColor.fromHex('#6366F1');
    }
  }
}