import 'dart:convert';
import 'dart:typed_data';
import '../models/saved_resume.dart';
import 'resume_renderer.dart';

Future<Uint8List> generateDoc(SavedResume resume) async {
  final txt = resumeToPlainText(resume);
  // Very simple: plain text saved with .doc extension (many editors open it)
  return Uint8List.fromList(utf8.encode(txt));
}