import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils.dart';

class PreferSplashLogo extends DartLintRule {
  const PreferSplashLogo() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_splash_logo',
    problemMessage:
        'Use SplashLogo for VorzelaSplashGate.logo — not raw Image / Image.asset.',
    correctionMessage: 'logo: SplashLogo.asset(\'assets/logo.png\'),',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isTestPath(resolver)) return;
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (typeName != 'VorzelaSplashGate') return;
      for (final arg in node.argumentList.arguments) {
        if (arg is! NamedExpression) continue;
        if (arg.name.label.name != 'logo') continue;
        if (isRawImageLogo(arg.expression)) {
          reporter.atNode(arg.expression, code);
        }
      }
    });
  }
}
