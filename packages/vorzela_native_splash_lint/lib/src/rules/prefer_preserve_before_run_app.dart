import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

class PreferPreserveBeforeRunApp extends DartLintRule {
  const PreferPreserveBeforeRunApp() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_preserve_before_run_app',
    problemMessage:
        'Call VorzelaNativeSplash.preserve() before runApp when using VorzelaSplashGate.',
    correctionMessage:
        'In main(), await VorzelaNativeSplash.preserve() before runApp(...).',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isTestPath(resolver)) return;
    final src = resolver.source.contents.data;
    if (!fileUsesSplashGate(src) || !fileCallsRunApp(src)) return;
    if (fileCallsPreserve(src)) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'runApp') return;
      reporter.atNode(node.methodName, code);
    });
  }
}
