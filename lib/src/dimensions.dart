/// Official Android 12+ SplashScreen + density math (phones **and** tablets).
///
/// Android uses **density-independent pixels (dp)**. Tablets share the same
/// mdpi→xxxhdpi buckets; a 288 dp icon is the same logical size on a phone or
/// iPad-class Android tablet — only the physical pixel count changes.
///
/// Pixel targets at **xxxhdpi (4×)** match Google’s docs and
/// [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) 2.4.x
/// (latest on pub is **2.4.8** — there is no package v5/v6):
///
/// | Asset | dp (mdpi) | xxxhdpi px | Notes |
/// |-------|-----------|------------|-------|
/// | Icon, no background | 288×288 | 1152×1152 | Fit design in ⌀192 dp circle |
/// | Icon, with background | 240×240 | 960×960 | Fit design in ⌀160 dp circle |
/// | Branding strip | 200×80 | 800×320 | Bottom brand image |
///
/// [flutter_native_splash] treats the source PNG as **@4x / xxxhdpi** and
/// scales with `size * density / 4` (aspect preserved). We do the same, and
/// optionally normalize Android 12 icons / branding to the official canvas
/// before densifying.
library;

/// Android drawable density multipliers (same folders phones + tablets use).
const Map<String, double> kAndroidDensities = {
  'drawable-mdpi': 1,
  'drawable-hdpi': 1.5,
  'drawable-xhdpi': 2,
  'drawable-xxhdpi': 3,
  'drawable-xxxhdpi': 4,
};

/// Android 12+ night + v31 variants of [kAndroidDensities].
Map<String, double> androidDensities({
  bool night = false,
  bool v31 = false,
}) {
  final prefix = night ? 'drawable-night' : 'drawable';
  final suffix = v31 ? '-v31' : '';
  return {
    for (final e in kAndroidDensities.entries)
      '$prefix-${e.key.split('-').last}$suffix': e.value,
  };
}

/// iOS scale factors. Source is treated as @4x (like flutter_native_splash).
const Map<String, double> kIosScales = {
  '1x': 1,
  '2x': 2,
  '3x': 3,
};

/// Master scale factor for source images (@4x / xxxhdpi).
const double kMasterDensity = 4;

/// App icon without icon background (Android 12 SplashScreen).
const int kAndroid12IconDp = 288;
const int kAndroid12IconXxxhdpiPx = 1152; // 288 * 4
const int kAndroid12IconSafeCircleDp = 192;

/// App icon with icon background.
const int kAndroid12IconWithBgDp = 240;
const int kAndroid12IconWithBgXxxhdpiPx = 960; // 240 * 4
const int kAndroid12IconWithBgSafeCircleDp = 160;

/// Branding image (Android 12).
const int kBrandingWidthDp = 200;
const int kBrandingHeightDp = 80;
const int kBrandingXxxhdpiWidthPx = 800; // 200 * 4
const int kBrandingXxxhdpiHeightPx = 320; // 80 * 4

/// iOS LaunchScreen logo: points on phone; capped fraction of width on tablet.
const double kIosLogoPoints = 240;
const double kIosLogoMaxWidthFraction = 0.38;

/// Recommended minimum source edge (px) so xxxhdpi stays sharp.
int recommendedMasterPx({required bool iconBackground}) =>
    iconBackground ? kAndroid12IconWithBgXxxhdpiPx : kAndroid12IconXxxhdpiPx;

/// Logical dp for Android 12 animated/static icon.
int android12IconDp({required bool iconBackground}) =>
    iconBackground ? kAndroid12IconWithBgDp : kAndroid12IconDp;
