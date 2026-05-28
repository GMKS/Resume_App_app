import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'preview_image_service.dart';

class PreviewMediaService {
  static const Duration _defaultGifFrameHold = Duration(milliseconds: 1200);

  static Future<Uint8List> generateGifFromPdfBytes(
    Uint8List pdfBytes, {
    double dpi = 144,
    Duration frameHold = _defaultGifFrameHold,
  }) async {
    final pageImages = await PreviewImageService.generatePagesFromPdfBytes(
      pdfBytes,
      dpi: dpi,
    );
    if (pageImages.isEmpty) {
      throw StateError('No PDF pages were available for GIF export.');
    }

    final decodedFrames = pageImages
        .map((pageBytes) => img.decodeImage(pageBytes))
        .toList(growable: false);
    if (decodedFrames.any((frame) => frame == null)) {
      throw StateError(
          'A PDF page could not be decoded as PNG data for GIF export.');
    }

    final normalizedFrames = decodedFrames.cast<img.Image>();
    final frameWidth = normalizedFrames
        .map((frame) => frame.width)
        .reduce((left, right) => left > right ? left : right);
    final frameHeight = normalizedFrames
        .map((frame) => frame.height)
        .reduce((left, right) => left > right ? left : right);

    final encoder = img.GifEncoder(
      repeat: 0,
      delay: math.max(1, (frameHold.inMilliseconds / 10).round()),
    );
    var frameCount = 0;

    for (final frame in normalizedFrames) {
      final composedFrame = img.Image(
        width: frameWidth,
        height: frameHeight,
        numChannels: 4,
      );
      img.fill(
        composedFrame,
        color: img.ColorRgba8(255, 255, 255, 255),
      );
      final offsetX = ((frameWidth - frame.width) / 2).round();
      final offsetY = ((frameHeight - frame.height) / 2).round();
      img.compositeImage(
        composedFrame,
        frame,
        dstX: offsetX,
        dstY: offsetY,
      );

      composedFrame.frameDuration = frameHold.inMilliseconds;
      encoder.addFrame(composedFrame);
      frameCount++;
    }

    if (frameCount == 0) {
      throw StateError('Animated GIF generation failed.');
    }

    final gifBytes = encoder.finish();
    if (gifBytes == null || gifBytes.isEmpty) {
      throw StateError('Animated GIF generation failed.');
    }

    return Uint8List.fromList(gifBytes);
  }
}
