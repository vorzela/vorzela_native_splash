import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';

typedef DensifyFn = Future<void> Function({
  required String? sourcePath,
  required String outRoot,
  required String fileName,
  required int baseDp,
  Map<String, double>? folders,
});

class AndroidWriter {
  AndroidWriter({required this.root, required this.config});

  final String root;
  final SplashConfig config;

  Future<void> write({required DensifyFn densify}) async {
    final res = _resDir();
    if (res == null) {
      stdout.writeln('⚠ No android/app/src/main/res — skipping Android');
      return;
    }

    await densify(
      sourcePath: config.image,
      outRoot: res.path,
      fileName: 'vorzela_splash.png',
      baseDp: 288,
    );

    if (config.android12Image != null &&
        config.android12Image != config.image) {
      await densify(
        sourcePath: config.android12Image,
        outRoot: res.path,
        fileName: 'vorzela_splash_a12.png',
        baseDp: 288,
      );
    }

    if (config.brandingImage != null) {
      await densify(
        sourcePath: config.brandingImage,
        outRoot: res.path,
        fileName: 'vorzela_branding.png',
        baseDp: 200, // branding is wide; height scaled proportionally in densify square — ok for now
      );
    }

    _writeColors(res);
    _writeLaunchBackground(res);
    if (config.generateAvdPulse) {
      _writeAvd(res);
    }
    _writeStyles(res);
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
    final bg = File(p.join(drawable.path, 'vorzela_launch_background.xml'));
    bg.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/vorzela_splash_background"/>
${hasImage ? '''    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/vorzela_splash"/>
    </item>
''' : ''}
</layer-list>
''');
  }

  void _writeAvd(Directory res) {
    // Android 12+ animated icon — subtle scale pulse (Material / YouTube feel).
    final v31 = Directory(p.join(res.path, 'drawable-v31'));
    if (!v31.existsSync()) v31.createSync(recursive: true);
    final avd = File(p.join(v31.path, 'vorzela_splash_avd.xml'));
    final ms = config.animationDurationMs.clamp(200, 1000);
    avd.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<animated-vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt">
    <aapt:attr name="android:drawable">
        <vector
            android:width="288dp"
            android:height="288dp"
            android:viewportWidth="288"
            android:viewportHeight="288">
            <group
                android:name="logo"
                android:pivotX="144"
                android:pivotY="144">
                <path
                    android:fillColor="#FFFFFFFF"
                    android:pathData="M144,48c-53,0 -96,43 -96,96s43,96 96,96 96,-43 96,-96 -43,-96 -96,-96z"/>
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

  void _writeStyles(Directory res) {
    final values = Directory(p.join(res.path, 'values'));
    final v31 = Directory(p.join(res.path, 'values-v31'));
    if (!v31.existsSync()) v31.createSync(recursive: true);

    final icon = config.generateAvdPulse
        ? '@drawable/vorzela_splash_avd'
        : (config.image != null
            ? '@drawable/vorzela_splash'
            : '@mipmap/ic_launcher');

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

    // Prefer bitmap icon on v31 if provided, else keep AVD.
    final a12Icon = config.android12Image != null
        ? '@drawable/vorzela_splash_a12'
        : icon;
    final styles31 = File(p.join(v31.path, 'vorzela_splash_styles.xml'));
    final iconBg = config.android12IconBackgroundColor;
    styles31.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Vorzela.Splash" parent="Theme.SplashScreen${iconBg != null ? '.IconBackground' : ''}">
        <item name="windowSplashScreenBackground">@color/vorzela_splash_background</item>
        <item name="windowSplashScreenAnimatedIcon">$a12Icon</item>
        <item name="windowSplashScreenAnimationDuration">${config.animationDurationMs.clamp(200, 1000)}</item>
${iconBg != null ? '        <item name="windowSplashScreenIconBackgroundColor">$iconBg</item>\n' : ''}        <item name="postSplashScreenTheme">@style/NormalTheme</item>
    </style>
</resources>
''');

    // Patch styles.xml LaunchTheme if present.
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
        // Also point parent toward SplashScreen when possible — leave as-is if complex.
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
