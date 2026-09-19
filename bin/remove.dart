import 'dart:io';

import 'package:args/args.dart';
import 'package:vorzela_native_splash/src/generator.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts['help'] == true) {
    stdout.writeln('vorzela_native_splash remove — restore default splash stubs');
    return;
  }
  final summary = await SplashGenerator.remove(Directory.current.path);
  stdout.writeln(summary);
}
