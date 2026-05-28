import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'export_file_validation.dart';
import 'shareable_export_file_stub.dart'
    if (dart.library.io) 'shareable_export_file_io.dart' as impl;

Future<XFile> buildShareableExportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  validateExportBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
  return impl.buildShareableExportFile(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
