import 'dart:io';
import 'dart:convert';
import '../models/saved_resume.dart';

/// Minimal export service shim to unblock builds.
/// Generates temporary files for DOCX/TXT/PDF without external packages.
class ShareExportService {
  ShareExportService._();
  static final ShareExportService instance = ShareExportService._();

  /// Create a fake PDF file for preview/open in apps that support it.
  Future<File> exportAndOpenPdf(SavedResume resume) async {
    final file = await _writeTempFile(
      resume,
      extension: 'pdf',
      header: '%PDF-FAKE%\n',
    );
    // No-op: Opening/sharing handled by UI in future; return file for convenience.
    return file;
  }

  /// Create a fake DOCX file (really just text content with .docx extension).
  Future<File> exportDoc(SavedResume resume) async {
    return _writeTempFile(
      resume,
      extension: 'docx',
      header: 'DOCX (placeholder)\n',
    );
  }

  /// Create a TXT export with plain-text representation.
  Future<File> exportTxt(SavedResume resume) async {
    return _writeTempFile(resume, extension: 'txt', header: 'TXT Export\n');
  }

  Future<File> _writeTempFile(
    SavedResume resume, {
    required String extension,
    String header = '',
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${_sanitize(resume.title)}_$ts.$extension';
    final file = File('${Directory.systemTemp.path}/$fileName');
    final content = StringBuffer()
      ..writeln(header)
      ..writeln('Title: ${resume.title}')
      ..writeln('Template: ${resume.template}')
      ..writeln('Created: ${resume.createdAt.toIso8601String()}')
      ..writeln('Updated: ${resume.updatedAt.toIso8601String()}')
      ..writeln('--- Data ---')
      ..writeln(const JsonEncoder.withIndent('  ').convert(resume.data));
    await file.writeAsString(content.toString());
    return file;
  }

  String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_').trim();
  }
}
