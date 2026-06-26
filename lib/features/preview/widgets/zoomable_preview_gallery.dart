import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_theme.dart';

class PreviewPageThumbnail extends StatelessWidget {
  final Uint8List imageBytes;
  final int pageNumber;
  final VoidCallback onOpenFullscreen;

  const PreviewPageThumbnail({
    super.key,
    required this.imageBytes,
    required this.pageNumber,
    required this.onOpenFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onOpenFullscreen,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.fitWidth,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.maximize_4,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Page $pageNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenPreviewGalleryScreen extends StatefulWidget {
  final List<Uint8List> pageImages;
  final int initialPage;
  final bool showWatermark;

  const FullscreenPreviewGalleryScreen({
    super.key,
    required this.pageImages,
    this.initialPage = 0,
    this.showWatermark = false,
  });

  @override
  State<FullscreenPreviewGalleryScreen> createState() =>
      _FullscreenPreviewGalleryScreenState();
}

class _FullscreenPreviewGalleryScreenState
    extends State<FullscreenPreviewGalleryScreen> {
  late final PageController _pageController;
  final Map<int, TransformationController> _controllers =
      <int, TransformationController>{};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, widget.pageImages.length - 1);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  TransformationController _controllerFor(int index) {
    return _controllers.putIfAbsent(index, TransformationController.new);
  }

  bool _isZoomed(int index) {
    final controller = _controllers[index];
    if (controller == null) {
      return false;
    }
    return controller.value.getMaxScaleOnAxis() > 1.01;
  }

  void _resetZoom(int index) {
    final controller = _controllerFor(index);
    controller.value = Matrix4.identity();
  }

  void _toggleZoom(int index, TapDownDetails details) {
    final controller = _controllerFor(index);
    if (_isZoomed(index)) {
      controller.value = Matrix4.identity();
    } else {
      const scale = 2.4;
      final position = details.localPosition;
      controller.value = Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Preview Page ${_currentPage + 1}'),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () {
              _resetZoom(_currentPage);
              setState(() {});
            },
            icon: const Icon(Iconsax.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed(_currentPage)
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.pageImages.length,
            onPageChanged: (index) {
              _resetZoom(_currentPage);
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onDoubleTapDown: (details) => _toggleZoom(index, details),
                    child: InteractiveViewer(
                      transformationController: _controllerFor(index),
                      minScale: 1,
                      maxScale: 4,
                      panEnabled: true,
                      clipBehavior: Clip.none,
                      onInteractionEnd: (_) => setState(() {}),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                            child: Image.memory(
                              widget.pageImages[index],
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (widget.showWatermark)
            IgnorePointer(
              child: Center(
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    'Generated with ${AppInfo.appName}\nUpgrade to remove watermark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.maximize_4,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isZoomed(_currentPage)
                              ? 'Double-tap to zoom out. Pinch or drag to inspect details.'
                              : 'Double-tap to zoom in. Swipe left or right to change pages.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_currentPage + 1}/${widget.pageImages.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
