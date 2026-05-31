import 'dart:typed_data';
import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import '../../../core/constants/app_info.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
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

  static Future<Uint8List> generatePreviewBytes(ResumeModel resume) async {
    final pdf = await generateDocument(resume);
    return pdf.save();
  }

  static Future<Uint8List> generateBytes(ResumeModel resume) async {
    final bytes = await generatePreviewBytes(resume);
    if (!FreePlanService.shouldShowWatermark) {
      return bytes;
    }

    return _applyFreePlanWatermark(bytes);
  }

  static Uint8List _applyFreePlanWatermark(Uint8List pdfBytes) {
    final document = sfpdf.PdfDocument(inputBytes: pdfBytes);
    final font = sfpdf.PdfStandardFont(
      sfpdf.PdfFontFamily.helvetica,
      34,
      style: sfpdf.PdfFontStyle.bold,
    );
    final brush = sfpdf.PdfSolidBrush(sfpdf.PdfColor(90, 90, 90));
    final format = sfpdf.PdfStringFormat(
      alignment: sfpdf.PdfTextAlignment.center,
      lineAlignment: sfpdf.PdfVerticalAlignment.middle,
    );
    const watermarkText =
        'Generated with ${AppInfo.appName}\nUpgrade to remove watermark';

    for (var index = 0; index < document.pages.count; index++) {
      final page = document.pages[index];
      final graphics = page.graphics;
      final size = page.size;
      final state = graphics.save();

      graphics.setTransparency(0.12);
      graphics.translateTransform(size.width / 2, size.height / 2);
      graphics.rotateTransform(-28);
      graphics.drawString(
        watermarkText,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(-size.width / 2, -48, size.width, 96),
        format: format,
      );
      graphics.restore(state);
    }

    final watermarked = Uint8List.fromList(document.saveSync());
    document.dispose();
    return watermarked;
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
