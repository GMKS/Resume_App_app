import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> buildShareableExportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final tempDirectory = await Directory.systemTemp.createTemp(
    'resume_builder_export_',
  );
  final file = File(
    '${tempDirectory.path}${Platform.pathSeparator}$safeFileName',
  );

  await file.writeAsBytes(bytes, flush: true);

  return XFile(
    file.path,
    mimeType: mimeType,
    name: safeFileName,
  );
}