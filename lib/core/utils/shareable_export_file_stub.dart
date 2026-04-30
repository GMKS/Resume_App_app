import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> buildShareableExportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  return XFile.fromData(
    bytes,
    mimeType: mimeType,
    name: fileName,
  );
}