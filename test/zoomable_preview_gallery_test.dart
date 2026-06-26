import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/features/preview/widgets/zoomable_preview_gallery.dart';

Uint8List _tinyPngBytes() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgAONP6sAAAAASUVORK5CYII=',
  );
}

void main() {
  testWidgets('preview thumbnail opens fullscreen callback on double tap', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviewPageThumbnail(
            imageBytes: _tinyPngBytes(),
            pageNumber: 1,
            onOpenFullscreen: () => opened = true,
          ),
        ),
      ),
    );

    await tester.doubleTap(find.byType(PreviewPageThumbnail));

    expect(opened, isTrue);
  });

  testWidgets('fullscreen gallery shows page hint and supports page changes', (
    tester,
  ) async {
    final imageBytes = _tinyPngBytes();

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenPreviewGalleryScreen(
          pageImages: [imageBytes, imageBytes],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview Page 1'), findsOneWidget);
    expect(find.textContaining('Double-tap to zoom in'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Preview Page 2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
  });
}