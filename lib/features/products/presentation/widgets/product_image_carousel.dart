import 'dart:async';

import 'package:flutter/material.dart';

/// Product images that auto-advance, with dot indicators and swipe support.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 180,
    this.autoScrollInterval = const Duration(seconds: 3),
    this.borderRadius,
  });

  final List<String> imageUrls;
  final double height;
  final Duration autoScrollInterval;
  final BorderRadius? borderRadius;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _index = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.imageUrls.length < 2) return;
    _timer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: widget.height,
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 34,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.imageUrls.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _CarouselImage(
                  url: widget.imageUrls[index],
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (dot) {
                    final active = dot == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: active ? 16 : 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white70,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselImage extends StatelessWidget {
  const _CarouselImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, _, __) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 30,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
