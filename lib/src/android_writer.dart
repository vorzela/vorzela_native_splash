import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'config.dart';
import 'dimensions.dart';

typedef DensifyFn = Future<void> Function({
  required String? sourcePath,
  required String outRoot,
  required String fileName,
  required int baseDp,
  Map<String, double>? folders,
  img.Image? master,
  int? masterWidthPx,
  int? masterHeightPx,
});

typedef NormalizeMasterFn = Future<img.Image> Function({
  required String sourcePath,
  required int masterWidthPx,
  required int masterHeightPx,
  void Function(String)? warn,
});

class AndroidWriter {
  AndroidWriter({required this.root, required this.config});

  final String root;
  final SplashConfig config;

  Future<void> write({
    required DensifyFn densify,
    required NormalizeMasterFn normalizeMaster,
    void Function(String)? warn,
  }) async {
    final res = _resDir();
    if (res == null) {
      stdout.writeln('⚠ No android/app/src/main/res — skipping Android');
      return;
    }

    final hasIconBg = config.android12IconBackgroundColor != null;
    final iconDp = android12IconDp(iconBackground: hasIconBg);
    final iconMasterPx = recommendedMasterPx(iconBackground: hasIconBg);

    // Pre-12 launch bitmap: densify source as @4x master (aspect preserved).
    if (config.image != null) {
      await densify(
        sourcePath: config.image,
        outRoot: res.path,
        fileName: 'vorzela_splash.png',
        baseDp: iconDp,
        folders: kAndroidDensities,
      );
    }

    // Android 12+ icon → drawable-*-v31 at official 288dp / 240dp canvas.
    final a12Source = config.android12Image ?? config.image;
    if (a12Source != null) {
      final master = await normalizeMaster(
        sourcePath: a12Source,
        masterWidthPx: iconMasterPx,
        masterHeightPx: iconMasterPx,
        warn: warn,
      );
      await densify(
        sourcePath: a12Source,
        outRoot: res.path,
        fileName: 'vorzela_splash_a12.png',
        baseDp: iconDp,
        folders: androidDensities(v31: true),
        master: master,
      );
    }

    if (config.brandingImage != null) {
      final master = await normalizeMaster(
        sourcePath: config.brandingImage!,
        masterWidthPx: kBrandingXxxhdpiWidthPx,
        masterHeightPx: kBrandingXxxhdpiHeightPx,
        warn: warn,
      );
      await densify(
        sourcePath: config.brandingImage,
        outRoot: res.path,
        fileName: 'vorzela_branding.png',
        baseDp: kBrandingWidthDp,
        folders: {
          ...kAndroidDensities,
          ...androidDensities(v31: true),
        },
        master: master,
      );
    }

    _writeColors(res);
    _writeLaunchBackground(res);
    if (config.generateAvdPulse) {
      _writeAvd(res, iconDp: iconDp);
    }
    _writeStyles(res, hasIconBg: hasIconBg);
    _ensureMainActivitySplash();
    _ensureGradleSplashScreenDep();
  }

  Directory? _resDir() {
    final d = Directory(p.join(root, 'android', 'app', 'src', 'main', 'res'));
    return d.existsSync() ? d : null;
  }

  void _writeColors(Directory res) {
    final values = Directory(p.join(res.path, 'values'));
    if (!values.existsSync()) values.createSync(recursive: true);
    final f = File(p.join(values.path, 'vorzela_splash_colors.xml'));
    final dark = config.colorDark ?? config.color;
    f.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="vorzela_splash_background">${config.color}</color>
    <color name="vorzela_splash_background_dark">$dark</color>
</resources>
''');
  }

  void _writeLaunchBackground(Directory res) {
    final drawable = Directory(p.join(res.path, 'drawable'));
    if (!drawable.existsSync()) drawable.createSync(recursive: true);
    final hasImage = config.image != null;
    final hasBranding = config.brandingImage != null;
    final bg = File(p.join(drawable.path, 'vorzela_launch_background.xml'));
    bg.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/vorzela_splash_background"/>
${hasImage ? '''    <item>
        <bitmap
            android:gravity="center"
            android:filter="false"
            android:antialias="true"
            android:src="@drawable/vorzela_splash"/>
    </item>
''' : ''}${hasBranding ? '''    <item android:bottom="24dp">
        <bitmap
            android:gravity="bottom|center_horizontal"
            android:filter="false"
            android:antialias="true"
            android:src="@drawable/vorzela_branding"/>
    </item>
''' : ''}
</layer-list>
''');
  }

  void _writeAvd(Directory res, {required int iconDp}) {
    // AVD viewport matches Android 12 icon dp (288 or 240).
    final v31 = Directory(p.join(res.path, 'drawable-v31'));
    if (!v31.existsSync()) v31.createSync(recursive: true);
    final avd = File(p.join(v31.path, 'vorzela_splash_avd.xml'));
    final ms = config.animationDurationMs.clamp(200, 1000);
    final mid = iconDp / 2;
    final r = iconDp * 0.33; // stays inside masked circle (~2/3)
    avd.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<animated-vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt">
    <aapt:attr name="android:drawable">
        <vector
            android:width="${iconDp}dp"
            android:height="${iconDp}dp"
            android:viewportWidth="$iconDp"
            android:viewportHeight="$iconDp">
            <group
                android:name="logo"
                android:pivotX="$mid"
                android:pivotY="$mid">
                <path
                    android:fillColor="#FFFFFFFF"
                    android:pathData="M$mid,${mid - r}a$r,$r 0 1,1 0,${r * 2}a$r,$r 0 1,1 0,-${r * 2}z"/>
            </group>
        </vector>
    </aapt:attr>
    <target android:name="logo">
        <aapt:attr name="android:animation">
            <objectAnimator
                android:propertyName="scaleX"
                android:duration="$ms"
                android:valueFrom="0.86"
                android:valueTo="1"
                android:valueType="floatType"
                android:interpolator="@android:interpolator/fast_out_slow_in"/>
        </aapt:attr>
    </target>
    <target android:name="logo">
        <aapt:attr name="android:animation">
            <objectAnimator
                android:propertyName="scaleY"
                android:duration="$ms"
                android:valueFrom="0.86"
                android:valueTo="1"
                android:valueType="floatType"
                android:interpolator="@android:interpolator/fast_out_slow_in"/>
        </aapt:attr>
    </target>
</animated-vector>
''');
  }

  void _writeStyles(Directory res, {required bool hasIconBg}) {
    final values = Directory(p.join(res.path, 'values'));
    final v31 = Directory(p.join(res.path, 'values-v31'));
    if (!v31.existsSync()) v31.createSync(recursive: true);

    final hasA12Bitmap = (config.android12Image ?? config.image) != null;
    final icon = config.generateAvdPulse && !hasA12Bitmap
        ? '@drawable/vorzela_splash_avd'
        : (hasA12Bitmap
            ? '@drawable/vorzela_splash_a12'
            : (config.image != null
                ? '@drawable/vorzela_splash'
                : '@mipmap/ic_launcher'));

    final styles = File(p.join(values.path, 'vorzela_splash_styles.xml'));
    styles.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Vorzela.Splash" parent="Theme.SplashScreen">
        <item name="windowSplashScreenBackground">@color/vorzela_splash_background</item>
        <item name="windowSplashScreenAnimatedIcon">$icon</item>
        <item name="windowSplashScreenAnimationDuration">${config.animationDurationMs.clamp(200, 1000)}</item>
        <item name="postSplashScreenTheme">@style/NormalTheme</item>
    </style>
</resources>
''');

    final a12Icon = hasA12Bitmap ? '@drawable/vorzela_splash_a12' : icon;
    final styles31 = File(p.join(v31.path, 'vorzela_splash_styles.xml'));
    final iconBg = config.android12IconBackgroundColor;
    final brandingItem = config.brandingImage != null
        ? '        <item name="android:windowSplashScreenBrandingImage">@drawable/vorzela_branding</item>\n'
        : '';
    styles31.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Vorzela.Splash" parent="Theme.SplashScreen${hasIconBg ? '.IconBackground' : ''}">
        <item name="windowSplashScreenBackground">@color/vorzela_splash_background</item>
        <item name="windowSplashScreenAnimatedIcon">$a12Icon</item>
        <item name="windowSplashScreenAnimationDuration">${config.animationDurationMs.clamp(200, 1000)}</item>
${iconBg != null ? '        <item name="windowSplashScreenIconBackgroundColor">$iconBg</item>\n' : ''}$brandingItem        <item name="postSplashScreenTheme">@style/NormalTheme</item>
    </style>
</resources>
''');

    final mainStyles = File(p.join(values.path, 'styles.xml'));
    if (mainStyles.existsSync()) {
      var text = mainStyles.readAsStringSync();
      if (!text.contains('Theme.Vorzela.Splash') &&
          text.contains('LaunchTheme')) {
        text = text.replaceFirst(
          RegExp(r'(<style name="LaunchTheme"[^>]*>)([\s\S]*?)(</style>)'),
          '''\$1
        <item name="android:windowBackground">@drawable/vorzela_launch_background</item>
\$3''',
        );
        mainStyles.writeAsStringSync(text);
      }
    }
  }

  void _ensureMainActivitySplash() {
    final manifest = File(
      p.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    );
    if (!manifest.existsSync()) return;
    var text = manifest.readAsStringSync();
    if (text.contains('Theme.Vorzela.Splash')) return;
    if (text.contains('android:theme="@style/LaunchTheme"')) {
      text = text.replaceFirst(
        'android:theme="@style/LaunchTheme"',
        'android:theme="@style/Theme.Vorzela.Splash"',
      );
      manifest.writeAsStringSync(text);
      stdout.writeln('  patched AndroidManifest → Theme.Vorzela.Splash');
    }
  }

  void _ensureGradleSplashScreenDep() {
    final gradle = File(p.join(root, 'android', 'app', 'build.gradle'));
    final kts = File(p.join(root, 'android', 'app', 'build.gradle.kts'));
    final file = gradle.existsSync()
        ? gradle
        : (kts.existsSync() ? kts : null);
    if (file == null) return;
    var text = file.readAsStringSync();
    if (text.contains('androidx.core:core-splashscreen')) return;
    const dep = "    implementation 'androidx.core:core-splashscreen:1.0.1'";
    const depKts = '    implementation("androidx.core:core-splashscreen:1.0.1")';
    if (text.contains('dependencies {')) {
      text = text.replaceFirst(
        'dependencies {',
        'dependencies {\n${file.path.endsWith('.kts') ? depKts : dep}',
      );
      file.writeAsStringSync(text);
      stdout.writeln('  added core-splashscreen dependency');
    }
  }
}
