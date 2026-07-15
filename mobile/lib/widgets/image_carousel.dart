import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/app_images.dart';
import '../theme/app_theme.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    this.slides = AppImages.featuredSlides,
    this.height = 280,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 4),
    this.borderRadius,
    this.showDots = true,
    this.blurSigma = 0,
  });

  final List<CarouselSlide> slides;
  final double height;
  final bool autoPlay;
  final Duration interval;
  final BorderRadius? borderRadius;
  final bool showDots;
  /// Soft blur over the photo (e.g. 4–8 for registration).
  final double blurSigma;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _controller;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.autoPlay && widget.slides.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.slides.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppDecor.radiusLg;
    final slide = widget.slides[_index];

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                Widget image = Image.asset(
                  widget.slides[i].image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, error, stack) => Container(
                    color: AppColors.deepGreen,
                    child: const Icon(Icons.favorite, color: AppColors.gold, size: 48),
                  ),
                );
                if (widget.blurSigma > 0) {
                  image = ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: image,
                  );
                }
                return image;
              },
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, widget.showDots ? 36 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'WedPlan Ghana',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Column(
                        key: ValueKey(_index),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slide.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.showDots && widget.slides.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
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

class FullScreenSlideshow extends StatefulWidget {
  const FullScreenSlideshow({
    super.key,
    this.slides = AppImages.featuredSlides,
    this.child,
  });

  final List<CarouselSlide> slides;
  final Widget? child;

  @override
  State<FullScreenSlideshow> createState() => _FullScreenSlideshowState();
}

class _FullScreenSlideshowState extends State<FullScreenSlideshow> {
  late final PageController _controller;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_index];

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.slides.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Image.asset(
            widget.slides[i].image,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => Container(color: AppColors.deepGreen),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.deepGreen.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.gold, size: 40),
                ),
                const SizedBox(height: 14),
                const Text(
                  'WedPlan Ghana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    key: ValueKey(_index),
                    children: [
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (widget.child != null) widget.child!,
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
