import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../animation/reward_controllers.dart';
import '../theme/app_theme.dart';

/// Animated XP bar with two operating modes.
///
/// 1. Auto-react mode (no [controller]): when [value] changes upward, the
///    bar tweens from old to new percentage automatically. Used by simple
///    callers that just want progress to animate.
/// 2. Imperative mode (with [controller]): the choreographer drives the bar
///    via [XpBarController.fillTo] / [snapTo] / [highlight]. The bar ignores
///    prop-driven changes (snaps silently) so external state updates after
///    a sequence don't trigger a second animation.
class XpBar extends StatefulWidget {
  final int value;
  final int max;
  final Duration animatedDuration;
  final VoidCallback? onFillComplete;
  final XpBarController? controller;

  const XpBar({
    super.key,
    required this.value,
    required this.max,
    this.animatedDuration = const Duration(milliseconds: 400),
    this.onFillComplete,
    this.controller,
  });

  @override
  State<XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<XpBar> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<double> _anim = const AlwaysStoppedAnimation(0);
  // Sparkle ticker drives particle motion at ~60Hz while filling.
  late final AnimationController _sparkleTicker;
  // Glow overlay controller — pulses for 400ms when highlight() is called.
  late final AnimationController _glowCtrl;
  double _displayedPct = 0;
  // Track current effective max so the bar can render correctly after a
  // level-up snap (max changes when the level changes).
  late int _effectiveMax;
  bool _isAnimating = false;
  Completer<void>? _fillCompleter;
  final List<_Sparkle> _sparkles = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _effectiveMax = widget.max;
    _displayedPct = (widget.value / widget.max).clamp(0.0, 1.0);
    _ctrl = AnimationController(vsync: this, duration: widget.animatedDuration);
    _sparkleTicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _sparkleTicker.addListener(_onSparkleTick);

    _attachToken = widget.controller?.attach(
      highlight: _highlight,
      fillTo: _fillTo,
      snap: _snapTo,
    );
  }

  Object? _attachToken;

  @override
  void didUpdateWidget(covariant XpBar old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      if (_attachToken != null) old.controller?.detach(_attachToken!);
      _attachToken = widget.controller?.attach(
        highlight: _highlight,
        fillTo: _fillTo,
        snap: _snapTo,
      );
    }

    // Imperative mode: prop changes snap silently so post-choreography state
    // updates don't trigger a second animation.
    if (widget.controller != null) {
      final newPct = (widget.value / widget.max).clamp(0.0, 1.0);
      if (!_isAnimating && (newPct != _displayedPct || widget.max != _effectiveMax)) {
        setState(() {
          _displayedPct = newPct;
          _effectiveMax = widget.max;
        });
      }
      return;
    }

    // Auto-react mode: animate to the new prop value.
    final newPct = (widget.value / widget.max).clamp(0.0, 1.0);
    if (newPct != _displayedPct && !_isAnimating) {
      _ctrl.duration = widget.animatedDuration;
      _anim = Tween<double>(begin: _displayedPct, end: newPct).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _isAnimating = true;
      _sparkles.clear();
      _ctrl
        ..reset()
        ..forward();
      _sparkleTicker.repeat();
    } else if (!_isAnimating && newPct != _displayedPct) {
      // Backwards/instant change (e.g. level reset) — snap.
      setState(() {
        _displayedPct = newPct;
        _effectiveMax = widget.max;
      });
    }
  }

  // ── Imperative API (for the controller) ────────────────────────────────

  void _highlight() {
    _glowCtrl.forward(from: 0).then((_) => _glowCtrl.reverse());
  }

  Future<void> _fillTo(double pct, {required Duration duration}) {
    pct = pct.clamp(0.0, 1.0);
    // Settle any prior completer safely (could already be completed).
    final prior = _fillCompleter;
    if (prior != null && !prior.isCompleted) prior.complete();
    _fillCompleter = Completer<void>();
    _ctrl.duration = duration;
    _anim = Tween<double>(begin: _displayedPct, end: pct).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _isAnimating = true;
    _sparkles.clear();
    _ctrl
      ..reset()
      ..forward();
    _sparkleTicker.repeat();
    return _fillCompleter!.future;
  }

  void _snapTo(double pct, {required int newMax}) {
    pct = pct.clamp(0.0, 1.0);
    _ctrl.stop();
    _sparkleTicker.stop();
    _isAnimating = false;
    setState(() {
      _displayedPct = pct;
      _effectiveMax = newMax;
      _sparkles.clear();
    });
    final prior = _fillCompleter;
    if (prior != null && !prior.isCompleted) prior.complete();
    _fillCompleter = null;
  }

  // ── Animation listeners ────────────────────────────────────────────────

  void _onTick() {
    setState(() => _displayedPct = _anim.value);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isAnimating = false;
      _sparkleTicker.stop();
      // Let lingering sparkles fade.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(_sparkles.clear);
      });
      final completer = _fillCompleter;
      _fillCompleter = null;
      if (completer != null && !completer.isCompleted) completer.complete();
      widget.onFillComplete?.call();
    }
  }

  void _onSparkleTick() {
    // Spawn a few new sparkles per tick from the leading edge.
    if (_isAnimating && _rng.nextDouble() < 0.6) {
      _sparkles.add(_Sparkle(
        pct: _displayedPct,
        offsetY: -2 + _rng.nextDouble() * 6,
        vx: -10 + _rng.nextDouble() * 20,
        vy: -20 - _rng.nextDouble() * 25,
        life: 0,
        size: 1.4 + _rng.nextDouble() * 1.6,
      ));
    }
    // Advance + cull existing sparkles.
    for (final s in _sparkles) {
      s.life += 1 / 30; // ~30 frames lifespan
      s.offsetY += s.vy * (1 / 60);
      s.vy += 30 * (1 / 60); // gravity
    }
    _sparkles.removeWhere((s) => s.life >= 1.0);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_attachToken != null) widget.controller?.detach(_attachToken!);
    _ctrl.dispose();
    _sparkleTicker.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        // Glow halo intensity 0..1 maps to a soft yellow box-shadow that
        // peaks mid-animation.
        final glow = _glowCtrl.value;
        return Container(
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: glow > 0
                  ? Color.lerp(Colors.black.withOpacity(.4), AppColors.yellow, glow)!
                  : Colors.black.withOpacity(.4),
              width: 2,
            ),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.55 * glow),
                      blurRadius: 16 * glow,
                      spreadRadius: 2 * glow,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w     = constraints.maxWidth;
                final fillW = w * _displayedPct;
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      width: fillW,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.yellow, AppColors.pink, AppColors.hotPink],
                            stops: [0, .6, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0, top: 2,
                      height: 3,
                      width: fillW * .6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (_isAnimating && fillW > 4)
                      Positioned(
                        left: fillW - 6, top: -2, bottom: -2,
                        width: 12,
                        child: IgnorePointer(
                          child: CustomPaint(painter: _FuseEdgePainter()),
                        ),
                      ),
                    if (_sparkles.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _SparklePainter(_sparkles, w),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Sparkle {
  double pct;
  double offsetY;
  double vx;
  double vy;
  double life; // 0 → 1
  double size;
  _Sparkle({
    required this.pct,
    required this.offsetY,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
  });
}

class _FuseEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          AppColors.yellow,
          AppColors.yellow.withOpacity(0.0),
        ],
        stops: const [0, .35, 1],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, size.height / 2),
        width: size.width * 1.4,
        height: size.height * 1.6,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height / 2),
        width: size.width,
        height: size.height * 1.4,
      ),
      glow,
    );
    final core = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), core);
  }

  @override
  bool shouldRepaint(_FuseEdgePainter old) => true;
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double widthPx;
  _SparklePainter(this.sparkles, this.widthPx);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final x = (s.pct * widthPx).clamp(0.0, widthPx);
      final y = size.height / 2 + s.offsetY;
      final alpha = (1.0 - s.life).clamp(0.0, 1.0);
      final paint = Paint()..color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), s.size * (1 - s.life * 0.4), paint);
      paint.color = AppColors.yellow.withOpacity(alpha * 0.5);
      canvas.drawCircle(Offset(x, y), s.size * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => true;
}
