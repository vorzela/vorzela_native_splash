import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

bool isTestPath(CustomLintResolver resolver) {
  final path = resolver.source.fullName.replaceAll(r'\', '/');
  return path.contains('/test/') || path.endsWith('_test.dart');
}

bool fileUsesSplashGate(String source) => source.contains('VorzelaSplashGate');

bool fileCallsRunApp(String source) => RegExp(r'\brunApp\s*\(').hasMatch(source);

bool fileCallsPreserve(String source) =>
    source.contains('VorzelaNativeSplash.preserve') ||
    RegExp(r'VorzelaNativeSplash\s*\.\s*preserve\s*\(').hasMatch(source);

bool isRawImageLogo(Expression expression) {
  if (expression is MethodInvocation) {
    final target = expression.target;
    final name = expression.methodName.name;
    if (name == 'asset' &&
        target is SimpleIdentifier &&
        target.name == 'Image') {
      return true;
    }
  }
  if (expression is InstanceCreationExpression) {
    final typeName = expression.constructorName.type.name.lexeme;
    if (typeName == 'Image') return true;
  }
  return false;
}
