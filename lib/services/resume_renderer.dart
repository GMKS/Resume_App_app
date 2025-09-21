import '../models/saved_resume.dart';

String resumeToPlainText(SavedResume r) {
  final b = StringBuffer()
    ..writeln('Title: ${r.title}')
    ..writeln('Template: ${r.template}')
    ..writeln('Created: ${r.createdAt}')
    ..writeln('Updated: ${r.updatedAt}')
    ..writeln('--- Data ---');
  for (final e in r.data.entries) {
    b.writeln('${e.key}: ${e.value}');
  }
  return b.toString();
}
