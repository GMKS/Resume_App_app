import 'dart:typed_data';

abstract class BrowserPdfPreviewHandle {
  Future<void> showPdf(Uint8List bytes);

  void close();
}