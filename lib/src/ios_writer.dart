import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'dimensions.dart';

typedef DensifyIosFn = Future<void> Function({
  required String sourcePath,
  required String imagesetDir,
  required String baseName,
  void Function(String)? warn,
});

class IosWriter {
  IosWriter({required this.root, required this.config});

  final String root;
  final SplashConfig config;

  Future<void> write({
    required DensifyIosFn densifyIos,
    void Function(String)? warn,
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
      await densifyIos(
        sourcePath: config.image!,
        imagesetDir: imageset.path,
        baseName: 'splash',
        warn: warn,
      );
      File(p.join(imageset.path, 'Contents.json')).writeAsStringSync('''
{
  "images" : [
    { "filename" : "splash.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "splash@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "splash@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "vorzela", "version" : 1 }
}
''');
    }

    if (config.brandingImage != null) {
      final brandSet =
          Directory(p.join(assets.path, 'VorzelaBranding.imageset'));
      if (!brandSet.existsSync()) brandSet.createSync(recursive: true);
      await densifyIos(
        sourcePath: config.brandingImage!,
        imagesetDir: brandSet.path,
        baseName: 'branding',
        warn: warn,
      );
      File(p.join(brandSet.path, 'Contents.json')).writeAsStringSync('''
{
  "images" : [
    { "filename" : "branding.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "branding@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "branding@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "vorzela", "version" : 1 }
}
''');
    }

    _writeLaunchStoryboard(runner);
  }

  void _writeLaunchStoryboard(Directory runner) {
    final (r, g, b) = _rgb(config.color);
    final hasBranding = config.brandingImage != null;
    // Universal storyboard: logo centered; width ≤ 38% of canvas (tablets)
    // and ≤ 240pt (phones). Aspect-fit image scales correctly on iPad.
    File(p.join(runner.path, 'LaunchScreen.storyboard')).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21701" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_1" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21679"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView userInteractionEnabled="NO" contentMode="scaleAspectFit" image="VorzelaSplash" translatesAutoresizingMaskIntoConstraints="NO" id="logo">
                                <constraints>
                                    <constraint firstAttribute="width" secondAttribute="height" multiplier="1:1" id="aspect"/>
                                    <constraint firstAttribute="width" constant="$kIosLogoPoints" id="w-max"/>
                                </constraints>
                            </imageView>
${hasBranding ? '''                            <imageView userInteractionEnabled="NO" contentMode="scaleAspectFit" image="VorzelaBranding" translatesAutoresizingMaskIntoConstraints="NO" id="brand">
                                <constraints>
                                    <constraint firstAttribute="height" constant="40" id="bh"/>
                                    <constraint firstAttribute="width" constant="200" id="bw"/>
                                </constraints>
                            </imageView>
''' : ''}                        </subviews>
                        <color key="backgroundColor" red="$r" green="$g" blue="$b" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="logo" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="cx"/>
                            <constraint firstItem="logo" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="cy"/>
                            <constraint firstItem="logo" firstAttribute="width" secondItem="Ze5-6b-2t3" secondAttribute="width" multiplier="$kIosLogoMaxWidthFraction" relation="lessThanOrEqual" id="w-frac"/>
${hasBranding ? '''                            <constraint firstItem="brand" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="bcx"/>
                            <constraint firstItem="Ze5-6b-2t3" firstAttribute="bottom" secondItem="brand" secondAttribute="bottom" constant="28" id="bby"/>
''' : ''}                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="VorzelaSplash" width="$kIosLogoPoints" height="$kIosLogoPoints"/>
${hasBranding ? '        <image name="VorzelaBranding" width="200" height="80"/>\n' : ''}    </resources>
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
