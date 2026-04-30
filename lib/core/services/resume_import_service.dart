import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImportedResumeFile {
  const ImportedResumeFile({
    required this.fileName,
    required this.extractedText,
  });

  final String fileName;
  final String extractedText;
}

class ResumeImportException implements Exception {
  ResumeImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResumeImportService {
  static const XTypeGroup _resumeFiles = XTypeGroup(
    label: 'Resume Files',
    extensions: <String>['txt', 'text', 'md', 'rtf', 'docx', 'pdf'],
  );

  static Future<ImportedResumeFile?> pickResumeFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_resumeFiles],
      confirmButtonText: 'Select Resume',
    );
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final extractedText = extractTextFromBytes(
      bytes: bytes,
      fileName: file.name,
    );

    return ImportedResumeFile(
      fileName: file.name,
      extractedText: extractedText,
    );
  }

  static String extractTextFromBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final extension = _extensionOf(fileName);

    final extractedText = switch (extension) {
      'txt' || 'text' || 'md' => _decodePlainText(bytes),
      'rtf' => _extractRtfText(bytes),
      'docx' => _extractDocxText(bytes),
      'pdf' => _extractPdfText(bytes),
      _ => throw ResumeImportException(
          'Unsupported file type .$extension. Please select a TXT, RTF, DOCX, or PDF resume.',
        ),
    };

    final normalizedText = _normalizeExtractedText(extractedText);
    if (normalizedText.length < 50) {
      throw ResumeImportException(
        'The selected file did not contain enough readable resume text. Try another file or paste the resume content directly.',
      );
    }

    return normalizedText;
  }

  static String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static String _decodePlainText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static String _extractRtfText(Uint8List bytes) {
    var text = _decodePlainText(bytes);
    text = text
        .replaceAll(RegExp(r'\\par[d]?'), '\n')
        .replaceAll(RegExp(r'\\tab'), '\t')
        .replaceAll(RegExp(r"\\[a-zA-Z]+-?\d* ?"), ' ')
        .replaceAll(RegExp(r'[{}]'), ' ');
    return _decodeXmlEntities(text);
  }

  static String _extractDocxText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw ResumeImportException(
        'This DOCX file could not be read. Please try another file or paste the resume text directly.',
      );
    }

    final content = documentFile.content;
    final xmlBytes = content is List<int> ? content : Uint8List.fromList(<int>[]);
    if (xmlBytes.isEmpty) {
      throw ResumeImportException(
        'This DOCX file did not contain readable document text.',
      );
    }

    var text = utf8.decode(xmlBytes, allowMalformed: true);
    text = text
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
        .replaceAll(RegExp(r'<w:br[^>]*/>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeXmlEntities(text);
  }

  static String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } catch (_) {
      throw ResumeImportException(
        'This PDF could not be read. If it is image-only, paste the resume text directly instead.',
      );
    } finally {
      document.dispose();
    }
  }

  static String _decodeXmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final codePoint = int.tryParse(match.group(1) ?? '');
          return codePoint == null ? ' ' : String.fromCharCode(codePoint);
        });
  }

  static String _normalizeExtractedText(String value) {
    return value
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[\t\f\v]+'), ' ')
        .replaceAll(RegExp(r'\u00A0'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }
}