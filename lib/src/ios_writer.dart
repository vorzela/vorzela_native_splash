import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'config.dart';

class IosWriter {
  IosWriter({required this.root, required this.config});

  final String root;
  final SplashConfig config;

  Future<void> write({
    required Future<void> Function({
      required String? sourcePath,
      required String outRoot,
      required String fileName,
      required int baseDp,
      Map<String, double>? folders,
    }) densify,
  }) async {
    final runner = Directory(p.join(root, 'ios', 'Runner'));
    if (!runner.existsSync()) {
      stdout.writeln('⚠ No ios/Runner — skipping iOS');
      return;
    }

    final assets = Directory(p.join(runner.path, 'Assets.xcassets'));
    final imageset = Directory(p.join(assets.path, 'VorzelaSplash.imageset'));
    if (!imageset.existsSync()) imageset.createSync(recursive: true);

    if (config.image != null) {
      await _writeScaledPng(config.image!, p.join(imageset.path, 'splash.png'), 200);
      await _writeScaledPng(
        config.image!,
        p.join(imageset.path, 'wendy.h@example.net'),
        400,
      );
      await _writeScaledPng(
        config.image!,
        p.join(imageset.path, 'frank.g@example.org'),
        600,
      );
      File(p.join(imageset.path, 'Contents.json')).writeAsStringSync('''
{
  "images" : [
    { "filename" : "splash.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "wendy.h@example.net", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "frank.g@example.org", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "vorzela", "version" : 1 }
}
''');
    }

    _writeLaunchStoryboard(runner);
  }

  Future<void> _writeScaledPng(String source, String outPath, int px) async {
    final src = File(p.isAbsolute(source) ? source : p.join(root, source));
    if (!src.existsSync()) {
      throw StateError('Image not found: ${src.path}');
    }
    final decoded = img.decodeImage(await src.readAsBytes());
    if (decoded == null) throw StateError('Decode failed: ${src.path}');
    final resized = img.copyResize(
      decoded,
      width: px,
      height: px,
      interpolation: img.Interpolation.cubic,
    );
    await File(outPath).writeAsBytes(img.encodePng(resized));
  }

  void _writeLaunchStoryboard(Directory runner) {
    final (r, g, b) = _rgb(config.color);
    File(p.join(runner.path, 'LaunchScreen.storyboard')).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="12121" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="12089"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView userInteractionEnabled="NO" contentMode="scaleAspectFit" image="VorzelaSplash" translatesAutoresizingMaskIntoConstraints="NO" id="logo">
                                <constraints>
                                    <constraint firstAttribute="width" constant="200" id="w1"/>
                                    <constraint firstAttribute="height" constant="200" id="h1"/>
                                </constraints>
                            </imageView>
                        </subviews>
                        <color key="backgroundColor" red="$r" green="$g" blue="$b" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="logo" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="cx"/>
                            <constraint firstItem="logo" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="cy"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" sceneMemberID="firstResponder"/>
            </objects>
        </scene>
    </scenes>
    <resources>
        <image name="VorzelaSplash" width="200" height="200"/>
    </resources>
</document>
''');
  }

  (String, String, String) _rgb(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length != 6) return ('0.000', '0.000', '0.000');
    final r = int.parse(h.substring(0, 2), radix: 16) / 255.0;
    final g = int.parse(h.substring(2, 4), radix: 16) / 255.0;
    final b = int.parse(h.substring(4, 6), radix: 16) / 255.0;
    return (r.toStringAsFixed(3), g.toStringAsFixed(3), b.toStringAsFixed(3));
  }
}
