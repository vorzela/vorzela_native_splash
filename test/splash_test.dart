import 'dart:async';

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
}
