import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> buildShareableExportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  Object? lastError;

  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'resume_builder_export_',
      );
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}$safeFileName',
      );

      await file.writeAsBytes(bytes, flush: true);
      final writtenLength = await file.length();
      if (writtenLength != bytes.length) {
        throw StateError(
          'File write verification failed for $safeFileName.',
        );
      }

      return XFile(
        file.path,
        mimeType: mimeType,
        name: safeFileName,
      );
    } catch (error) {
      lastError = error;
      if (attempt == 1) {
        rethrow;
      }
    }
  }

  throw StateError('Unable to prepare export file: $lastError');
}
