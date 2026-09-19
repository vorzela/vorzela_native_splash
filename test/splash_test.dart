import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorzela_native_splash/vorzela_native_splash.dart';

void main() {
  test('parseExitAnimation maps aliases', () {
    expect(parseExitAnimation('youtube'), SplashExitAnimation.scaleFade);
    expect(parseExitAnimation('fade'), SplashExitAnimation.fade);
    expect(parseExitAnimation('pulse'), SplashExitAnimation.pulse);
    expect(parseExitAnimation('none'), SplashExitAnimation.none);
  });

  testWidgets('VorzelaSplashGate shows then removes overlay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VorzelaSplashGate(
          animation: SplashExitAnimation.fade,
          duration: Duration(milliseconds: 50),
          loaderStyle: SplashLoaderStyle.none,
          child: Scaffold(body: Text('home')),
        ),
      ),
    );
    expect(find.text('home'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('shows loader under logo and optional footer', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VorzelaSplashGate(
          animation: SplashExitAnimation.none,
          loaderStyle: SplashLoaderStyle.circular,
          footerText: 'Vorzela',
          logo: const Text('LOGO'),
          ready: hold.future,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LOGO'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Vorzela'), findsOneWidget);

    // Tear down while ready is still pending — must not leak / throw.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('custom loader replaces built-in style', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VorzelaSplashGate(
          animation: SplashExitAnimation.none,
          loader: const Text('CUSTOM_LOADER'),
          loaderStyle: SplashLoaderStyle.dots,
          ready: hold.future,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('CUSTOM_LOADER'), findsOneWidget);
    expect(find.byType(SplashDotsLoader), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('loaderTheme styles circular loader', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VorzelaSplashGate(
          animation: SplashExitAnimation.none,
          loaderStyle: SplashLoaderStyle.circular,
          loaderTheme: const SplashLoaderTheme(
            color: Color(0xFFFF0000),
            size: 40,
            strokeWidth: 4,
            trackColor: Color(0x33FFFFFF),
          ),
          ready: hold.future,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pump();
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.strokeWidth, 4);
    expect(indicator.backgroundColor, const Color(0x33FFFFFF));
    expect(
      (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
      const Color(0xFFFF0000),
    );
    final box = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.width, 40);
    expect(box.height, 40);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dots loader disposes its ticker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SplashDotsLoader())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashDotsLoader), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('SplashLogo.asset uses high filter quality', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SplashLogo(
            width: 48,
            image: Image.memory(
              Uint8List.fromList(_tinyPng),
              width: 48,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.high);
    expect(image.isAntiAlias, isTrue);
  });

  test('Android 12 dimensions match Google + flutter_native_splash', () {
    expect(kAndroid12IconDp, 288);
    expect(kAndroid12IconXxxhdpiPx, 1152);
    expect(kAndroid12IconWithBgDp, 240);
    expect(kAndroid12IconWithBgXxxhdpiPx, 960);
    expect(kBrandingWidthDp, 200);
    expect(kBrandingHeightDp, 80);
    expect(kBrandingXxxhdpiWidthPx, 800);
    expect(kBrandingXxxhdpiHeightPx, 320);
    expect(android12IconDp(iconBackground: false), 288);
    expect(android12IconDp(iconBackground: true), 240);
    expect((1152 * 1 / kMasterDensity).round(), 288);
    expect((960 * 1 / kMasterDensity).round(), 240);
    final v31 = androidDensities(v31: true);
    expect(v31.keys, contains('drawable-mdpi-v31'));
    expect(v31.keys, contains('drawable-xxxhdpi-v31'));
  });
}

/// 1×1 transparent PNG.
final _tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

