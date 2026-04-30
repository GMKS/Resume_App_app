import 'browser_pdf_preview_handle.dart';
import 'browser_pdf_preview_stub.dart'
    if (dart.library.html) 'browser_pdf_preview_web.dart' as impl;

BrowserPdfPreviewHandle? openBrowserPdfPreview({String? title}) {
  return impl.openBrowserPdfPreview(title: title);
}