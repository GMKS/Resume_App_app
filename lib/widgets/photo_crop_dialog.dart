import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PhotoCropDialog extends StatefulWidget {
  final String base64Image;
  final Function(String) onCropped;

  const PhotoCropDialog({
    super.key,
    required this.base64Image,
    required this.onCropped,
  });

  @override
  State<PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<PhotoCropDialog> {
  late Uint8List _imageBytes;
  late ui.Image _image;
  bool _imageLoaded = false;

  // Crop area
  Rect _cropRect = const Rect.fromLTWH(50, 50, 200, 200);
  late Size _imageDisplaySize;
  late Size _actualImageSize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      _imageBytes = base64Decode(widget.base64Image);
      final codec = await ui.instantiateImageCodec(_imageBytes);
      final frame = await codec.getNextFrame();
      _image = frame.image;
      _actualImageSize = Size(
        _image.width.toDouble(),
        _image.height.toDouble(),
      );
      setState(() {
        _imageLoaded = true;
      });
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crop Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _imageLoaded
                  ? _buildCropArea()
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cropImage,
                    child: const Text('Apply Crop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate display size maintaining aspect ratio
        final aspectRatio = _actualImageSize.width / _actualImageSize.height;
        late Size displaySize;

        if (aspectRatio > constraints.maxWidth / constraints.maxHeight) {
          displaySize = Size(
            constraints.maxWidth,
            constraints.maxWidth / aspectRatio,
          );
        } else {
          displaySize = Size(
            constraints.maxHeight * aspectRatio,
            constraints.maxHeight,
          );
        }

        _imageDisplaySize = displaySize;

        // Initialize crop rect if needed
        if (_cropRect.left == 50) {
          final cropSize = displaySize.width * 0.6;
          final offsetX = (displaySize.width - cropSize) / 2;
          final offsetY = (displaySize.height - cropSize) / 2;
          _cropRect = Rect.fromLTWH(offsetX, offsetY, cropSize, cropSize);
        }

        return Center(
          child: SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: Stack(
              children: [
                // Background image
                Container(
                  width: displaySize.width,
                  height: displaySize.height,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(_imageBytes),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Overlay with crop area
                CustomPaint(
                  size: displaySize,
                  painter: CropOverlayPainter(_cropRect),
                ),
                // Draggable crop handles
                _buildCropHandle(
                  _cropRect.topLeft,
                  (delta) => _updateCropRect(
                    Rect.fromLTWH(
                      _cropRect.left + delta.dx,
                      _cropRect.top + delta.dy,
                      _cropRect.width - delta.dx,
                      _cropRect.height - delta.dy,
                    ),
                  ),
                ),
                _buildCropHandle(
                  _cropRect.topRight,
                  (delta) => _updateCropRect(
                    Rect.fromLTWH(
                      _cropRect.left,
                      _cropRect.top + delta.dy,
                      _cropRect.width + delta.dx,
                      _cropRect.height - delta.dy,
                    ),
                  ),
                ),
                _buildCropHandle(
                  _cropRect.bottomLeft,
                  (delta) => _updateCropRect(
                    Rect.fromLTWH(
                      _cropRect.left + delta.dx,
                      _cropRect.top,
                      _cropRect.width - delta.dx,
                      _cropRect.height + delta.dy,
                    ),
                  ),
                ),
                _buildCropHandle(
                  _cropRect.bottomRight,
                  (delta) => _updateCropRect(
                    Rect.fromLTWH(
                      _cropRect.left,
                      _cropRect.top,
                      _cropRect.width + delta.dx,
                      _cropRect.height + delta.dy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCropHandle(Offset position, Function(Offset) onPan) {
    return Positioned(
      left: position.dx - 8,
      top: position.dy - 8,
      child: GestureDetector(
        onPanUpdate: (details) => onPan(details.delta),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCropRect(Rect newRect) {
    // Ensure crop rect stays within bounds
    final constrainedRect = Rect.fromLTWH(
      newRect.left.clamp(0, _imageDisplaySize.width - 50),
      newRect.top.clamp(0, _imageDisplaySize.height - 50),
      newRect.width.clamp(50, _imageDisplaySize.width - newRect.left),
      newRect.height.clamp(50, _imageDisplaySize.height - newRect.top),
    );

    setState(() {
      _cropRect = constrainedRect;
    });
  }

  Future<void> _cropImage() async {
    try {
      // Convert display coordinates to actual image coordinates
      final scaleX = _actualImageSize.width / _imageDisplaySize.width;
      final scaleY = _actualImageSize.height / _imageDisplaySize.height;

      final actualCropRect = Rect.fromLTWH(
        _cropRect.left * scaleX,
        _cropRect.top * scaleY,
        _cropRect.width * scaleX,
        _cropRect.height * scaleY,
      );

      // Create a new image with the cropped area
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        _image,
        actualCropRect,
        Rect.fromLTWH(0, 0, actualCropRect.width, actualCropRect.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        actualCropRect.width.round(),
        actualCropRect.height.round(),
      );

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final croppedBytes = byteData!.buffer.asUint8List();
      final croppedBase64 = base64Encode(croppedBytes);

      widget.onCropped(croppedBase64);
      Navigator.pop(context);
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to crop image')));
    }
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw overlay outside crop area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw crop border
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(cropRect, borderPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + (cropRect.width / 3) * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + (cropRect.height / 3) * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
