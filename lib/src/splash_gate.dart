import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';

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
/// Android 12 only allows a short AVD on the system icon; the cinematic
/// brand motion happens here once Flutter paints.
class VorzelaSplashGate extends StatefulWidget {
  const VorzelaSplashGate({
    super.key,
    required this.child,
    this.logo,
    this.backgroundColor,
    this.animation = SplashExitAnimation.scaleFade,
    this.duration = const Duration(milliseconds: 700),
    this.ready,
  });

  final Widget child;
  final Widget? logo;
  final Color? backgroundColor;
  final SplashExitAnimation animation;
  final Duration duration;

  /// When complete, splash animates out. Defaults to first frame.
  final Future<void>? ready;

  @override
  State<VorzelaSplashGate> createState() => _VorzelaSplashGateState();
}

class _VorzelaSplashGateState extends State<VorzelaSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  bool _overlay = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    await widget.ready;
    await VorzelaNativeSplash.remove();
    if (!mounted) return;
    if (widget.animation == SplashExitAnimation.none) {
      setState(() => _overlay = false);
      return;
    }
    if (widget.animation == SplashExitAnimation.pulse) {
      await _c.animateTo(0.55);
      if (!mounted) return;
      await _c.animateBack(0.35);
    }
    await _c.forward();
    if (mounted) setState(() => _overlay = false);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_overlay) return widget.child;

    final bg = widget.backgroundColor ?? const Color(0xFF0F0F0F);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              final t = _t.value;
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              final scale = switch (widget.animation) {
                SplashExitAnimation.scaleFade => 1.0 + 0.12 * t,
                SplashExitAnimation.pulse => 1.0 + 0.06 * (t < 0.5 ? t * 2 : 1),
                _ => 1.0,
              };
              return Opacity(
                opacity: opacity,
                child: ColoredBox(
                  color: bg,
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: widget.logo ??
                          const Icon(Icons.circle, size: 72, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
