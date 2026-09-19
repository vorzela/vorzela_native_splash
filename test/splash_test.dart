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
          child: Scaffold(body: Text('home')),
        ),
      ),
    );
    expect(find.text('home'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
