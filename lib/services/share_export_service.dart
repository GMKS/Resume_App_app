import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/saved_resume.dart';
import 'pdf_exporter.dart';
import 'word_exporter.dart';
import 'resume_renderer.dart';

class ShareExportService {
  ShareExportService._();
  static final ShareExportService instance = ShareExportService._();

  Future<File> _writeTemp(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> exportPdf(SavedResume r) async {
    final bytes = await generatePdf(r);
    return _writeTemp('${r.title.replaceAll(' ', '_')}.pdf', bytes);
  }

  Future<File> exportDoc(SavedResume r) async {
    final bytes = await generateDoc(r);
    return _writeTemp('${r.title.replaceAll(' ', '_')}.doc', bytes);
  }

  Future<File> exportTxt(SavedResume r) async {
    final txt = resumeToPlainText(r);
    return _writeTemp('${r.title.replaceAll(' ', '_')}.txt', txt.codeUnits);
  }

  Future<void> shareEmailClassic(SavedResume r) async {
    final body = resumeToPlainText(r);
    await Share.share(body, subject: r.title);
  }

  Future<void> shareGeneric(SavedResume r) async {
    final body = resumeToPlainText(r);
    await Share.share(body, subject: '${r.title} (${r.template})');
  }

  Future<void> exportAndOpenPdf(SavedResume r) async {
    final f = await exportPdf(r);
    await OpenFilex.open(f.path);
  }

  Future<void> exportAndOpenDoc(SavedResume r) async {
    final f = await exportDoc(r);
    await OpenFilex.open(f.path);
  }

  Future<void> exportAndOpenTxt(SavedResume r) async {
    final f = await exportTxt(r);
    await OpenFilex.open(f.path);
  }
}
