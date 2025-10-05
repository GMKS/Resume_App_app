import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart' as ar;
import 'package:resume_builder_app/services/ai_service.dart';

void main() {
  test('buildDocxBytesFromPlainText produces valid OOXML parts', () {
    final bytes = buildDocxBytesFromPlainText('Hello\nWorld');
    final archive = ar.ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names.contains('[Content_Types].xml'), isTrue);
    expect(names.contains('_rels/.rels'), isTrue);
    expect(names.contains('docProps/app.xml'), isTrue);
    expect(names.contains('docProps/core.xml'), isTrue);
    expect(names.contains('word/document.xml'), isTrue);
    expect(names.contains('word/styles.xml'), isTrue);
    expect(names.contains('word/_rels/document.xml.rels'), isTrue);

    final docXml = utf8.decode(
      archive.files.firstWhere((f) => f.name == 'word/document.xml').content,
    );
    expect(docXml.contains('<w:document'), isTrue);
    expect(docXml.contains('<w:p>'), isTrue);
    expect(docXml.contains('Hello'), isTrue);
    expect(docXml.contains('World'), isTrue);
  });
}
