import 'dart:io';

import 'package:args/args.dart';
import 'package:vorzela_native_splash/src/config.dart';
import 'package:vorzela_native_splash/src/generator.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Config YAML (default: vorzela_native_splash.yaml or pubspec.yaml)',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final opts = parser.parse(args);
  if (opts['help'] == true) {
    stdout.writeln('''
vorzela_native_splash create

Generates high-DPI native splash assets + Android 12 SplashScreen /
iOS LaunchScreen wiring, and a Flutter handoff animation config.

  dart run vorzela_native_splash:create
  dart run vorzela_native_splash:create -p path/to/config.yaml
''');
    stdout.writeln(parser.usage);
    return;
  }

  final root = Directory.current.path;
  final config = SplashConfig.load(
    projectRoot: root,
    explicitPath: opts['path'] as String?,
  );
  final result = await SplashGenerator(root: root, config: config).generate();
  stdout.writeln(result.summary);
}
