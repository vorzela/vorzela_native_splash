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

/// Visual knobs for built-in [SplashLoaderStyle]s.
///
/// Use with [VorzelaSplashGate.loaderTheme] when you keep `loaderStyle`
/// (e.g. [SplashLoaderStyle.circular]) instead of a fully custom [loader].
class SplashLoaderTheme {
  const SplashLoaderTheme({
    this.color,
    this.trackColor,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.strokeCap = StrokeCap.round,
    this.linearWidth = 120,
    this.linearHeight = 3,
    this.dotSize = 7,
    this.dotGap = 8,
  });

  /// Active stroke / dot / bar color. Defaults to white @ 85% on the gate.
  final Color? color;

  /// Inactive track behind circular / linear indicators.
  final Color? trackColor;

  /// Diameter for [SplashLoaderStyle.circular].
  final double size;

  /// Stroke for [SplashLoaderStyle.circular].
  final double strokeWidth;

  /// Cap style for the circular stroke.
  final StrokeCap strokeCap;

  /// Width for [SplashLoaderStyle.linear].
  final double linearWidth;

  /// Thickness for [SplashLoaderStyle.linear].
  final double linearHeight;

  /// Dot diameter for [SplashLoaderStyle.dots].
  final double dotSize;

  /// Space between dots.
  final double dotGap;

  SplashLoaderTheme copyWith({
    Color? color,
    Color? trackColor,
    double? size,
    double? strokeWidth,
    StrokeCap? strokeCap,
    double? linearWidth,
    double? linearHeight,
    double? dotSize,
    double? dotGap,
  }) {
    return SplashLoaderTheme(
      color: color ?? this.color,
      trackColor: trackColor ?? this.trackColor,
      size: size ?? this.size,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
      linearWidth: linearWidth ?? this.linearWidth,
      linearHeight: linearHeight ?? this.linearHeight,
      dotSize: dotSize ?? this.dotSize,
      dotGap: dotGap ?? this.dotGap,
    );
  }
}

/// Centered circular indeterminate indicator.
class SplashCircularLoader extends StatelessWidget {
  const SplashCircularLoader({
    super.key,
    this.color = Colors.white,
    this.trackColor,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.strokeCap = StrokeCap.round,
  });

  /// Convenience from a resolved [SplashLoaderTheme].
  factory SplashCircularLoader.fromTheme(SplashLoaderTheme theme) {
    return SplashCircularLoader(
      color: theme.color ?? Colors.white,
      trackColor: theme.trackColor,
      size: theme.size,
      strokeWidth: theme.strokeWidth,
      strokeCap: theme.strokeCap,
    );
  }

  final Color color;
  final Color? trackColor;
  final double size;
  final double strokeWidth;
  final StrokeCap strokeCap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: strokeCap,
        backgroundColor: trackColor,
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
    this.trackColor,
    this.width = 120,
    this.height = 3,
  });

  factory SplashLinearLoader.fromTheme(SplashLoaderTheme theme) {
    return SplashLinearLoader(
      color: theme.color ?? Colors.white,
      trackColor: theme.trackColor,
      width: theme.linearWidth,
      height: theme.linearHeight,
    );
  }

  final Color color;
  final Color? trackColor;
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
          backgroundColor:
              trackColor ?? color.withValues(alpha: 0.18),
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

  factory SplashDotsLoader.fromTheme(SplashLoaderTheme theme) {
    return SplashDotsLoader(
      color: theme.color ?? Colors.white,
      dotSize: theme.dotSize,
      gap: theme.dotGap,
    );
  }

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
