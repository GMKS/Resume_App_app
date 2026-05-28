import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

import '../../../core/models/resume_model.dart';
import 'preview_pdf_service.dart';

class PreviewImageService {
  static const double _defaultDpi = 144;

  static Future<Uint8List> generateBytes(
    ResumeModel resume, {
    double dpi = _defaultDpi,
  }) async {
    final pdfBytes = await PreviewPdfService.generateBytes(resume);
    return generateFromPdfBytes(pdfBytes, dpi: dpi);
  }

  static Future<Uint8List> generateFromPdfBytes(
    Uint8List pdfBytes, {
    double dpi = _defaultDpi,
  }) async {
    final pages = await generatePagesFromPdfBytes(
      pdfBytes,
      dpi: dpi,
      pages: const <int>[0],
    );

    return pages.first;
  }

  static Future<List<Uint8List>> generatePages(
    ResumeModel resume, {
    double dpi = _defaultDpi,
    List<int>? pages,
  }) async {
    final pdfBytes = await PreviewPdfService.generateBytes(resume);
    return generatePagesFromPdfBytes(
      pdfBytes,
      dpi: dpi,
      pages: pages,
    );
  }

  static Future<List<Uint8List>> generatePagesFromPdfBytes(
    Uint8List pdfBytes, {
    double dpi = _defaultDpi,
    List<int>? pages,
  }) async {
    final rasterPages = Printing.raster(
      pdfBytes,
      pages: pages,
      dpi: dpi,
    );

    final imageBytes = <Uint8List>[];
    await for (final rasterPage in rasterPages) {
      final pngBytes = await rasterPage.toPng();
      imageBytes.add(_normalizeRasterPage(pngBytes));
    }

    return imageBytes;
  }

  static Uint8List _normalizeRasterPage(Uint8List pngBytes) {
    final decodedPage = img.decodeImage(pngBytes);
    if (decodedPage == null) {
      throw StateError(
          'A rasterized PDF page could not be decoded as PNG data.');
    }

    final normalizedPage = img.Image(
      width: decodedPage.width,
      height: decodedPage.height,
      numChannels: 4,
    );
    img.fill(
      normalizedPage,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
    img.compositeImage(
      normalizedPage,
      decodedPage,
      dstX: 0,
      dstY: 0,
    );

    return Uint8List.fromList(img.encodePng(normalizedPage));
  }
}
