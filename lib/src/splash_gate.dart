import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'loaders.dart';

/// Keeps / dismisses the OS splash (Android 12 SplashScreen compat).
///
/// Optional: wire a tiny platform plugin that calls `installSplashScreen()` +
/// `setKeepOnScreenCondition`. Without it, [VorzelaSplashGate] still covers
/// the Flutter handoff animation.
class VorzelaNativeSplash {
  static const _channel = MethodChannel('vorzela_native_splash');

  static Future<void> preserve() async {
    try {
      await _channel.invokeMethod<void>('preserve');
    } on MissingPluginException {
      // Overlay gate still provides a seamless handoff.
    }
  }

  static Future<void> remove() async {
    try {
      await _channel.invokeMethod<void>('remove');
    } on MissingPluginException {
      // no-op
    }
  }
}

/// Flutter brand animation after the OS splash (Gmail / YouTube style).
///
/// Layout: centered [logo], optional [loader] under the logo, optional
/// [footer] / [footerText] pinned to the bottom safe area.
///
/// Controllers and curved animations are disposed; async exit work is gated
/// so it cannot [setState] or drive tickers after [dispose].
class VorzelaSplashGate extends StatefulWidget {
  const VorzelaSplashGate({
    super.key,
    required this.child,
    this.logo,
    this.loader,
    this.loaderStyle = SplashLoaderStyle.circular,
    this.loaderTheme = const SplashLoaderTheme(),
    this.loaderColor,
    this.logoLoaderGap = 28,
    this.footer,
    this.footerText,
    this.footerStyle,
    this.footerPadding = const EdgeInsets.fromLTRB(24, 0, 24, 28),
    this.backgroundColor,
    this.animation = SplashExitAnimation.scaleFade,
    this.duration = const Duration(milliseconds: 700),
    this.ready,
    this.semanticLabel = 'Loading',
  });

  final Widget child;
  final Widget? logo;

  /// Custom loader widget under the logo. When null, [loaderStyle] is used
  /// (pass [SplashLoaderStyle.none] for no loader).
  final Widget? loader;

  /// Built-in loader when [loader] is null.
  final SplashLoaderStyle loaderStyle;

  /// Size / stroke / track / dots styling for [loaderStyle].
  ///
  /// Ignored when [loader] is set. Example:
  /// ```dart
  /// loaderStyle: SplashLoaderStyle.circular,
  /// loaderTheme: SplashLoaderTheme(
  ///   color: Color(0xFFFF0000),
  ///   size: 36,
  ///   strokeWidth: 3,
  ///   trackColor: Colors.white24,
  /// ),
  /// ```
  final SplashLoaderTheme loaderTheme;

  /// Convenience tint for built-in loaders (overrides [loaderTheme.color]).
  /// Defaults to white @ 85% when both are null.
  final Color? loaderColor;

  /// Space between logo and loader.
  final double logoLoaderGap;

  /// Optional custom footer (bottom). Takes precedence over [footerText].
  final Widget? footer;

  /// Optional bottom caption (e.g. “Loading…”, legal line, version).
  final String? footerText;

  final TextStyle? footerStyle;
  final EdgeInsetsGeometry footerPadding;

  final Color? backgroundColor;
  final SplashExitAnimation animation;
  final Duration duration;

  /// When complete, splash animates out. Defaults to first frame.
  final Future<void>? ready;

  /// Accessibility label for the splash overlay while visible.
  final String semanticLabel;

  @override
  State<VorzelaSplashGate> createState() => _VorzelaSplashGateState();
}

class _VorzelaSplashGateState extends State<VorzelaSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _t;
  bool _overlay = true;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_alive) _run();
    });
  }

  Future<void> _run() async {
    try {
      await widget.ready;
      if (!_alive) return;
      await VorzelaNativeSplash.remove();
      if (!_alive || !mounted) return;

      if (widget.animation == SplashExitAnimation.none) {
        _dismissOverlay();
        return;
      }
      if (widget.animation == SplashExitAnimation.pulse) {
        await _c.animateTo(0.55);
        if (!_alive || !mounted) return;
        await _c.animateBack(0.35);
        if (!_alive || !mounted) return;
      }
      await _c.forward();
      if (!_alive || !mounted) return;
      _dismissOverlay();
    } on TickerCanceled {
      // Disposed mid-animation — expected, not a leak.
    }
  }

  void _dismissOverlay() {
    if (!_alive || !mounted) return;
    _c.stop();
    setState(() => _overlay = false);
  }

  @override
  void dispose() {
    _alive = false;
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  Widget? _resolveLoader(SplashLoaderTheme theme) {
    if (widget.loader != null) return widget.loader;
    return switch (widget.loaderStyle) {
      SplashLoaderStyle.none => null,
      SplashLoaderStyle.circular => SplashCircularLoader.fromTheme(theme),
      SplashLoaderStyle.dots => SplashDotsLoader.fromTheme(theme),
      SplashLoaderStyle.linear => SplashLinearLoader.fromTheme(theme),
    };
  }

  Widget? _resolveFooter() {
    if (widget.footer != null) return widget.footer;
    final text = widget.footerText;
    if (text == null || text.isEmpty) return null;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: widget.footerStyle ??
          TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            height: 1.3,
            letterSpacing: 0.2,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_overlay) return widget.child;

    final bg = widget.backgroundColor ?? const Color(0xFF0F0F0F);
    final theme = widget.loaderTheme.copyWith(
      color: widget.loaderColor ??
          widget.loaderTheme.color ??
          Colors.white.withValues(alpha: 0.85),
    );
    final loader = _resolveLoader(theme);
    final footer = _resolveFooter();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Semantics(
            label: widget.semanticLabel,
            liveRegion: true,
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) {
                final t = _t.value;
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final scale = switch (widget.animation) {
                  SplashExitAnimation.scaleFade => 1.0 + 0.12 * t,
                  SplashExitAnimation.pulse =>
                    1.0 + 0.06 * (t < 0.5 ? t * 2 : 1),
                  _ => 1.0,
                };
                return Opacity(
                  opacity: opacity,
                  child: ColoredBox(
                    color: bg,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widget.logo ??
                                    const ExcludeSemantics(
                                      child: Icon(
                                        Icons.circle,
                                        size: 72,
                                        color: Colors.white,
                                      ),
                                    ),
                                if (loader != null) ...[
                                  SizedBox(height: widget.logoLoaderGap),
                                  loader,
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (footer != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: bottomInset,
                            child: Padding(
                              padding: widget.footerPadding,
                              child: footer,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
