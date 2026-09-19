# vorzela_native_splash

Native **Android / iOS** splash screens with a **high-DPI generator** and modern
Flutter exit animations (YouTube / Gmail style).

**License:** MIT  
**Repo:** https://github.com/vorzela/vorzela_native_splash

---

## Why this exists

[`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) covers
static color + image. Modern apps (Gmail, YouTube, Netflix) use a **two-phase**
splash:

1. **OS splash** (Android 12 `SplashScreen` / iOS `LaunchScreen`) — instant,
   native, high-DPI icon (optionally a short AVD on Android 12+).
2. **Flutter handoff** — brand motion (scale-fade / fade / pulse) once the
   engine is ready.

Android 12 **cannot** run arbitrary Lottie on the system splash — only an
AnimatedVectorDrawable icon (~1s). Cinematic motion belongs in Flutter. This
package generates both layers.

| Feature | Support |
|---------|---------|
| High-DPI PNGs (mdpi→xxxhdpi, @1x/@2x/@3x) | ✓ |
| Android 12 SplashScreen + core-splashscreen | ✓ |
| Optional AVD pulse icon (API 31+) | ✓ |
| iOS LaunchScreen storyboard | ✓ |
| Flutter exit: `fade` / `scale_fade` / `pulse` | ✓ |
| Custom / built-in loaders under logo | ✓ |
| Optional bottom footer text / widget | ✓ |
| Web | Not included (use CSS / Flutter web splash) |

---

## Install

```yaml
dev_dependencies:
  vorzela_native_splash:
    git:
      url: https://github.com/vorzela/vorzela_native_splash.git

dependencies:
  vorzela_native_splash:
    git:
      url: https://github.com/vorzela/vorzela_native_splash.git
```

(Use as both dep + dev_dep so the CLI and `VorzelaSplashGate` are available.)

---

## 1. Configure

`vorzela_native_splash.yaml` (or under `pubspec.yaml`):

```yaml
vorzela_native_splash:
  color: "#0F0F0F"
  color_dark: "#000000"
  image: assets/brand/logo.png          # @4x master: prefer 1152×1152 (or 960×960 with icon bg)
  branding: assets/brand/wordmark.png   # Android 12 branding canvas: 800×320 @xxxhdpi
  animation_duration: 800               # AVD + Flutter gate (ms)
  exit_animation: scale_fade            # none | fade | scale_fade | pulse
  android_12_animated_icon: true        # generate AVD pulse for API 31+
  android_12:
    image: assets/brand/logo.png
    icon_background_color: "#0F0F0F"    # when set → 240dp / 960px canvas; else 288dp / 1152px
```

**Tip:** Treat the source as an **@4x / xxxhdpi** master (same as
`flutter_native_splash` 2.4.x). The generator scales with `px = size × density / 4`
using **cubic** interpolation (not soft `average`), and **never upscales** a small
PNG onto the 1152/960 canvas (that is what makes logos look faint). Tablets use the
same density buckets (dp); iOS LaunchScreen caps logo width at 38% of the canvas
so iPad does not look phone-sized. In Flutter, use `SplashLogo.asset(…)` (or
`filterQuality: FilterQuality.high`) so the handoff mark stays crisp.

### Official dimensions (Android 12 SplashScreen)

| Asset | dp | xxxhdpi px | Mask |
|-------|-----|------------|------|
| Icon, no background | 288×288 | 1152×1152 | ⌀192 dp circle |
| Icon, with background | 240×240 | 960×960 | ⌀160 dp circle |
| Branding | 200×80 | 800×320 | bottom strip |

> Note: pub’s `flutter_native_splash` latest is **2.4.8** (not a v5/v6 package).
> Specs above match Google’s SplashScreen docs + that package’s densify math.

---

## 2. Generate

```bash
dart run vorzela_native_splash:create
# or
dart run vorzela_native_splash:create -p vorzela_native_splash.yaml
```

Writes:

- `android/.../drawable-*/vorzela_splash.png` (mdpi→xxxhdpi, phones & tablets)
- `drawable-*-v31/vorzela_splash_a12.png` (Android 12 icon canvas)
- `drawable-v31/vorzela_splash_avd.xml` (optional animated icon)
- branding at **200×80 dp** (`800×320` @xxxhdpi) when configured
- `values` / `values-v31` splash styles + Manifest theme patch
- `ios/.../VorzelaSplash.imageset` (@1x/@2x/@3x from @4x master)
- `LaunchScreen.storyboard` (centered logo, width ≤38% for iPad)
- `lib/generated/vorzela_splash.g.dart`

---

## 3. Flutter handoff

```dart
import 'package:vorzela_native_splash/vorzela_native_splash.dart';
import 'generated/vorzela_splash.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VorzelaNativeSplash.preserve();
  runApp(
    VorzelaSplashGate(
      animation: kVorzelaSplashExitAnimation, // or SplashExitAnimation.scaleFade
      backgroundColor: const Color(0xFF0F0F0F),
      logo: SplashLogo.asset('assets/brand/logo.png', width: 96),
      loaderStyle: SplashLoaderStyle.circular, // none | circular | dots | linear
      loaderTheme: const SplashLoaderTheme(
        color: Color(0xFFE50914),
        size: 36,
        strokeWidth: 3,
        trackColor: Colors.white24,
      ),
      // loader: SplashCircularLoader(color: Colors.red, size: 40), // or fully custom
      footerText: 'Vorzela',                 // optional bottom caption
      // footer: Text('v1.0'),               // or a custom footer widget
      // ready: authBootstrap(),             // optional
      child: const MyApp(),
    ),
  );
}
```

### Exit animations

| Name | Feel |
|------|------|
| `scale_fade` | YouTube / Material — logo grows slightly, fades out |
| `fade` | Gmail-like soft dissolve |
| `pulse` | Brand heartbeat then dissolve |
| `none` | Instant remove |

### Loaders & footer

Logo is centered; the loader sits **under** it (`logoLoaderGap`, default 28). Footer is
pinned to the **bottom safe area** (`footerText` or `footer`). Controllers /
tickers (gate + dots loader) are disposed; async exit work is cancelled on
unmount so there are no post-`dispose` `setState` leaks.

Style built-in loaders with `SplashLoaderTheme` (`color`,
`trackColor`, `size`, `strokeWidth`, `strokeCap`, `linearWidth` / `linearHeight`,
`dotSize` / `dotGap`). Or pass `loader:` with `SplashCircularLoader(...)` /
any widget for full control. `loaderColor` is a shorthand for theme color.

---

## Research notes (Gmail / YouTube / flutter_native_splash)

- **YouTube:** dark field, centered mark, short scale into the first frame.
- **Gmail:** color field + mark, quieter fade into inbox chrome.
- **Android 12:** system icon may be an AVD; keep ≤ ~1000ms; branding is
  discouraged by Google and capped at **200×80 dp**.
- **Densify:** `flutter_native_splash` 2.4.x uses `width * density ~/ 4` from an
  @4x master — we match that. Tablets are covered by the same dp buckets.
- **Sharpness:** prefer a **1152×1152** (no icon bg) or **960×960** (with bg)
  master; never upscale a 48 dp asset into xxxhdpi.

---

## Remove

```bash
dart run vorzela_native_splash:remove
```

---

## License

MIT — see [LICENSE](LICENSE).
