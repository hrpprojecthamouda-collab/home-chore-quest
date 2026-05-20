import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animation/reward_controllers.dart';
import '../providers/inventory_providers.dart';

// Glyph lookup shared across Pip preview and home screen overlay
const pipItemGlyphs = <String, String>{
  // Hats — themed roofs
  'roof_tile_red':   '🏠',
  'roof_tile_blue':  '🏘️',
  'roof_thatch':     '🌾',
  'roof_greek':      '🏛️',
  'roof_japanese':   '⛩️',
  // Costumes
  'costume_brick':    '🧱',
  'costume_wood':     '🪵',
  'costume_stone':    '🪨',
  'costume_garden':   '🌷',
  'costume_tuxedo':   '🤵',
  'costume_overalls': '👖',
  'costume_kimono':   '👘',
  'costume_armor':    '🛡️',
};

class PipMascot extends StatefulWidget {
  final double size;
  final bool hat;
  final bool wave;
  final String mood; // 'happy' | 'sleep'
  final PipController? controller;

  const PipMascot({
    super.key,
    this.size = 80,
    this.hat = false,
    this.wave = false,
    this.mood = 'happy',
    this.controller,
  });

  @override
  State<PipMascot> createState() => _PipMascotState();
}

class _PipMascotState extends State<PipMascot>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final Animation<double> _waveAnim;
  // Drives the celebration reaction: jump + squash + glow halo + sparkles,
  // ~700ms. Triggered by the choreographer via PipController.reactHappy().
  late final AnimationController _reactCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);
    if (widget.wave) _waveCtrl.repeat(reverse: true);

    _reactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    widget.controller?.attach(() async {
      await _reactCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(PipMascot old) {
    super.didUpdateWidget(old);
    if (widget.wave != old.wave) {
      if (widget.wave) {
        _waveCtrl.repeat(reverse: true);
      } else {
        _waveCtrl.stop();
        _waveCtrl.value = 0;
      }
    }
    if (widget.controller != old.controller) {
      old.controller?.detach();
      widget.controller?.attach(() async {
        await _reactCtrl.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _waveCtrl.dispose();
    _reactCtrl.dispose();
    super.dispose();
  }

  // Jump trajectory — parabola peaking at t≈0.45 at -22 (height proportional
  // to Pip's size so it scales with her). Returns a vertical offset in
  // logical pixels (negative = up).
  double _reactJump(double t) {
    if (t <= 0 || t >= 1) return 0;
    // Asymmetric parabola: longer take-off, snappier landing.
    final shifted = (t - 0.45) / 0.55;
    final tri = 1.0 - shifted * shifted;
    return -widget.size * 0.30 * tri.clamp(0.0, 1.0);
  }

  // Anisotropic scale: small squash on takeoff/landing, stretch at peak.
  // Returns (scaleX, scaleY). At rest both = 1.
  (double, double) _reactSquash(double t) {
    if (t <= 0 || t >= 1) return (1, 1);
    // Takeoff squash (compress vertically): peaks at t≈0.10
    final takeoff = (1 - (t - 0.10).abs() * 12).clamp(0.0, 1.0);
    // Air-stretch (slim vertically up): peaks at t≈0.45
    final stretch = (1 - (t - 0.45).abs() * 4).clamp(0.0, 1.0);
    // Landing squash: peaks at t≈0.85
    final landing = (1 - (t - 0.85).abs() * 10).clamp(0.0, 1.0);

    final sx = 1.0 + 0.10 * takeoff - 0.08 * stretch + 0.12 * landing;
    final sy = 1.0 - 0.12 * takeoff + 0.12 * stretch - 0.10 * landing;
    return (sx, sy);
  }

  // Glow halo opacity 0 → peak → 0, peaking around mid-jump.
  double _reactGlow(double t) {
    if (t <= 0 || t >= 1) return 0;
    final tri = 1.0 - (t - 0.45).abs() / 0.45;
    return Curves.easeOutCubic.transform(tri.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnim, _reactCtrl]),
      builder: (_, __) {
        final t = _reactCtrl.value;
        final jump = _reactJump(t);
        final (sx, sy) = _reactSquash(t);
        final glow = _reactGlow(t);
        // Widget size stays exactly size × size so callers' layout math is
        // unaffected. Glow + sparkles are painted via OverflowBox so they
        // can spill into the surrounding Stack/Positioned space.
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glow halo + sparkles behind Pip — overflow the bounds so
              // the celebration is visible regardless of where Pip is placed.
              if (glow > 0)
                Positioned.fill(
                  child: OverflowBox(
                    maxWidth: widget.size * 2.4,
                    maxHeight: widget.size * 2.4,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PipReactionOverlay(t: t, glow: glow),
                      ),
                    ),
                  ),
                ),
              // Pip body: jump + squash, with the body itself anchored to
              // the bottom so the jump reads as her leaving the ground.
              Transform.translate(
                offset: Offset(0, jump),
                child: Transform.scale(
                  scaleX: sx,
                  scaleY: sy,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: _PipPainter(
                        hat: widget.hat,
                        waveT: _waveAnim.value,
                        mood: widget.mood,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Painted overlay drawn behind Pip during the celebration reaction: a
// concentric glow halo + 5 sparkle particles that radiate outward.
class _PipReactionOverlay extends CustomPainter {
  final double t;     // 0..1 reaction progress
  final double glow;  // 0..1 halo intensity (derived from t)

  const _PipReactionOverlay({required this.t, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pipRadius = math.min(size.width, size.height) / 2 / 2.4;

    // ── Glow halo: layered radial gradient, scaling up as it fades.
    final haloR = pipRadius * (1.4 + 0.9 * t);
    final haloRect = Rect.fromCircle(center: Offset(cx, cy), radius: haloR);
    canvas.drawCircle(
      Offset(cx, cy),
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE066).withOpacity(0.55 * glow),
            const Color(0xFFFFB347).withOpacity(0.30 * glow),
            const Color(0xFFFF6BAA).withOpacity(0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(haloRect),
    );

    // Soft inner core
    canvas.drawCircle(
      Offset(cx, cy),
      pipRadius * 1.1,
      Paint()
        ..color = Colors.white.withOpacity(0.18 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Sparkle particles radiating outward.
    // Five star sparkles at fixed angles, each riding out then in.
    const sparkleCount = 5;
    final sparkleR = pipRadius * (0.9 + 1.1 * t);
    // Each sparkle fades in 0.1..0.7 of the reaction.
    final sparkleAlpha =
        Curves.easeOutCubic.transform((t * 1.4).clamp(0.0, 1.0)) *
        (1 - Curves.easeInCubic.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0)));

    for (int i = 0; i < sparkleCount; i++) {
      final a = (i / sparkleCount) * 2 * math.pi - math.pi / 2;
      final px = cx + math.cos(a) * sparkleR;
      final py = cy + math.sin(a) * sparkleR;
      _drawSparkle(canvas, Offset(px, py), pipRadius * 0.18, sparkleAlpha);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, double alpha) {
    if (alpha <= 0) return;
    final color = const Color(0xFFFFE066).withOpacity(alpha.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.35;
    // Four-point star: a vertical line and a horizontal line, plus a small
    // center dot for a sharper sparkle look.
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
    canvas.drawCircle(c, r * 0.22, Paint()..color = Colors.white.withOpacity(alpha.clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(_PipReactionOverlay old) =>
      old.t != t || old.glow != glow;
}

class _PipPainter extends CustomPainter {
  final bool hat;
  final double waveT; // 0..1
  final String mood;  // 'happy' | 'sleep'

  const _PipPainter({required this.hat, this.waveT = 0, this.mood = 'happy'});

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Wave arm — drawn behind body
    if (waveT > 0) {
      canvas.save();
      canvas.translate(w * 0.74, h * 0.54);
      final angle = (-0.45 + waveT * 1.1) * (math.pi / 2);
      canvas.rotate(angle);
      // Upper arm
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.035, -h * 0.18, w * 0.07, h * 0.18),
          Radius.circular(w * 0.035),
        ),
        _fill(const Color(0xFF9D5CFF)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.035, -h * 0.18, w * 0.07, h * 0.18),
          Radius.circular(w * 0.035),
        ),
        _stroke(const Color(0xFF1A1030), w * 0.02),
      );
      // Hand circle
      canvas.drawCircle(Offset(0, -h * 0.20), w * 0.055, _fill(const Color(0xFFC98AFF)));
      canvas.drawCircle(Offset(0, -h * 0.20), w * 0.055, _stroke(const Color(0xFF1A1030), w * 0.018));
      canvas.restore();
    }

    // Body — square rounded RRect
    final bodyRect = Rect.fromCenter(
      center: Offset(w * .5, h * .60),
      width: w * .72,
      height: h * .68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * .16)),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.2, -.3),
          radius: .7,
          colors: const [Color(0xFFC98AFF), Color(0xFF9D5CFF), Color(0xFF5B2EB5)],
          stops: const [.0, .6, 1.0],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * .16)),
      _stroke(const Color(0xFF1A1030), w * .022),
    );

    // Belly highlight
    final bellyRect = Rect.fromCenter(
      center: Offset(w * .5, h * .68),
      width: w * .44,
      height: h * .36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bellyRect, Radius.circular(w * .10)),
      _fill(const Color(0xFFC98AFF).withOpacity(.45)),
    );

    if (mood == 'sleep') {
      // Squiggle closed eyes
      final eyeL = Path()
        ..moveTo(w * .33, h * .52)
        ..quadraticBezierTo(w * .375, h * .47, w * .42, h * .52);
      canvas.drawPath(eyeL, _stroke(const Color(0xFF1A1030), w * .028));
      final eyeR = Path()
        ..moveTo(w * .58, h * .52)
        ..quadraticBezierTo(w * .625, h * .47, w * .67, h * .52);
      canvas.drawPath(eyeR, _stroke(const Color(0xFF1A1030), w * .028));
    } else {
      // Eyes white
      canvas.drawCircle(Offset(w * .38, h * .52), w * .06, _fill(Colors.white));
      canvas.drawCircle(Offset(w * .62, h * .52), w * .06, _fill(Colors.white));
      // Pupils
      canvas.drawCircle(Offset(w * .39, h * .53), w * .03, _fill(const Color(0xFF1A1030)));
      canvas.drawCircle(Offset(w * .63, h * .53), w * .03, _fill(const Color(0xFF1A1030)));
      // Eye shine
      canvas.drawCircle(Offset(w * .40, h * .515), w * .01, _fill(Colors.white));
      canvas.drawCircle(Offset(w * .64, h * .515), w * .01, _fill(Colors.white));
    }

    // Cheeks
    canvas.drawCircle(Offset(w * .32, h * .64), w * .04, _fill(const Color(0xFFFF4D8D).withOpacity(.65)));
    canvas.drawCircle(Offset(w * .68, h * .64), w * .04, _fill(const Color(0xFFFF4D8D).withOpacity(.65)));

    // Mouth
    final mouth = Path()
      ..moveTo(w * .44, h * .66)
      ..quadraticBezierTo(w * .5, h * (mood == 'sleep' ? .69 : .72), w * .56, h * .66);
    canvas.drawPath(mouth, _stroke(const Color(0xFF1A1030), w * .025));

    if (hat) {
      final hatFill = _fill(const Color(0xFFFFD23F));
      final hatOutline = _stroke(const Color(0xFF1A1030), w * .02);
      final hatPath = Path()
        ..moveTo(w * .5, h * .12)
        ..lineTo(w * .62, h * .32)
        ..lineTo(w * .38, h * .32)
        ..close();
      canvas.drawPath(hatPath, hatFill);
      canvas.drawPath(hatPath, hatOutline);
      canvas.drawCircle(Offset(w * .5, h * .10), w * .03, _fill(const Color(0xFFFF4D8D)));
    }
  }

  @override
  bool shouldRepaint(_PipPainter old) =>
      old.hat != hat || old.waveT != waveT || old.mood != mood;
}

// Pip with painted accessory overlays.
// If [equipped] is provided it is used directly; otherwise reads equippedPipProvider.
//
// The celebration reaction (jump + squash + glow halo + sparkles) is hosted
// at this level — not inside the inner [PipMascot] — so the equipped hat and
// costume travel with the body. When a [controller] is attached, the inner
// PipMascot is told NOT to react (to avoid double-animating).
class PipWithItems extends ConsumerStatefulWidget {
  final double size;
  final Map<String, String>? equipped;
  final PipController? controller;
  // Forwarded to the inner PipMascot so callers can drop in PipWithItems
  // wherever they used PipMascot before.
  final bool hat;   // legacy yellow triangle hat (used by celebration only)
  final bool wave;
  final String mood; // 'happy' | 'sleep'

  const PipWithItems({
    super.key,
    this.size = 80,
    this.equipped,
    this.controller,
    this.hat = false,
    this.wave = false,
    this.mood = 'happy',
  });

  @override
  ConsumerState<PipWithItems> createState() => _PipWithItemsState();
}

class _PipWithItemsState extends ConsumerState<PipWithItems>
    with SingleTickerProviderStateMixin {
  // Drives the celebration reaction at the OUTER level so the body + hat
  // + costume all transform together. Same duration/curves as PipMascot's
  // reaction so callers see consistent timing.
  late final AnimationController _reactCtrl;

  @override
  void initState() {
    super.initState();
    _reactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    widget.controller?.attach(() async {
      await _reactCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(PipWithItems old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?.detach();
      widget.controller?.attach(() async {
        await _reactCtrl.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _reactCtrl.dispose();
    super.dispose();
  }

  // ── Reaction curves (identical to PipMascot's so timing matches when used
  //    standalone without PipWithItems).
  double _reactJump(double t) {
    if (t <= 0 || t >= 1) return 0;
    final shifted = (t - 0.45) / 0.55;
    final tri = 1.0 - shifted * shifted;
    return -widget.size * 0.30 * tri.clamp(0.0, 1.0);
  }

  (double, double) _reactSquash(double t) {
    if (t <= 0 || t >= 1) return (1, 1);
    final takeoff = (1 - (t - 0.10).abs() * 12).clamp(0.0, 1.0);
    final stretch = (1 - (t - 0.45).abs() * 4).clamp(0.0, 1.0);
    final landing = (1 - (t - 0.85).abs() * 10).clamp(0.0, 1.0);
    final sx = 1.0 + 0.10 * takeoff - 0.08 * stretch + 0.12 * landing;
    final sy = 1.0 - 0.12 * takeoff + 0.12 * stretch - 0.10 * landing;
    return (sx, sy);
  }

  double _reactGlow(double t) {
    if (t <= 0 || t >= 1) return 0;
    final tri = 1.0 - (t - 0.45).abs() / 0.45;
    return Curves.easeOutCubic.transform(tri.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> eq =
        widget.equipped ?? ref.watch(equippedPipProvider);
    final size = widget.size;
    final extra = size * 0.22;

    return SizedBox(
      width: size,
      height: size + extra,
      child: AnimatedBuilder(
        animation: _reactCtrl,
        builder: (_, __) {
          final t = _reactCtrl.value;
          final jump = _reactJump(t);
          final (sx, sy) = _reactSquash(t);
          final glow = _reactGlow(t);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow halo + sparkles overflow the bounds so the celebration
              // is visible regardless of where Pip is placed. Drawn behind
              // the body + accessories.
              if (glow > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: OverflowBox(
                      maxWidth: size * 2.4,
                      maxHeight: size * 2.4,
                      child: Transform.translate(
                        offset: Offset(0, jump),
                        child: CustomPaint(
                          painter: _PipReactionOverlay(t: t, glow: glow),
                        ),
                      ),
                    ),
                  ),
                ),

              // Body + accessories transformed together so the hat and
              // costume follow Pip during the jump.
              Transform.translate(
                offset: Offset(0, jump),
                child: Transform.scale(
                  scaleX: sx,
                  scaleY: sy,
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        // Inner mascot has no controller — outer PipWithItems
                        // owns the reaction now to keep accessories in sync.
                        child: PipMascot(
                          size: size,
                          hat: widget.hat,
                          wave: widget.wave,
                          mood: widget.mood,
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AccessoryPainter(
                            hatId:     eq['hat']     ?? 'none',
                            costumeId: eq['costume'] ?? 'none',
                            bo: extra,
                            bs: size,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Accessory painter — draws the equipped hat (a themed roof) above
// Pip's head and the equipped costume (SquarePants-style band) over
// the lower body. Coordinates: bo = body offset (extra space above
// body), bs = body size. PipMascot occupies y ∈ [bo, bo+bs].
// ─────────────────────────────────────────────────────────────
class _AccessoryPainter extends CustomPainter {
  final String hatId, costumeId;
  final double bo, bs;

  const _AccessoryPainter({
    required this.hatId,
    required this.costumeId,
    required this.bo,
    required this.bs,
  });

  static const _outC = Color(0xFF1A1030);

  Paint _f(Color c) => Paint()..color = c;
  Paint _s(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size sz) {
    if (costumeId != 'none' && costumeId.isNotEmpty) {
      _drawCostume(canvas, sz.width);
    }
    if (hatId != 'none' && hatId.isNotEmpty) {
      _drawHat(canvas, sz.width);
    }
  }

  // ── HAT: themed roofs ────────────────────────────────────────

  void _drawHat(Canvas canvas, double cw) {
    final cx = cw * 0.50;
    final headTop = bo + bs * 0.26;
    switch (hatId) {
      case 'roof_tile_red':
        _roofTile(canvas, cx, headTop, const Color(0xFFC0392B), const Color(0xFF7B2118));
      case 'roof_tile_blue':
        _roofTile(canvas, cx, headTop, const Color(0xFF2E6FBF), const Color(0xFF1B4A85));
      case 'roof_thatch':
        _roofThatch(canvas, cx, headTop);
      case 'roof_greek':
        _roofGreek(canvas, cx, headTop);
      case 'roof_japanese':
        _roofJapanese(canvas, cx, headTop);
    }
  }

  Path _roofTriangle(double cx, double headTop, double w, double h) {
    return Path()
      ..moveTo(cx - w / 2, headTop)
      ..lineTo(cx, headTop - h)
      ..lineTo(cx + w / 2, headTop)
      ..close();
  }

  void _roofTile(Canvas canvas, double cx, double headTop, Color base, Color shadow) {
    final w = bs * 0.74;
    final h = bs * 0.20;
    final left = cx - w / 2;
    final right = cx + w / 2;
    final tri = _roofTriangle(cx, headTop, w, h);

    canvas.drawPath(tri, _f(base));
    canvas.save();
    canvas.clipPath(tri);
    // Scalloped tile rows
    final scallop = _f(shadow);
    for (int row = 0; row < 4; row++) {
      final rowY = headTop - h * row / 4 - bs * 0.01;
      final rowWidth = w * (1 - row / 4) - bs * 0.02;
      final tileW = bs * 0.075;
      final cnt = (rowWidth / tileW).floor();
      final startX = cx - cnt * tileW / 2;
      for (int i = 0; i < cnt; i++) {
        final tx = startX + i * tileW + tileW / 2;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(tx, rowY), width: tileW * 0.95, height: bs * 0.04),
          math.pi, math.pi, false, scallop,
        );
      }
    }
    canvas.restore();
    canvas.drawPath(tri, _s(_outC, bs * 0.014));
    // Ridge cap at peak
    final peakY = headTop - h;
    canvas.drawCircle(Offset(cx, peakY + bs * 0.005), bs * 0.022, _f(shadow));
    canvas.drawCircle(Offset(cx, peakY + bs * 0.005), bs * 0.022, _s(_outC, bs * 0.010));
    // Eaves (overhang line at base)
    canvas.drawLine(Offset(left - bs * 0.02, headTop), Offset(right + bs * 0.02, headTop),
        _s(_outC, bs * 0.012));
  }

  void _roofThatch(Canvas canvas, double cx, double headTop) {
    final w = bs * 0.74;
    final h = bs * 0.20;
    final tri = _roofTriangle(cx, headTop, w, h);
    final peakY = headTop - h;

    canvas.drawPath(tri, _f(const Color(0xFFD9A859)));
    canvas.save();
    canvas.clipPath(tri);
    // Layered horizontal thatch courses with slight wave
    final thatch = _s(const Color(0xFF8A5A22), bs * 0.005);
    for (int i = 1; i < 5; i++) {
      final y = headTop - h * i / 5;
      final wave = Path()..moveTo(cx - w / 2, y);
      for (double x = cx - w / 2; x <= cx + w / 2; x += bs * 0.04) {
        wave.lineTo(x, y + math.sin(x * 0.3) * bs * 0.004);
      }
      canvas.drawPath(wave, thatch);
    }
    // Vertical strands for texture
    final strand = _s(const Color(0xFFAB7B3A), bs * 0.003);
    for (double tx = cx - w / 2 + bs * 0.02; tx < cx + w / 2; tx += bs * 0.025) {
      final t = (tx - cx).abs() / (w / 2);
      final topY = peakY + t * h * 0.85;
      canvas.drawLine(Offset(tx, topY), Offset(tx, headTop - bs * 0.01), strand);
    }
    canvas.restore();
    canvas.drawPath(tri, _s(_outC, bs * 0.013));
    // Rope ridge cap
    canvas.drawLine(Offset(cx - bs * 0.04, peakY + bs * 0.012),
        Offset(cx + bs * 0.04, peakY + bs * 0.012),
        _s(const Color(0xFF6A4422), bs * 0.018));
  }

  void _roofGreek(Canvas canvas, double cx, double headTop) {
    final w = bs * 0.78;
    final h = bs * 0.16;
    final left = cx - w / 2;
    final right = cx + w / 2;
    final tri = _roofTriangle(cx, headTop - bs * 0.018, w, h);

    // Pediment
    canvas.drawPath(tri, _f(const Color(0xFFF1EAD8)));
    canvas.drawPath(tri, _s(const Color(0xFF7A6B5A), bs * 0.012));
    // Center sun rosette
    canvas.drawCircle(Offset(cx, headTop - h * 0.45), bs * 0.022,
        _f(const Color(0xFFE8DBB8)));
    canvas.drawCircle(Offset(cx, headTop - h * 0.45), bs * 0.022,
        _s(const Color(0xFF7A6B5A), bs * 0.006));
    // Frieze (horizontal beam)
    final friezeRect = Rect.fromLTWH(left - bs * 0.025, headTop - bs * 0.025,
        w + bs * 0.05, bs * 0.030);
    canvas.drawRect(friezeRect, _f(const Color(0xFFE5D7B2)));
    canvas.drawRect(friezeRect, _s(const Color(0xFF7A6B5A), bs * 0.008));
    // Triglyphs
    for (int i = 0; i < 5; i++) {
      final tx = left + w * (i + 0.5) / 5;
      canvas.drawLine(Offset(tx, headTop - bs * 0.022),
          Offset(tx, headTop - bs * 0.002),
          _s(const Color(0xFF7A6B5A), bs * 0.006));
    }
    // Architrave shadow
    canvas.drawLine(Offset(left - bs * 0.025, headTop + bs * 0.005),
        Offset(right + bs * 0.025, headTop + bs * 0.005),
        _s(const Color(0xFF7A6B5A).withOpacity(0.5), bs * 0.005));
  }

  void _roofJapanese(Canvas canvas, double cx, double headTop) {
    final w = bs * 0.84;
    final h = bs * 0.20;
    final left = cx - w / 2;
    final right = cx + w / 2;

    // Lower tier — curved upturned eaves
    final eaves = Path()
      ..moveTo(cx - bs * 0.10, headTop - h * 0.45)
      ..quadraticBezierTo(cx, headTop - h, cx + bs * 0.10, headTop - h * 0.45)
      ..lineTo(right - bs * 0.04, headTop)
      ..quadraticBezierTo(right + bs * 0.03, headTop - bs * 0.005,
                          right - bs * 0.005, headTop - bs * 0.025)
      ..lineTo(left + bs * 0.005, headTop - bs * 0.025)
      ..quadraticBezierTo(left - bs * 0.03, headTop - bs * 0.005,
                          left + bs * 0.04, headTop)
      ..close();
    canvas.drawPath(eaves, _f(const Color(0xFF6B1F18)));
    canvas.drawPath(eaves, _s(_outC, bs * 0.012));

    // Tile rows on the lower roof
    canvas.save();
    canvas.clipPath(eaves);
    final tile = _s(const Color(0xFF3A0F0A), bs * 0.005);
    for (int i = 0; i < 3; i++) {
      final ratio = (i + 1) / 4;
      final ly = headTop - bs * 0.02 - (h * 0.65 - bs * 0.02) * ratio;
      final lwHalf = (w / 2 - bs * 0.04) * (1 - ratio * 0.85);
      canvas.drawLine(Offset(cx - lwHalf, ly), Offset(cx + lwHalf, ly), tile);
    }
    canvas.restore();

    // Upper finial / peak
    final peakPath = Path()
      ..moveTo(cx - bs * 0.05, headTop - h * 0.45)
      ..lineTo(cx, headTop - h * 1.05)
      ..lineTo(cx + bs * 0.05, headTop - h * 0.45)
      ..close();
    canvas.drawPath(peakPath, _f(const Color(0xFFC09030)));
    canvas.drawPath(peakPath, _s(_outC, bs * 0.010));
    canvas.drawCircle(Offset(cx, headTop - h * 1.05),
        bs * 0.018, _f(const Color(0xFFFFD23F)));
    canvas.drawCircle(Offset(cx, headTop - h * 1.05),
        bs * 0.018, _s(_outC, bs * 0.008));
  }

  // ── COSTUME: SquarePants-style band over lower body ──────────

  void _drawCostume(Canvas canvas, double cw) {
    // Pip body in absolute coords (matches _PipPainter):
    //   body center (cw*0.5, bo + bs*0.6), size 0.72cw × 0.68bs, radius 0.16cw
    final bodyRect = Rect.fromCenter(
      center: Offset(cw * 0.5, bo + bs * 0.6),
      width:  bs * 0.72,
      height: bs * 0.68,
    );
    final bodyR = RRect.fromRectAndRadius(bodyRect, Radius.circular(bs * 0.16));

    // Costume band — bottom ~30% of body
    final waistY = bo + bs * 0.74;
    final left   = bodyRect.left;
    final right  = bodyRect.right;
    final bottom = bodyRect.bottom;

    canvas.save();
    canvas.clipRRect(bodyR);
    switch (costumeId) {
      case 'costume_brick':    _costumeBrick(canvas, left, right, waistY, bottom);
      case 'costume_wood':     _costumeWood(canvas, left, right, waistY, bottom);
      case 'costume_stone':    _costumeStone(canvas, left, right, waistY, bottom);
      case 'costume_garden':   _costumeGarden(canvas, left, right, waistY, bottom);
      case 'costume_tuxedo':   _costumeTuxedo(canvas, cw, left, right, waistY, bottom);
      case 'costume_overalls': _costumeOveralls(canvas, cw, left, right, waistY, bottom);
      case 'costume_kimono':   _costumeKimono(canvas, left, right, waistY, bottom);
      case 'costume_armor':    _costumeArmor(canvas, left, right, waistY, bottom);
    }
    canvas.restore();
    // Re-stroke body outline so the costume seam stays crisp
    canvas.drawRRect(bodyR, _s(_outC, bs * 0.022));
    // Belt line at the waist
    canvas.drawLine(
      Offset(bodyRect.left + bs * 0.03, waistY),
      Offset(bodyRect.right - bs * 0.03, waistY),
      _s(_outC.withOpacity(0.6), bs * 0.012),
    );
  }

  void _costumeBrick(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    canvas.drawRect(Rect.fromLTWH(l, t, w, h), _f(const Color(0xFFB54B3D)));
    final mortar = _s(const Color(0xFF3A1A14), bs * 0.008);
    const rows = 3;
    final rowH = h / rows;
    // Horizontal mortar lines
    for (int i = 1; i < rows; i++) {
      final y = t + rowH * i;
      canvas.drawLine(Offset(l, y), Offset(r, y), mortar);
    }
    // Offset vertical separators
    for (int row = 0; row < rows; row++) {
      final y0 = t + rowH * row;
      final y1 = t + rowH * (row + 1);
      final offset = (row.isEven) ? 0.0 : w / 6;
      for (double x = l + offset; x < r; x += w / 3) {
        if (x > l && x < r) {
          canvas.drawLine(Offset(x, y0), Offset(x, y1), mortar);
        }
      }
    }
    // Highlight on top of bricks
    canvas.drawRect(Rect.fromLTWH(l, t, w, bs * 0.008),
        _f(const Color(0xFFD96A55).withOpacity(0.6)));
  }

  void _costumeWood(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    canvas.drawRect(Rect.fromLTWH(l, t, w, h), _f(const Color(0xFF8E5A2C)));
    final plank = _s(const Color(0xFF4A2C12), bs * 0.008);
    for (int i = 1; i < 5; i++) {
      final x = l + w * i / 5;
      canvas.drawLine(Offset(x, t), Offset(x, b), plank);
    }
    // Wood grain
    final grain = _s(const Color(0xFF6B3F1B), bs * 0.004);
    final rng = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final y = t + h * (i + 0.5 + rng.nextDouble() * 0.3) / 6;
      canvas.drawLine(Offset(l + bs * 0.01, y),
          Offset(r - bs * 0.01, y), grain);
    }
    // Knot
    canvas.drawCircle(Offset(l + w * 0.32, t + h * 0.55), bs * 0.013,
        _f(const Color(0xFF4A2C12)));
  }

  void _costumeStone(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    canvas.drawRect(
      Rect.fromLTWH(l, t, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8E96A0), Color(0xFF5D666F)],
      ).createShader(Rect.fromLTWH(l, t, w, h)),
    );
    final mortar = _s(const Color(0xFF2E343A), bs * 0.008);
    // Irregular block pattern
    const rows = 3;
    for (int row = 0; row < rows; row++) {
      final y0 = t + h * row / rows;
      final y1 = t + h * (row + 1) / rows;
      if (row > 0) canvas.drawLine(Offset(l, y0), Offset(r, y0), mortar);
      final cols = row.isEven ? 3 : 4;
      for (int c = 1; c < cols; c++) {
        final x = l + w * c / cols + (row.isOdd ? bs * 0.01 : 0);
        canvas.drawLine(Offset(x, y0), Offset(x, y1), mortar);
      }
    }
    // Highlight speckles
    canvas.drawCircle(Offset(l + w * 0.2, t + h * 0.3), bs * 0.006,
        _f(const Color(0xFFB8C0CA)));
    canvas.drawCircle(Offset(l + w * 0.7, t + h * 0.6), bs * 0.005,
        _f(const Color(0xFFB8C0CA)));
  }

  void _costumeGarden(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    // Sky-to-grass gradient
    canvas.drawRect(
      Rect.fromLTWH(l, t, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF66A867), Color(0xFF2E7A3E)],
      ).createShader(Rect.fromLTWH(l, t, w, h)),
    );
    // Grass blades
    final blade = _s(const Color(0xFF1F5A2B), bs * 0.004);
    for (double x = l; x < r; x += bs * 0.02) {
      canvas.drawLine(Offset(x, b), Offset(x + bs * 0.005, b - bs * 0.018), blade);
    }
    // Flowers
    final spots = [
      Offset(l + w * 0.18, t + h * 0.35),
      Offset(l + w * 0.55, t + h * 0.25),
      Offset(l + w * 0.78, t + h * 0.55),
      Offset(l + w * 0.30, t + h * 0.65),
    ];
    final petals = [
      const Color(0xFFFFB6C1),
      const Color(0xFFFFE066),
      const Color(0xFFE08CFF),
      const Color(0xFFFF8095),
    ];
    for (int i = 0; i < spots.length; i++) {
      _flower(canvas, spots[i], bs * 0.020, petals[i]);
    }
  }

  void _flower(Canvas canvas, Offset c, double r, Color petal) {
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      final px = c.dx + r * math.cos(a);
      final py = c.dy + r * math.sin(a);
      canvas.drawCircle(Offset(px, py), r * 0.6, _f(petal));
    }
    canvas.drawCircle(c, r * 0.5, _f(const Color(0xFFFFD23F)));
  }

  void _costumeTuxedo(Canvas canvas, double cw, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    final cx = (l + r) / 2;
    // Black jacket base
    canvas.drawRect(Rect.fromLTWH(l, t, w, h), _f(const Color(0xFF15151B)));
    // White lapel/shirt V
    final v = Path()
      ..moveTo(cx - w * 0.30, t)
      ..lineTo(cx, t + h * 0.45)
      ..lineTo(cx + w * 0.30, t)
      ..lineTo(cx + w * 0.20, t)
      ..lineTo(cx, t + h * 0.32)
      ..lineTo(cx - w * 0.20, t)
      ..close();
    canvas.drawPath(v, _f(const Color(0xFFF5F5F0)));
    canvas.drawPath(v, _s(const Color(0xFF8E8E8E), bs * 0.005));
    // Lapel inner triangles
    final lapelL = Path()
      ..moveTo(l + w * 0.05, t)
      ..lineTo(cx - w * 0.04, t + h * 0.25)
      ..lineTo(cx - w * 0.20, t)
      ..close();
    final lapelR = Path()
      ..moveTo(r - w * 0.05, t)
      ..lineTo(cx + w * 0.04, t + h * 0.25)
      ..lineTo(cx + w * 0.20, t)
      ..close();
    canvas.drawPath(lapelL, _f(const Color(0xFF2A2A35)));
    canvas.drawPath(lapelR, _f(const Color(0xFF2A2A35)));
    // Bow tie just above the waist seam
    final btY = t + bs * 0.005;
    final btW = bs * 0.07;
    final btH = bs * 0.034;
    final btL = Path()
      ..moveTo(cx, btY)
      ..lineTo(cx - btW, btY - btH)
      ..lineTo(cx - btW, btY + btH)
      ..close();
    final btR = Path()
      ..moveTo(cx, btY)
      ..lineTo(cx + btW, btY - btH)
      ..lineTo(cx + btW, btY + btH)
      ..close();
    canvas.drawPath(btL, _f(const Color(0xFFC0392B)));
    canvas.drawPath(btR, _f(const Color(0xFFC0392B)));
    canvas.drawPath(btL, _s(const Color(0xFF1A1030), bs * 0.005));
    canvas.drawPath(btR, _s(const Color(0xFF1A1030), bs * 0.005));
    canvas.drawCircle(Offset(cx, btY), bs * 0.014, _f(const Color(0xFF8B2418)));
    // Buttons
    canvas.drawCircle(Offset(cx, t + h * 0.6), bs * 0.012, _f(const Color(0xFF2A2A35)));
    canvas.drawCircle(Offset(cx, t + h * 0.85), bs * 0.012, _f(const Color(0xFF2A2A35)));
  }

  void _costumeOveralls(Canvas canvas, double cw, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    // Denim base
    canvas.drawRect(Rect.fromLTWH(l, t, w, h), _f(const Color(0xFF3F66A0)));
    // Vertical stitching texture
    final stitch = _s(const Color(0xFF254573).withOpacity(0.7), bs * 0.003);
    for (int i = 1; i < 8; i++) {
      final x = l + w * i / 8;
      canvas.drawLine(Offset(x, t), Offset(x, b), stitch);
    }
    // Bib & straps — straps extend above costume area to shoulders
    final strapW = bs * 0.075;
    final strapL = Rect.fromLTWH(l + w * 0.18, bo + bs * 0.45,
        strapW, t - (bo + bs * 0.45) + bs * 0.05);
    final strapR = Rect.fromLTWH(r - w * 0.18 - strapW, bo + bs * 0.45,
        strapW, t - (bo + bs * 0.45) + bs * 0.05);
    canvas.drawRect(strapL, _f(const Color(0xFF3F66A0)));
    canvas.drawRect(strapR, _f(const Color(0xFF3F66A0)));
    canvas.drawRect(strapL, _s(const Color(0xFF1A2A50), bs * 0.005));
    canvas.drawRect(strapR, _s(const Color(0xFF1A2A50), bs * 0.005));
    // Bib panel between straps
    final bibY = bo + bs * 0.55;
    final bibRect = Rect.fromLTWH(l + w * 0.24, bibY,
        w * 0.52, t - bibY + bs * 0.02);
    canvas.drawRect(bibRect, _f(const Color(0xFF3F66A0)));
    canvas.drawRect(bibRect, _s(const Color(0xFF1A2A50), bs * 0.005));
    // Gold buttons
    canvas.drawCircle(Offset(strapL.center.dx, bibY + bs * 0.015), bs * 0.014,
        _f(const Color(0xFFFFD23F)));
    canvas.drawCircle(Offset(strapR.center.dx, bibY + bs * 0.015), bs * 0.014,
        _f(const Color(0xFFFFD23F)));
    canvas.drawCircle(Offset(strapL.center.dx, bibY + bs * 0.015), bs * 0.014,
        _s(const Color(0xFF7A5A1A), bs * 0.005));
    canvas.drawCircle(Offset(strapR.center.dx, bibY + bs * 0.015), bs * 0.014,
        _s(const Color(0xFF7A5A1A), bs * 0.005));
    // Pocket
    canvas.drawRect(
      Rect.fromLTWH(l + w * 0.42, t + h * 0.25, w * 0.16, h * 0.30),
      _s(const Color(0xFF254573), bs * 0.005),
    );
  }

  void _costumeKimono(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    final cx = (l + r) / 2;
    // Crimson base
    canvas.drawRect(Rect.fromLTWH(l, t, w, h), _f(const Color(0xFFB02E45)));
    // Diagonal collar fold (lighter)
    final fold = Path()
      ..moveTo(l, t)
      ..lineTo(r, t + h * 0.18)
      ..lineTo(cx, t + h * 0.55)
      ..close();
    canvas.drawPath(fold, _f(const Color(0xFFE8C8C0)));
    canvas.drawPath(fold, _s(const Color(0xFF7A1F30), bs * 0.005));
    // Obi (waist sash)
    canvas.drawRect(
      Rect.fromLTWH(l, t + h * 0.55, w, h * 0.18),
      _f(const Color(0xFFFFD23F)),
    );
    canvas.drawRect(
      Rect.fromLTWH(l, t + h * 0.55, w, h * 0.18),
      _s(const Color(0xFF7A5A1A), bs * 0.005),
    );
    canvas.drawLine(Offset(l, t + h * 0.65), Offset(r, t + h * 0.65),
        _s(const Color(0xFFC09030), bs * 0.004));
    // Floral motifs
    final spots = [
      Offset(l + w * 0.20, t + h * 0.30),
      Offset(l + w * 0.75, t + h * 0.42),
      Offset(l + w * 0.50, t + h * 0.85),
      Offset(l + w * 0.15, t + h * 0.90),
    ];
    for (final s in spots) {
      _flower(canvas, s, bs * 0.018, const Color(0xFFFFE0E8));
    }
  }

  void _costumeArmor(Canvas canvas, double l, double r, double t, double b) {
    final w = r - l;
    final h = b - t;
    // Brushed steel gradient
    canvas.drawRect(
      Rect.fromLTWH(l, t, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC0C8D0), Color(0xFF6E7680)],
      ).createShader(Rect.fromLTWH(l, t, w, h)),
    );
    // Plate divisions
    final plate = _s(const Color(0xFF353B43), bs * 0.008);
    canvas.drawLine(Offset(l, t + h * 0.40), Offset(r, t + h * 0.40), plate);
    canvas.drawLine(Offset(l, t + h * 0.75), Offset(r, t + h * 0.75), plate);
    // Center seam
    canvas.drawLine(Offset((l + r) / 2, t), Offset((l + r) / 2, b),
        _s(const Color(0xFF353B43).withOpacity(0.5), bs * 0.006));
    // Rivets (3 rows × 2 cols)
    final rivet = _f(const Color(0xFF353B43));
    for (int row = 0; row < 3; row++) {
      final y = t + h * (row + 0.5) / 3;
      canvas.drawCircle(Offset(l + w * 0.18, y), bs * 0.012, rivet);
      canvas.drawCircle(Offset(r - w * 0.18, y), bs * 0.012, rivet);
      canvas.drawCircle(Offset(l + w * 0.18, y), bs * 0.012,
          _s(const Color(0xFFB8C0CA), bs * 0.003));
      canvas.drawCircle(Offset(r - w * 0.18, y), bs * 0.012,
          _s(const Color(0xFFB8C0CA), bs * 0.003));
    }
    // Highlight on top edge of each plate
    canvas.drawLine(Offset(l, t + bs * 0.005), Offset(r, t + bs * 0.005),
        _s(const Color(0xFFE0E6ED).withOpacity(0.6), bs * 0.004));
  }

  @override
  bool shouldRepaint(_AccessoryPainter old) =>
      old.hatId     != hatId     ||
      old.costumeId != costumeId ||
      old.bo        != bo        ||
      old.bs        != bs;
}
