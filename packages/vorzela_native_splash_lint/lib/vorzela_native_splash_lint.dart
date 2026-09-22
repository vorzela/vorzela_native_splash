import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/prefer_preserve_before_run_app.dart';
import 'src/rules/prefer_splash_logo.dart';

/// Entrypoint for `custom_lint` — must stay `createPlugin` in this library.
PluginBase createPlugin() => _VorzelaNativeSplashLint();

class _VorzelaNativeSplashLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const PreferPreserveBeforeRunApp(),
        const PreferSplashLogo(),
      ];
}
