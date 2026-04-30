import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'browser_pdf_preview_handle.dart';

BrowserPdfPreviewHandle? openBrowserPdfPreview({String? title}) {
  final previewWindow = html.window.open('about:blank', '_blank');
  if (previewWindow is! html.Window) {
    return null;
  }

  return _BrowserPdfPreviewHandle(
    previewWindow,
    title: title ?? 'Resume Preview',
  );
}

class _BrowserPdfPreviewHandle implements BrowserPdfPreviewHandle {
  _BrowserPdfPreviewHandle(this._window, {required this.title});

  final html.Window _window;
  final String title;
  String? _objectUrl;

  @override
  Future<void> showPdf(Uint8List bytes) async {
    final objectUrl = html.Url.createObjectUrlFromBlob(
      html.Blob(<dynamic>[bytes], 'application/pdf'),
    );
    _objectUrl = objectUrl;

    final escapedTitle = const HtmlEscape(HtmlEscapeMode.element).convert(title);
    final pdfUrlLiteral = jsonEncode(objectUrl);
    final htmlSource = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>$escapedTitle</title>
    <style>
      html, body {
        margin: 0;
        height: 100%;
        background: #0f172a;
      }

      iframe {
        display: block;
        width: 100vw;
        height: 100vh;
        border: 0;
        background: white;
      }
    </style>
  </head>
  <body>
    <iframe id="resume-pdf-frame" src=$pdfUrlLiteral></iframe>
    <script>
      const pdfUrl = $pdfUrlLiteral;
      const frame = document.getElementById('resume-pdf-frame');
      const cleanup = () => {
        try { URL.revokeObjectURL(pdfUrl); } catch (error) {}
      };

      window.addEventListener('afterprint', cleanup, { once: true });
      window.addEventListener('beforeunload', cleanup, { once: true });

      frame.addEventListener('load', () => {
        setTimeout(() => {
          try {
            frame.contentWindow.print();
          } catch (error) {
            try { window.print(); } catch (_) {}
          }
        }, 300);
      }, { once: true });
    </script>
  </body>
</html>
''';

    final wrapperUrl = Uri.dataFromString(
      htmlSource,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();

    _window.location.href = wrapperUrl;
  }

  @override
  void close() {
    final objectUrl = _objectUrl;
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
      _objectUrl = null;
    }

    _window.close();
  }
}