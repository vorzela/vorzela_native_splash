import 'package:flutter/material.dart';

/// High-quality splash logo for [VorzelaSplashGate].
///
/// Uses [FilterQuality.high] so Flutter does not paint a soft/faint mark when
/// the asset is scaled on tablet or high-DPI displays.
class SplashLogo extends StatelessWidget {
  const SplashLogo({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  /// Convenience for asset logos (most common handoff case).
  SplashLogo.asset(
    String assetName, {
    super.key,
    this.width = 96,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    AssetBundle? bundle,
    String? package,
  }) : image = Image.asset(
          assetName,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          bundle: bundle,
          package: package,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
        );

  final Widget image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final child = image is Image
        ? _withHighQuality(image as Image)
        : image;
    final labeled = semanticLabel != null || excludeFromSemantics
        ? Semantics(
            label: semanticLabel,
            excludeSemantics: excludeFromSemantics,
            image: !excludeFromSemantics,
            child: child,
          )
        : child;
    if (width == null && height == null) return labeled;
    return SizedBox(width: width, height: height, child: labeled);
  }

  Widget _withHighQuality(Image image) {
    return Image(
      image: image.image,
      width: image.width,
      height: image.height,
      fit: image.fit ?? BoxFit.contain,
      alignment: image.alignment,
      color: image.color,
      colorBlendMode: image.colorBlendMode,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
      semanticLabel: semanticLabel ?? image.semanticLabel,
      excludeFromSemantics:
          excludeFromSemantics || image.excludeFromSemantics,
      opacity: image.opacity,
    );
  }
}
