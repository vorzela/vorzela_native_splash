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
  image: assets/brand/logo.png          # provide a large source (1024px+)
  branding: assets/brand/wordmark.png   # optional
  animation_duration: 800               # AVD + Flutter gate (ms)
  exit_animation: scale_fade            # none | fade | scale_fade | pulse
  android_12_animated_icon: true        # generate AVD pulse for API 31+
  android_12:
    image: assets/brand/logo.png
    icon_background_color: "#0F0F0F"
```

**Tip:** Feed a **high-resolution** logo (1024×1024 or larger). The generator
downscales with cubic interpolation into every density bucket so xxxhdpi /
@3x stay sharp.

---

## 2. Generate

```bash
dart run vorzela_native_splash:create
# or
dart run vorzela_native_splash:create -p vorzela_native_splash.yaml
```

Writes:

- `android/.../drawable-*/vorzela_splash.png` (1×–4×)
- `drawable-v31/vorzela_splash_avd.xml` (optional animated icon)
- `values/vorzela_splash_styles.xml` + Manifest theme patch
- `ios/Runner/Assets.xcassets/VorzelaSplash.imageset` (@1x/@2x/@3x)
- `LaunchScreen.storyboard`
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
      logo: Image.asset('assets/brand/logo.png', width: 96),
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

## Research notes (Gmail / YouTube)

- **YouTube:** dark field, centered mark, short scale into the first frame.
- **Gmail:** color field + mark, quieter fade into inbox chrome.
- **Android 12:** system icon may be an AVD; keep ≤ ~1000ms; branding image is
  discouraged by Google and capped ~200×80dp.
- **Sharpness:** always generate from a large master PNG/SVG→PNG; never upscale
  a 48dp asset into xxxhdpi.

---

## Remove

```bash
dart run vorzela_native_splash:remove
```

---

## License

MIT — see [LICENSE](LICENSE).
