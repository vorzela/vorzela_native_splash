import 'package:flutter/material.dart';
import 'package:vorzela_native_splash/vorzela_native_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VorzelaNativeSplash.preserve();
  runApp(
    MaterialApp(
      home: VorzelaSplashGate(
        logo: SplashLogo.asset('assets/logo.png'),
        child: const Scaffold(body: Center(child: Text('App'))),
      ),
    ),
  );
}
