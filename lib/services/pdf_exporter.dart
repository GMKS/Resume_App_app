import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/saved_resume.dart';

Future<Uint8List> generatePdf(SavedResume resume) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) {
        return [
          pw.Text(resume.title,
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
            pw.Text('Template: ${resume.template}'),
          pw.Text('Updated: ${resume.updatedAt}'),
          pw.Divider(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: resume.data.entries
                .map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text('${e.key}: ${e.value}'),
                    ))
                .toList(),
          ),
        ];
      },
    ),
  );
  return doc.save();
}