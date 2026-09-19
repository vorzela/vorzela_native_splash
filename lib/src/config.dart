import 'package:yaml/yaml.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Exit animation after the OS splash hands off to Flutter.
///
/// Native Android 12 can only run a short AVD on the system icon; Gmail /
/// YouTube-style brand motion happens in Flutter (this package).
enum SplashExitAnimation {
  /// Instant remove (no Flutter overlay).
  none,

  /// Soft opacity fade (Gmail-like settle).
  fade,

  /// Scale up slightly then fade (YouTube / Material motion).
  scaleFade,

  /// Gentle pulse then fade (brand heartbeat).
  pulse,
}

SplashExitAnimation parseExitAnimation(String? raw) {
  switch ((raw ?? 'scale_fade').toLowerCase().replaceAll('-', '_')) {
    case 'none':
      return SplashExitAnimation.none;
    case 'fade':
      return SplashExitAnimation.fade;
    case 'pulse':
      return SplashExitAnimation.pulse;
    case 'scale_fade':
    case 'youtubescale':
    case 'youtube':
    default:
      return SplashExitAnimation.scaleFade;
  }
}

class SplashConfig {
  SplashConfig({
    required this.color,
    this.colorDark,
    this.image,
    this.imageDark,
    this.brandingImage,
    this.android12Image,
    this.android12IconBackgroundColor,
    this.animationDurationMs = 800,
    this.exitAnimation = SplashExitAnimation.scaleFade,
    this.android = true,
    this.ios = true,
    this.fullscreen = false,
    this.generateAvdPulse = true,
  });

  final String color;
  final String? colorDark;
  final String? image;
  final String? imageDark;
  final String? brandingImage;
  final String? android12Image;
  final String? android12IconBackgroundColor;
  final int animationDurationMs;
  final SplashExitAnimation exitAnimation;
  final bool android;
  final bool ios;
  final bool fullscreen;

  /// Emit a simple scale AVD for Android 12+ animated icon.
  final bool generateAvdPulse;

  static SplashConfig load({
    required String projectRoot,
    String? explicitPath,
  }) {
    final candidates = <String>[
      if (explicitPath != null) explicitPath,
      p.join(projectRoot, 'vorzela_native_splash.yaml'),
      p.join(projectRoot, 'pubspec.yaml'),
    ];

    Map<String, dynamic>? block;
    String? used;
    for (final path in candidates) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final doc = loadYaml(file.readAsStringSync());
      if (doc is! YamlMap) continue;
      final raw = doc['vorzela_native_splash'] ?? doc['flutter_native_splash'];
      if (raw is YamlMap) {
        block = Map<String, dynamic>.from(raw);
        used = path;
        break;
      }
    }

    if (block == null) {
      throw StateError(
        'No vorzela_native_splash: block found. Create '
        'vorzela_native_splash.yaml or add it to pubspec.yaml',
      );
    }

    String? reqColor = block['color']?.toString();
    if (reqColor == null || reqColor.isEmpty) {
      throw StateError('vorzela_native_splash.color is required (e.g. "#0F0F0F")');
    }
    if (!reqColor.startsWith('#')) reqColor = '#$reqColor';

    stdout.writeln('Using config: $used');

    final a12 = block['android_12'];
    Map<String, dynamic>? a12Map;
    if (a12 is YamlMap) a12Map = Map<String, dynamic>.from(a12);

    return SplashConfig(
      color: reqColor,
      colorDark: _color(block['color_dark']),
      image: block['image']?.toString(),
      imageDark: block['image_dark']?.toString(),
      brandingImage: block['branding']?.toString() ??
          block['branding_image']?.toString(),
      android12Image: a12Map?['image']?.toString() ?? block['image']?.toString(),
      android12IconBackgroundColor: _color(a12Map?['icon_background_color']),
      animationDurationMs:
          int.tryParse('${block['animation_duration'] ?? 800}') ?? 800,
      exitAnimation: parseExitAnimation(block['exit_animation']?.toString()),
      android: block['android'] != false,
      ios: block['ios'] != false,
      fullscreen: block['fullscreen'] == true,
      generateAvdPulse: block['android_12_animated_icon'] != false,
    );
  }

  static String? _color(Object? v) {
    if (v == null) return null;
    var s = v.toString();
    if (!s.startsWith('#')) s = '#$s';
    return s;
  }
}
