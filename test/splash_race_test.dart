import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorzela_native_splash/vorzela_native_splash.dart';

void main() {
  testWidgets('rapid rebuild while ready pending keeps semantics stable', (tester) async {
    final handle = tester.ensureSemantics();
    final hold = Completer<void>();

    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: VorzelaSplashGate(
            animation: SplashExitAnimation.none,
            loaderStyle: SplashLoaderStyle.dots,
            semanticLabel: 'Loading pass $i',
            ready: hold.future,
            child: Scaffold(body: Text('home $i')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.bySemanticsLabel('Loading pass 4'), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('complete ready while animating exit does not throw', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VorzelaSplashGate(
          animation: SplashExitAnimation.fade,
          duration: const Duration(milliseconds: 200),
          loaderStyle: SplashLoaderStyle.none,
          ready: hold.future,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pump();
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('home'), findsOneWidget);
  });
}
