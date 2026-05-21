import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animation/reward_controllers.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';

/// Coin counter with two operating modes.
///
/// 1. Auto-react mode (no [controller]): when [coinProvider] increases, the
///    counter animates from old to new value with a throttled tick sound.
/// 2. Imperative mode (with [controller]): the choreographer drives the
///    counter via [CoinChipController.countTo] / [snap] / [highlight]. Prop
///    changes from [coinProvider] snap silently — they're applied AFTER the
///    choreography completes, so the displayed value is already correct.
class AnimatedCoinCounter extends ConsumerStatefulWidget {
  final TextStyle? style;
  final String prefix;
  final CoinChipController? controller;
  const AnimatedCoinCounter({
    super.key,
    this.style,
    this.prefix = '',
    this.controller,
  });

  @override
  ConsumerState<AnimatedCoinCounter> createState() => _AnimatedCoinCounterState();
}

class _AnimatedCoinCounterState extends ConsumerState<AnimatedCoinCounter>
    with SingleTickerProviderStateMixin {
  late int _displayed;
  int _from = 0;
  int _to = 0;
  Timer? _frameTimer;
  Timer? _tickTimer;
  Completer<void>? _animCompleter;
  late final AnimationController _punch;

  @override
  void initState() {
    super.initState();
    _displayed = ref.read(coinProvider);
    _to = _displayed;
    _from = _displayed;
    _punch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _attachToken = widget.controller?.attach(
      highlight: _highlight,
      countTo: _countTo,
      snap: _snap,
    );
  }

  Object? _attachToken;

  @override
  void didUpdateWidget(covariant AnimatedCoinCounter old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      if (_attachToken != null) old.controller?.detach(_attachToken!);
      _attachToken = widget.controller?.attach(
        highlight: _highlight,
        countTo: _countTo,
        snap: _snap,
      );
    }
  }

  @override
  void dispose() {
    if (_attachToken != null) widget.controller?.detach(_attachToken!);
    _frameTimer?.cancel();
    _tickTimer?.cancel();
    _punch.dispose();
    super.dispose();
  }

  // ── Imperative API ─────────────────────────────────────────────────────

  void _highlight() {
    // The chip's surrounding container handles the visual glow (see
    // RewardOverlayHeader). The counter itself does a small punch.
    _punch.forward(from: 0).then((_) => _punch.reverse());
  }

  Future<void> _countTo(int target) {
    final prior = _animCompleter;
    if (prior != null && !prior.isCompleted) prior.complete();
    _animCompleter = Completer<void>();
    _animateTo(target, completer: _animCompleter);
    return _animCompleter!.future;
  }

  void _snap(int v) {
    _frameTimer?.cancel();
    _tickTimer?.cancel();
    if (mounted) setState(() => _displayed = v);
  }

  // ── Auto-react entry point ─────────────────────────────────────────────

  void _animateTo(int target, {Completer<void>? completer}) {
    final delta = target - _displayed;
    if (delta <= 0) {
      setState(() => _displayed = target);
      if (completer != null && !completer.isCompleted) completer.complete();
      return;
    }
    _from = _displayed;
    _to = target;
    // Duration scales with amount: 400 + delta*8 ms, capped at 1800ms.
    final durMs = (400 + delta * 8).clamp(500, 1800);
    final start = DateTime.now();
    _frameTimer?.cancel();
    _tickTimer?.cancel();

    final sound = ref.read(soundServiceProvider);
    final tickCount = delta.clamp(1, 10);
    final tickInterval = Duration(milliseconds: durMs ~/ (tickCount + 1));
    var ticksLeft = tickCount;
    _tickTimer = Timer.periodic(tickInterval, (t) {
      if (ticksLeft <= 0) {
        t.cancel();
        return;
      }
      sound.playSound(SoundType.coinTick);
      ticksLeft--;
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final raw = (elapsed / durMs).clamp(0.0, 1.0);
      // easeOutQuad
      final eased = 1 - (1 - raw) * (1 - raw);
      final v = (_from + (_to - _from) * eased).round();
      if (mounted) setState(() => _displayed = v);
      if (raw >= 1.0) {
        t.cancel();
        if (mounted) {
          setState(() => _displayed = _to);
          _punch.forward(from: 0).then((_) => _punch.reverse());
        }
        if (completer != null && !completer.isCompleted) completer.complete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch coin total. In auto-react mode (no controller) animate; in
    // imperative mode snap silently because the choreographer has already
    // moved the displayed value.
    ref.listen<int>(coinProvider, (prev, next) {
      if (prev == null) return;
      if (widget.controller != null) {
        // Imperative mode: snap. Provider write lands AFTER the choreographer
        // already drove the counter to the right value.
        if (next != _displayed) {
          setState(() => _displayed = next);
        }
        return;
      }
      // Auto-react: animate up, snap down (purchases).
      if (next > _displayed) {
        _animateTo(next);
      } else if (next != _displayed) {
        setState(() => _displayed = next);
      }
    });

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _punch, curve: Curves.easeOutBack),
      ),
      child: Text(
        '${widget.prefix}$_displayed',
        style: widget.style ?? GoogleFonts.nunito(),
      ),
    );
  }
}
