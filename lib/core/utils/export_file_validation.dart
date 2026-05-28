import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

void validateExportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  if (bytes.isEmpty) {
    throw StateError('The generated export file is empty.');
  }

  final normalizedName = fileName.toLowerCase();
  final normalizedMimeType = mimeType.toLowerCase();

  if (normalizedMimeType == 'application/pdf' ||
      normalizedName.endsWith('.pdf')) {
    if (!_startsWith(bytes, const <int>[0x25, 0x50, 0x44, 0x46, 0x2D])) {
      throw StateError('The generated PDF is missing a valid PDF header.');
    }
    return;
  }

  if (normalizedMimeType == 'image/png' || normalizedName.endsWith('.png')) {
    if (!_startsWith(bytes, const <int>[0x89, 0x50, 0x4E, 0x47])) {
      throw StateError('The generated PNG is missing a valid PNG header.');
    }
    if (img.decodeImage(bytes) == null) {
      throw StateError('The generated PNG could not be decoded.');
    }
    return;
  }

  if (normalizedMimeType == 'image/gif' || normalizedName.endsWith('.gif')) {
    final isGif87a = _startsWith(bytes, ascii.encode('GIF87a'));
    final isGif89a = _startsWith(bytes, ascii.encode('GIF89a'));
    if (!isGif87a && !isGif89a) {
      throw StateError('The generated GIF is missing a valid GIF header.');
    }
    if (img.decodeImage(bytes) == null) {
      throw StateError('The generated GIF could not be decoded.');
    }
    return;
  }

  if (normalizedMimeType == 'text/plain' || normalizedName.endsWith('.txt')) {
    final content = utf8.decode(bytes, allowMalformed: false).trim();
    if (content.isEmpty) {
      throw StateError('The generated TXT export is empty.');
    }
    return;
  }

  if (normalizedMimeType ==
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      normalizedName.endsWith('.docx')) {
    if (!_startsWith(bytes, const <int>[0x50, 0x4B, 0x03, 0x04])) {
      throw StateError('The generated DOCX is missing a valid ZIP header.');
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    final hasDocumentXml = archive.files.any(
      (file) => file.name == 'word/document.xml',
    );
    if (!hasDocumentXml) {
      throw StateError(
          'The generated DOCX is missing the Word document payload.');
    }
  }
}

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) {
    return false;
  }

  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) {
      return false;
    }
  }

  return true;
}
