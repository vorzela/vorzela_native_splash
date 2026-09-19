import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Built-in loader under the splash logo when no custom [loader] is passed.
enum SplashLoaderStyle {
  /// No loader.
  none,

  /// Compact circular progress (Material / YouTube-adjacent).
  circular,

  /// Three soft bouncing dots.
  dots,

  /// Short indeterminate linear bar.
  linear,
}

/// Centered circular indeterminate indicator.
class SplashCircularLoader extends StatelessWidget {
  const SplashCircularLoader({
    super.key,
    this.color = Colors.white,
    this.size = 28,
    this.strokeWidth = 2.5,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Short centered linear bar.
class SplashLinearLoader extends StatelessWidget {
  const SplashLinearLoader({
    super.key,
    this.color = Colors.white,
    this.width = 120,
    this.height = 3,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          backgroundColor: color.withValues(alpha: 0.18),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Three soft pulsing dots — light footprint, own ticker disposed on unmount.
class SplashDotsLoader extends StatefulWidget {
  const SplashDotsLoader({
    super.key,
    this.color = Colors.white,
    this.dotSize = 7,
    this.gap = 8,
  });

  final Color color;
  final double dotSize;
  final double gap;

  @override
  State<SplashDotsLoader> createState() => _SplashDotsLoaderState();
}

class _SplashDotsLoaderState extends State<SplashDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value + i * 0.22) % 1.0;
            final bounce = math.sin(phase * math.pi);
            final opacity = 0.35 + 0.65 * bounce;
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : widget.gap),
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, -3 * bounce),
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
