import 'package:flutter/material.dart';
import 'package:vorzela_native_splash/vorzela_native_splash.dart';

void main() {
  // expect_lint: prefer_preserve_before_run_app
  runApp(
    MaterialApp(
      home: VorzelaSplashGate(
        // expect_lint: prefer_splash_logo
        logo: Image.asset('assets/logo.png'),
        child: const Scaffold(body: Center(child: Text('App'))),
      ),
    ),
  );
}
