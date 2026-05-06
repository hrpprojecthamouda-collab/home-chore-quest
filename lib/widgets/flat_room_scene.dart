import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../models/furniture_skin.dart';
import '../providers/furniture_providers.dart';
import 'pip_mascot.dart';

// Canvas coordinate space: 400 wide × 500 tall (original drawing coordinates).
// We crop the top 60 px before displaying, so the visible area is 400×440.
const kRoomCanvasW = 400.0;
const kRoomCanvasH = 440.0;
const _kCropTop    = 60.0;

// Hitboxes in original 400×500 space (crop is handled in the tap mapping below).
const _cleaningRect  = Rect.fromLTWH(20,  80, 180, 290);
const _groceriesRect = Rect.fromLTWH(225, 80, 175, 275);
const _billsRect     = Rect.fromLTWH(10,  345, 215, 155);
const _laundryRect   = Rect.fromLTWH(225, 340, 175, 160);

class FlatRoomScene extends ConsumerStatefulWidget {
  final bool messy;
  final void Function(QuestCategory, Rect)? onCategoryTap;
  final Map<FurnitureType, FurnitureSkin>? skinOverrides;
  final bool showPip;
  final bool showBadges;

  const FlatRoomScene({
    super.key,
    required this.messy,
    this.onCategoryTap,
    this.skinOverrides,
    this.showPip = true,
    this.showBadges = true,
  });

  @override
  ConsumerState<FlatRoomScene> createState() => _FlatRoomSceneState();
}

// Pip overlay: canvas-visible coords (400×440) where Pip is centered per category.
const _kPipSize = 52.0;
const _kPipPositions = {
  QuestCategory.cleaning:  Offset(100.0, 251.0),  // next to vacuum
  QuestCategory.groceries: Offset(290.0, 215.0),  // in front of fridge
  QuestCategory.laundry:   Offset(275.0, 280.0),  // in front of washer
  QuestCategory.bills:     Offset(135.0,  356.0),  // in front of desk
};

class _FlatRoomSceneState extends ConsumerState<FlatRoomScene>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _tapCueCtrl;
  late final Animation<double> _breath;

  // Stable tie-breaking: only re-roll when the tied set changes.
  QuestCategory? _pipTiedChoice;
  Set<QuestCategory>? _prevTied;

  QuestCategory? _getPipCategory(Map<QuestCategory, int> counts) {
    if (counts.values.every((v) => v == 0)) return null;
    final maxCount = counts.values.reduce(math.max);
    final tied = counts.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toSet();
    if (tied.length == 1) {
      _pipTiedChoice = null;
      _prevTied = null;
      return tied.first;
    }
    // Reuse existing choice if the tied set hasn't changed.
    if (_pipTiedChoice != null &&
        _prevTied != null &&
        _prevTied!.length == tied.length &&
        _prevTied!.containsAll(tied) &&
        tied.contains(_pipTiedChoice)) {
      return _pipTiedChoice;
    }
    _prevTied = tied;
    _pipTiedChoice = tied.elementAt(math.Random().nextInt(tied.length));
    return _pipTiedChoice;
  }

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _tapCueCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _tapCueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeCounts = {
      QuestCategory.cleaning:  ref.watch(pendingQuestsByCategory(QuestCategory.cleaning)).length,
      QuestCategory.groceries: ref.watch(pendingQuestsByCategory(QuestCategory.groceries)).length,
      QuestCategory.bills:     ref.watch(pendingQuestsByCategory(QuestCategory.bills)).length,
      QuestCategory.laundry:   ref.watch(pendingQuestsByCategory(QuestCategory.laundry)).length,
    };

    final pipCat = widget.showPip ? _getPipCategory(badgeCounts) : null;

    return GestureDetector(
      onTapUp: widget.onCategoryTap == null ? null : (details) {
        final box = context.findRenderObject()! as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        // sx/sy map widget pixels → original 400×500 coordinate space (with crop offset)
        final sx = kRoomCanvasW / box.size.width;
        final sy = kRoomCanvasH / box.size.height;
        final pt = Offset(local.dx * sx, local.dy * sy + _kCropTop);

        Rect toScreen(Rect r) {
          final tl = box.localToGlobal(Offset(r.left / sx, (r.top - _kCropTop) / sy));
          return Rect.fromLTWH(tl.dx, tl.dy, r.width / sx, r.height / sy);
        }

        if (_cleaningRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.cleaning,  toScreen(_cleaningRect));
        } else if (_groceriesRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.groceries, toScreen(_groceriesRect));
        } else if (_billsRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.bills,     toScreen(_billsRect));
        } else if (_laundryRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.laundry,   toScreen(_laundryRect));
        }
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          final sx = constraints.maxWidth  / kRoomCanvasW;
          final sy = constraints.maxHeight / kRoomCanvasH;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_breath, _tapCueCtrl]),
                builder: (_, __) {
                  final providerSkins = ref.watch(resolvedFurnitureSkinsProvider);
                  final skins = widget.skinOverrides != null
                      ? {for (final t in FurnitureType.values) t: widget.skinOverrides![t] ?? kDefaultSkins[t]!}
                      : providerSkins;
                  // Day = 06:00 inclusive to 19:00 exclusive. Anything else is night.
                  final hour = DateTime.now().hour;
                  final daytime = hour >= 6 && hour < 19;
                  return CustomPaint(
                    painter: _FlatRoomPainter(
                      messy: widget.messy,
                      daytime: daytime,
                      breath: _breath.value,
                      tapCueAngle: _tapCueCtrl.value * 2 * math.pi,
                      badgeCounts: widget.showBadges ? badgeCounts : {},
                      skins: skins,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
              if (pipCat != null)
                Positioned(
                  left: _kPipPositions[pipCat]!.dx * sx - _kPipSize / 2,
                  top:  _kPipPositions[pipCat]!.dy * sy - _kPipSize / 2,
                  child: const PipWithItems(size: _kPipSize),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FlatRoomPainter extends CustomPainter {
  final bool messy;
  final bool daytime;
  final double breath;
  final double tapCueAngle;
  final Map<QuestCategory, int> badgeCounts;
  final Map<FurnitureType, FurnitureSkin> skins;

  _FlatRoomPainter({
    required this.messy,
    required this.daytime,
    required this.breath,
    required this.tapCueAngle,
    required this.badgeCounts,
    required this.skins,
  });

  // Palette
  static const _wall    = Color(0xFF1A1030);
  static const _wallHi  = Color(0xFF2a1a52);
  static const _wallLo  = Color(0xFF120824);
  static const _floorC  = Color(0xFF3b2418);
  static const _floorHi = Color(0xFF5a3520);
  static const _seam    = Color(0xFF1f120a);
  static const _oDark   = Color(0xFF1a1238);
  static const _oMid    = Color(0xFF3a2a6a);
  static const _oWarm   = Color(0xFF3a2010);
  static const _teal    = Color(0xFF3edcff);
  static const _amber   = Color(0xFFffb347);
  static const _blue    = Color(0xFF7ab8ff);
  static const _pink    = Color(0xFFd9a8ff);
  static const _red     = Color(0xFFff5e6c);
  static const _sw      = 1.6;

  Paint _f(Color c) => Paint()..color = c;
  Paint _s(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // Scale to the visible 400×440 window, then shift up to crop the top 60 px.
    canvas.scale(size.width / kRoomCanvasW, size.height / kRoomCanvasH);
    canvas.translate(0, -_kCropTop);
    _drawAll(canvas);
    canvas.restore();
  }

  void _drawAll(Canvas canvas) {
    _drawBackground(canvas);
    _drawZoneGlows(canvas);
    _drawStars(canvas);
    _drawWindow(canvas);
    _drawCleaning(canvas);
    _drawGroceries(canvas);
    _drawBills(canvas);
    _drawLaundry(canvas);
    if (messy) _drawFloorMess(canvas);
    _drawTopVignette(canvas);
    _drawQuestBadges(canvas);
  }

  // ── Background: wall + floor ─────────────────────────────────
  void _drawBackground(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 350), _f(_wall));
    // wall vignette
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 350),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, 0.1),
          radius: 0.75,
          colors: [Color(0x732a1a52), Color(0xD90a0418)],
        ).createShader(const Rect.fromLTWH(0, 0, 400, 350)),
    );
    // baseboard
    canvas.drawRect(const Rect.fromLTWH(0, 343, 400, 3), _f(_wallLo));
    canvas.drawRect(const Rect.fromLTWH(0, 346, 400, 2), _f(_wallHi.withOpacity(0.5)));
    // floor
    canvas.drawRect(const Rect.fromLTWH(0, 348, 400, 152), _f(_floorC));
    // plank seams
    for (int i = 0; i < 8; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * 50.0, 348, 1.2, 152),
        _f(_seam.withOpacity(0.7)),
      );
    }
    // scuffs
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, 385 + i * 38.0, 400, 1),
        _f(_floorHi.withOpacity(0.18)),
      );
    }
    // floor sheen
    canvas.drawRect(
      const Rect.fromLTWH(0, 348, 400, 152),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x005a3520), Color(0x597a4a2a), Color(0x991a0e08)],
          stops: [0, 0.35, 1],
        ).createShader(const Rect.fromLTWH(0, 348, 400, 152)),
    );
  }

  // ── Zone glows ───────────────────────────────────────────────
  void _drawZoneGlows(Canvas canvas) {
    void glow(double cx, double cy, double rx, double ry, Color c, {double op = 1.0}) {
      final r = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
      canvas.drawOval(
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withOpacity(0.5 * op), c.withOpacity(0)],
          ).createShader(r),
      );
    }
    glow(80,  280, 90,  120, _teal);
    glow(80,  400, 100, 40,  _teal, op: 0.9);
    glow(310, 260, 105, 120, _amber);
    glow(310, 400, 110, 40,  _amber, op: 0.9);
    glow(100, 460, 120, 60,  _blue);
    glow(310, 460, 120, 60,  _pink);
  }

  // ── Ambient wall stars ───────────────────────────────────────
  void _drawStars(Canvas canvas) {
    final p = _f(Colors.white.withOpacity(0.35));
    for (final s in [(60.0, 70.0, 1.0), (240.0, 82.0, 1.0), (370.0, 100.0, 1.3), (200.0, 120.0, 1.0), (320.0, 74.0, 0.9)]) {
      canvas.drawCircle(Offset(s.$1, s.$2), s.$3, p);
    }
  }

  // ── Window — switches between day and night based on `daytime` ───
  void _drawWindow(Canvas canvas) {
    canvas.save();
    canvas.translate(130, 50);  // large window; top of frame starts at y≈46, visible above crop

    // outer warm wooden frame (148×128 glass + 4px inset)
    canvas.drawRRect(_rr(-4, -4, 148, 128, 6), _f(const Color(0xFF3a230f)));
    canvas.drawRRect(_rr(-4, -4, 148, 128, 6), _s(_oWarm, _sw));

    // window sill
    canvas.drawRRect(_rr(-10, 120, 160, 8, 2), _f(const Color(0xFF5a3a1d)));
    canvas.drawRRect(_rr(-10, 120, 160, 8, 2), _s(_oWarm, _sw));

    if (daytime) {
      _drawDaySky(canvas);
    } else {
      _drawNightSky(canvas);
    }

    // villain drawn BEFORE hills so hills occlude its lower body (peeking effect)
    if (messy) {
      canvas.save();
      canvas.translate(70, 85);
      _drawVillain(canvas);
      canvas.restore();
    }

    // hills — colored by time of day
    if (daytime) {
      final hills1 = Path()
        ..moveTo(0, 96)
        ..quadraticBezierTo(24, 84, 48, 92)
        ..quadraticBezierTo(72, 100, 96, 86)
        ..quadraticBezierTo(120, 74, 140, 90)
        ..lineTo(140, 120)..lineTo(0, 120)..close();
      canvas.drawPath(hills1, _f(const Color(0xFF4a8a3a)));
      final hills2 = Path()
        ..moveTo(0, 104)
        ..quadraticBezierTo(30, 94, 60, 100)
        ..quadraticBezierTo(90, 108, 120, 96)
        ..quadraticBezierTo(130, 92, 140, 98)
        ..lineTo(140, 120)..lineTo(0, 120)..close();
      canvas.drawPath(hills2, _f(const Color(0xFF356626)));
    } else {
      final hills1 = Path()
        ..moveTo(0, 96)
        ..quadraticBezierTo(24, 84, 48, 92)
        ..quadraticBezierTo(72, 100, 96, 86)
        ..quadraticBezierTo(120, 74, 140, 90)
        ..lineTo(140, 120)..lineTo(0, 120)..close();
      canvas.drawPath(hills1, _f(const Color(0xFF1a1238).withOpacity(0.85)));
      final hills2 = Path()
        ..moveTo(0, 104)
        ..quadraticBezierTo(30, 94, 60, 100)
        ..quadraticBezierTo(90, 108, 120, 96)
        ..quadraticBezierTo(130, 92, 140, 98)
        ..lineTo(140, 120)..lineTo(0, 120)..close();
      canvas.drawPath(hills2, _f(const Color(0xFF0d0820).withOpacity(0.85)));
    }

    // mullions over everything
    canvas.drawLine(const Offset(70, 0),  const Offset(70, 120),  _s(const Color(0xFF3a230f), 3));
    canvas.drawLine(const Offset(0,  60), const Offset(140, 60),  _s(const Color(0xFF3a230f), 3));

    // glass glints
    final g1 = Path()..moveTo(6, 6)..lineTo(28, 6)..lineTo(6, 30)..close();
    canvas.drawPath(g1, _f(Colors.white.withOpacity(0.08)));
    final g2 = Path()..moveTo(76, 64)..lineTo(92, 64)..lineTo(76, 80)..close();
    canvas.drawPath(g2, _f(Colors.white.withOpacity(0.06)));

    canvas.restore();
  }

  void _drawNightSky(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 140, 120),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0d1230), Color(0xFF2a2378), Color(0xFF5a3a8a)],
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 140, 120)),
    );
    // moon (crescent: full circle + offset smaller circle)
    canvas.drawCircle(const Offset(104, 32), 14, _f(const Color(0xFFfef3c7)));
    canvas.drawCircle(const Offset(100, 29), 11, _f(const Color(0xFFfffbe6)));
    canvas.drawCircle(const Offset(96, 26),  2.5, _f(const Color(0xFFe8d49a).withOpacity(0.7)));
    canvas.drawCircle(const Offset(105, 35), 2.0, _f(const Color(0xFFe8d49a).withOpacity(0.6)));
    // stars
    for (final s in [(18.0, 20.0, 1.2), (40.0, 12.0, 0.9), (60.0, 34.0, 1.0), (28.0, 50.0, 0.9), (76.0, 18.0, 1.1), (124.0, 62.0, 0.9), (52.0, 74.0, 1.0), (14.0, 84.0, 0.9)]) {
      canvas.drawCircle(Offset(s.$1, s.$2), s.$3, _f(Colors.white));
    }
  }

  void _drawDaySky(Canvas canvas) {
    // bright blue sky gradient
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 140, 120),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6cc6ff), Color(0xFFb3e3ff), Color(0xFFffe9b8)],
          stops: [0, 0.6, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 140, 120)),
    );

    // sun with halo
    const sunCenter = Offset(108, 30);
    canvas.drawCircle(
      sunCenter,
      20,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFffe680).withOpacity(0.55), const Color(0xFFffe680).withOpacity(0)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: 20)),
    );
    canvas.drawCircle(sunCenter, 11, _f(const Color(0xFFffd54a)));
    canvas.drawCircle(sunCenter, 8.5, _f(const Color(0xFFfff2a6)));
    // tiny sparkle
    canvas.drawCircle(const Offset(104, 27), 1.6, _f(Colors.white));

    // sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFffd54a).withOpacity(0.6)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p1 = sunCenter + Offset(math.cos(a) * 14, math.sin(a) * 14);
      final p2 = sunCenter + Offset(math.cos(a) * 19, math.sin(a) * 19);
      canvas.drawLine(p1, p2, rayPaint);
    }

    // fluffy clouds (rounded blob layers)
    void cloud(double cx, double cy, double scale) {
      final w = _f(Colors.white);
      canvas.drawCircle(Offset(cx, cy), 6 * scale, w);
      canvas.drawCircle(Offset(cx + 7 * scale, cy + 1), 7.5 * scale, w);
      canvas.drawCircle(Offset(cx + 14 * scale, cy + 2), 5.5 * scale, w);
      canvas.drawCircle(Offset(cx + 4 * scale, cy + 5), 5 * scale, w);
      canvas.drawCircle(Offset(cx + 10 * scale, cy + 5), 5.5 * scale, w);
    }
    cloud(20, 22, 1.0);
    cloud(60, 50, 0.85);

    // a couple of distant birds
    final birdPaint = _s(const Color(0xFF35466e), 1.1)..strokeCap = StrokeCap.round;
    final bird1 = Path()
      ..moveTo(40, 38)..quadraticBezierTo(43, 35, 46, 38)
      ..moveTo(46, 38)..quadraticBezierTo(49, 35, 52, 38);
    final bird2 = Path()
      ..moveTo(78, 28)..quadraticBezierTo(81, 25, 84, 28)
      ..moveTo(84, 28)..quadraticBezierTo(87, 25, 90, 28);
    canvas.drawPath(bird1, birdPaint);
    canvas.drawPath(bird2, birdPaint);
  }

  // ── Villain — split-personality, half white/good, half black/evil.
  // Origin is the peeking point above the hills. Bigger and clearer than before
  // so the villain reads at a glance when the room is messy.
  void _drawVillain(Canvas canvas) {
    const headW = 46.0;
    const headH = 36.0;
    final headRect = Rect.fromCenter(center: const Offset(0, -10), width: headW, height: headH);

    // Soft red dread halo around the whole head
    canvas.drawOval(
      headRect.inflate(8),
      Paint()
        ..shader = RadialGradient(
          colors: [_red.withOpacity(0.45), _red.withOpacity(0)],
        ).createShader(headRect.inflate(8)),
    );

    // ── Horns: white angelic on the left, black devilish on the right
    final hornGood = Path()..moveTo(-15, -22)..lineTo(-19, -36)..lineTo(-9, -22)..close();
    final hornEvil = Path()..moveTo(15, -22)..quadraticBezierTo(26, -32, 19, -38)..quadraticBezierTo(20, -28, 9, -22)..close();
    canvas.drawPath(hornGood, _f(const Color(0xFFf5f5f5)));
    canvas.drawPath(hornGood, _s(const Color(0xFFb0b0b0), 1.2));
    canvas.drawPath(hornEvil, _f(const Color(0xFF050505)));
    canvas.drawPath(hornEvil, _s(const Color(0xFF3a3a3a), 1.2));

    // ── Head split down the middle: clip each half and fill independently
    // White (good) half — left
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(headRect.left - 2, headRect.top - 2, 0, headRect.bottom + 2));
    canvas.drawOval(headRect, _f(const Color(0xFFf2f2f2)));
    canvas.restore();
    // Black (evil) half — right
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, headRect.top - 2, headRect.right + 2, headRect.bottom + 2));
    canvas.drawOval(headRect, _f(const Color(0xFF0a0a0a)));
    canvas.restore();
    // Outline + central seam
    canvas.drawOval(headRect, _s(const Color(0xFF6a6a6a), 1.4));
    canvas.drawLine(
      Offset(0, headRect.top + 2),
      Offset(0, headRect.bottom - 2),
      _s(const Color(0xFF7a7a7a), 1.0),
    );

    // ── Eyes: serene blue on the white side, glowing red on the black side
    // Good eye (left)
    canvas.drawCircle(const Offset(-11, -12), 3.6, _f(Colors.white));
    canvas.drawCircle(const Offset(-11, -12), 3.6, _s(const Color(0xFF333333), 0.8));
    canvas.drawCircle(const Offset(-11, -12), 1.6, _f(const Color(0xFF2a6dd1)));
    canvas.drawCircle(const Offset(-10.4, -12.4), 0.7, _f(Colors.white));
    // Evil eye (right) — glow + iris + highlight
    canvas.drawCircle(const Offset(11, -12), 5.5, _f(const Color(0x66ff1111)));
    canvas.drawCircle(const Offset(11, -12), 3.4, _f(const Color(0xFFff2a2a)));
    canvas.drawCircle(const Offset(11, -12), 1.4, _f(Colors.white));

    // ── Mouth: gentle smile on the white side, fanged grin on the black side
    final smile = Path()..moveTo(-13, -2)..quadraticBezierTo(-7, 2, -1, -2);
    canvas.drawPath(smile, _s(const Color(0xFF333333), 1.3)..strokeCap = StrokeCap.round);

    // evil grin
    final grin = Path()..moveTo(1, -2)..quadraticBezierTo(7, 4, 13, -2);
    canvas.drawPath(grin, _s(const Color(0xFFff2a2a), 1.6)..strokeCap = StrokeCap.round);
    // two fangs on evil side
    canvas.drawPath(Path()..moveTo(4, -1)..lineTo(5.2, 4)..lineTo(7, -1)..close(), _f(Colors.white));
    canvas.drawPath(Path()..moveTo(9, -1)..lineTo(10.2, 4)..lineTo(12, -1)..close(), _f(Colors.white));
  }

  // ── Rotating dashed tap-cue ring ─────────────────────────────
  void _drawTapCue(Canvas canvas, double cx, double cy, double r, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const sweepRad = 20.0 * math.pi / 180.0;
    const stepRad  = 45.0 * math.pi / 180.0;
    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        tapCueAngle + i * stepRad,
        sweepRad,
        false,
        paint,
      );
    }
    final bx = cx + r * math.cos(tapCueAngle);
    final by = cy + r * math.sin(tapCueAngle);
    canvas.drawCircle(Offset(bx, by), 3.0, _f(Colors.white.withOpacity(0.9)));
    canvas.drawCircle(Offset(bx, by), 1.5, _f(color));
  }

  // ── BACK-LEFT: CLEANING (vacuum + sink + bucket) ─────────────
  void _drawCleaning(Canvas canvas) {
    canvas.save();
    canvas.translate(30, 130);

    _drawTapCue(canvas, 65, 155, 88, _teal);

    // contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(72, 218), width: 185, height: 12),
      _f(Colors.black.withValues(alpha: 0.5)),
    );

    // --- VACUUM ---
    {
      final vs = skins[FurnitureType.vacuum]!;
      canvas.save();
      canvas.translate(20, 44);
      canvas.scale(0.8, 0.8);

      // head plate
      final head = Path()
        ..moveTo(-16, 200)..lineTo(60, 200)..lineTo(70, 218)..lineTo(-26, 218)..close();
      canvas.drawPath(head, _f(vs.dark));
      canvas.drawPath(head, _s(_oDark, _sw));
      canvas.drawRRect(_rr(-26, 216, 96, 6, 2), _f(Color.lerp(vs.dark, Colors.black, 0.3)!));

      // neck
      canvas.drawRRect(
        _rr(20, 158, 10, 50, 3),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [vs.light, vs.primary, vs.dark],
            stops: const [0, 0.55, 1],
          ).createShader(const Rect.fromLTWH(20, 158, 10, 50)),
      );
      canvas.drawRRect(_rr(20, 158, 10, 50, 3), _s(_oDark, _sw));

      // body / dirt cup
      canvas.drawRRect(
        _rr(0, 100, 50, 64, 10),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            colors: [vs.light, vs.primary],
          ).createShader(const Rect.fromLTWH(0, 100, 50, 64)),
      );
      canvas.drawRRect(_rr(0, 100, 50, 64, 10), _s(_oDark, _sw));
      canvas.drawRRect(_rr(8, 112, 34, 34, 5), _f(Color.lerp(vs.dark, Colors.black, 0.45)!));
      canvas.drawRRect(_rr(10, 114, 30, 30, 4), _f(vs.light.withValues(alpha: 0.85)));
      canvas.drawCircle(const Offset(25, 129), 6, _f(vs.dark.withValues(alpha: 0.6)));
      canvas.drawCircle(const Offset(22, 126), 2.5, _f(vs.light.withValues(alpha: 0.9)));
      // chibi eyes
      canvas.drawCircle(const Offset(18, 150), 1.6, _f(_oDark));
      canvas.drawCircle(const Offset(32, 150), 1.6, _f(_oDark));
      canvas.drawPath(
        Path()..moveTo(22, 156)..quadraticBezierTo(25, 159, 28, 156),
        _s(_oDark, 1.4),
      );
      // glint
      canvas.drawRRect(_rr(2, 106, 3, 50, 1.5), _f(Colors.white.withValues(alpha: 0.5)));

      // upper handle
      canvas.drawRRect(
        _rr(22, 20, 6, 84, 3),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [vs.light, vs.primary, vs.dark],
            stops: const [0, 0.55, 1],
          ).createShader(const Rect.fromLTWH(22, 20, 6, 84)),
      );
      canvas.drawRRect(_rr(22, 20, 6, 84, 3), _s(_oDark, 1.2));
      canvas.drawRRect(_rr(14, 14, 22, 14, 5), _f(vs.light));
      canvas.drawRRect(_rr(14, 14, 22, 14, 5), _s(_oDark, _sw));

      canvas.restore();
    }

    // --- SINK CABINET ---
    canvas.save();
    canvas.translate(85, 148);

    // cabinet base (two doors)
    canvas.drawRRect(_rr(0, 0, 64, 70, 4), _f(const Color(0xFF4a2d10)));
    canvas.drawRRect(_rr(0, 0, 64, 70, 4), _s(_oWarm, _sw));
    // door divider
    canvas.drawLine(const Offset(32, 2), const Offset(32, 68), _s(_oWarm, 1.2));
    // door panels
    canvas.drawRRect(_rr(4, 8, 24, 54, 2), _f(const Color(0xFF5a3a1d)));
    canvas.drawRRect(_rr(36, 8, 24, 54, 2), _f(const Color(0xFF5a3a1d)));
    // door knobs
    canvas.drawCircle(const Offset(24, 36), 2.5, _f(const Color(0xFFa86b3a)));
    canvas.drawCircle(const Offset(40, 36), 2.5, _f(const Color(0xFFa86b3a)));

    // counter top
    canvas.drawRRect(_rr(-4, -12, 72, 12, 2), _f(const Color(0xFF8a9ab2)));
    canvas.drawRRect(_rr(-4, -12, 72, 12, 2), _s(_oDark, _sw));
    // sink basin
    canvas.drawRRect(_rr(8, -10, 48, 8, 3), _f(const Color(0xFF2d2d40)));
    canvas.drawRRect(_rr(8, -10, 48, 8, 3), _s(_oDark, 1.2));

    // faucet stem + arc
    canvas.drawRRect(_rr(29, -30, 5, 20, 2.5), _f(const Color(0xFF9d5cff)));
    canvas.drawPath(
      Path()..moveTo(31.5, -30)..quadraticBezierTo(48, -40, 50, -24),
      _s(const Color(0xFF9d5cff), 4)..strokeCap = StrokeCap.round,
    );
    // water drip
    canvas.drawCircle(const Offset(50, -20), 2.5, _f(const Color(0xFF3edcff).withValues(alpha: 0.8)));

    // stacked dishes (left of counter)
    for (int i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(14.0, -17.0 - i * 4), width: 22.0 - i * 1.5, height: 5.5 - i * 0.5),
        _f(const Color(0xFFfff5e6)),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(14.0, -17.0 - i * 4), width: 22.0 - i * 1.5, height: 5.5 - i * 0.5),
        _s(_oDark, 0.8),
      );
    }

    // mug
    canvas.drawRRect(_rr(46, -28, 12, 14, 2), _f(const Color(0xFFfb7185)));
    canvas.drawRRect(_rr(46, -28, 12, 14, 2), _s(_oDark, _sw));
    canvas.drawPath(
      Path()..moveTo(58, -24)..quadraticBezierTo(64, -21, 58, -18),
      _s(_oDark, _sw)..strokeCap = StrokeCap.round,
    );

    // foam bubbles near basin
    for (final b in [(18.0, -24.0, 2.0), (27.0, -27.0, 1.8), (36.0, -23.0, 1.9)]) {
      canvas.drawCircle(Offset(b.$1, b.$2), b.$3, _f(Colors.white.withValues(alpha: 0.9)));
    }

    // sponge
    canvas.drawRRect(_rr(34, -24, 10, 6, 1.5), _f(const Color(0xFFfde047)));
    canvas.drawRRect(_rr(34, -24, 10, 6, 1.5), _s(_oDark, 1.0));

    canvas.restore();

    // --- BUCKET ---
    {
      final vs = skins[FurnitureType.vacuum]!;
      canvas.save();
      canvas.translate(-10, 168);
      final bucket = Path()
        ..moveTo(0, 4)..lineTo(38, 4)..lineTo(34, 50)..lineTo(4, 50)..close();
      canvas.drawPath(bucket, _f(vs.primary));
      canvas.drawPath(bucket, _s(_oDark, _sw));
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(19, 4), width: 38, height: 8),
        _f(vs.dark),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(19, 4), width: 28, height: 4.8),
        _f(Color.lerp(vs.dark, Colors.black, 0.45)!),
      );
      // handle arc
      canvas.drawPath(
        Path()..moveTo(0, 4)..quadraticBezierTo(19, -10, 38, 4),
        _s(_oDark, _sw),
      );
      // suds
      for (final s in [(14.0, 2.0, 3.0), (22.0, -2.0, 2.4), (28.0, 3.0, 1.8)]) {
        canvas.drawCircle(Offset(s.$1, s.$2), s.$3, _f(Colors.white.withValues(alpha: 0.95)));
      }
      canvas.drawRRect(_rr(3, 14, 2, 22, 1), _f(Colors.white.withValues(alpha: 0.35)));
      canvas.restore();
    }

    canvas.restore();
  }

  // ── BACK-RIGHT: GROCERIES (fridge + produce crate) ───────────
  void _drawGroceries(Canvas canvas) {
    canvas.save();
    final fs = skins[FurnitureType.fridge]!;
    canvas.translate(240, 110);

    _drawTapCue(canvas, 65, 130, 75, _amber);

    // contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(65, 240), width: 160, height: 14),
      _f(Colors.black.withOpacity(0.55)),
    );

    // fridge body
    canvas.drawRRect(
      _rr(0, 0, 130, 232, 14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fs.light, fs.primary, fs.dark],
          stops: const [0, 0.6, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 130, 232)),
    );
    canvas.drawRRect(_rr(0, 0, 130, 232, 14), _s(_oWarm, _sw));

    // top/bottom split
    canvas.drawLine(const Offset(6, 80), const Offset(124, 80), _s(_oWarm.withOpacity(0.85), 1.6));

    // handles
    canvas.drawRRect(_rr(10, 22, 6, 36, 3), _f(fs.dark));
    canvas.drawRRect(_rr(10, 22, 6, 36, 3), _s(_oWarm, 1));
    canvas.drawRRect(_rr(10, 100, 6, 80, 3), _f(fs.dark));
    canvas.drawRRect(_rr(10, 100, 6, 80, 3), _s(_oWarm, 1));

    // photo (slight rotate)
    canvas.save();
    canvas.translate(58, 23);
    canvas.rotate(-4 * math.pi / 180);
    canvas.drawRRect(_rr(-18, -13, 36, 26, 1.5), _f(const Color(0xFFfff5e6)));
    canvas.drawRRect(_rr(-18, -13, 36, 26, 1.5), _s(_oWarm, 1.2));
    canvas.restore();

    canvas.drawCircle(const Offset(56, 22), 2.4, _f(const Color(0xFFfbbf24)));

    // XP sticker
    canvas.drawRRect(_rr(92, 14, 24, 14, 2), _f(const Color(0xFFfb7185)));
    canvas.drawRRect(_rr(92, 14, 24, 14, 2), _s(_oWarm, 1.2));
    _paintText(canvas, 'XP', const Offset(104, 21), 8, Colors.white);

    // star magnet
    canvas.drawCircle(const Offset(86, 44), 5, _f(const Color(0xFFfde047)));
    canvas.drawCircle(const Offset(86, 44), 5, _s(_oWarm, 1.2));

    // shine
    canvas.drawRRect(
      _rr(6, 6, 6, 220, 3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fs.light.withValues(alpha: 0.85), Colors.transparent],
        ).createShader(const Rect.fromLTWH(6, 6, 6, 220)),
    );
    canvas.drawRRect(_rr(118, 6, 3, 220, 1.5), _f(Colors.white.withOpacity(0.18)));

    // feet
    canvas.drawRRect(_rr(6,   228, 14, 8, 2), _f(const Color(0xFFa78bfa)));
    canvas.drawRRect(_rr(6,   228, 14, 8, 2), _s(_oWarm, 1.2));
    canvas.drawRRect(_rr(110, 228, 14, 8, 2), _f(const Color(0xFFa78bfa)));
    canvas.drawRRect(_rr(110, 228, 14, 8, 2), _s(_oWarm, 1.2));

    // --- PRODUCE CRATE ---
    canvas.save();
    canvas.translate(28, 196);
    canvas.drawRRect(_rr(0, 10, 84, 38, 3), _f(const Color(0xFF7a4520)));
    canvas.drawRRect(_rr(0, 10, 84, 38, 3), _s(_oWarm, _sw));
    for (final x in [21.0, 42.0, 63.0]) {
      canvas.drawLine(Offset(x, 10), Offset(x, 48), _s(_oWarm, 1.2));
    }
    canvas.drawRect(const Rect.fromLTWH(0, 10, 84, 6), _f(const Color(0xFF5a3018)));
    // apple
    canvas.drawCircle(const Offset(14, 4), 9, _f(const Color(0xFFef4444)));
    canvas.drawCircle(const Offset(14, 4), 9, _s(_oWarm, _sw));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(11, 0), width: 5, height: 3.2),
      _f(const Color(0xFFfca5a5)),
    );
    canvas.drawPath(
      Path()..moveTo(13, -6)..quadraticBezierTo(16, -10, 19, -6),
      _s(const Color(0xFF16a34a), 1.6)..strokeCap = StrokeCap.round,
    );
    // banana
    final banana = Path()
      ..moveTo(30, 8)..quadraticBezierTo(42, -2, 56, 2)
      ..quadraticBezierTo(50, 10, 32, 12)..close();
    canvas.drawPath(banana, _f(const Color(0xFFfde047)));
    canvas.drawPath(banana, _s(_oWarm, _sw));
    // leafy greens
    final leaf = Path()
      ..moveTo(64, 6)..quadraticBezierTo(72, -8, 80, 0)
      ..quadraticBezierTo(84, -6, 84, 8)..quadraticBezierTo(76, 8, 68, 8)..close();
    canvas.drawPath(leaf, _f(const Color(0xFF22c55e)));
    canvas.drawPath(leaf, _s(_oWarm, 1.4));
    canvas.restore();

    canvas.restore();
  }

  // ── FRONT-LEFT: BILLS (desk + laptop + calendar) ─────────────
  void _drawBills(Canvas canvas) {
    canvas.save();
    canvas.translate(20, 360);

    _drawTapCue(canvas, 90, 75, 70, _blue);

    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(85, 138), width: 184, height: 14),
      _f(Colors.black.withOpacity(0.55)),
    );

    // desk top
    canvas.drawRRect(
      _rr(0, 80, 180, 12, 3),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFa86b3a), Color(0xFF5a3a1d)],
        ).createShader(const Rect.fromLTWH(0, 80, 180, 12)),
    );
    canvas.drawRRect(_rr(0, 80, 180, 12, 3), _s(_oWarm, _sw));
    // legs
    canvas.drawRRect(_rr(6,   92, 10, 46, 0), _f(const Color(0xFF3a230f)));
    canvas.drawRRect(_rr(6,   92, 10, 46, 0), _s(_oWarm, 1.4));
    canvas.drawRRect(_rr(164, 92, 10, 46, 0), _f(const Color(0xFF3a230f)));
    canvas.drawRRect(_rr(164, 92, 10, 46, 0), _s(_oWarm, 1.4));
    // drawer
    canvas.drawRRect(_rr(22, 94, 136, 34, 2), _f(const Color(0xFF3a230f)));
    canvas.drawRRect(_rr(22, 94, 136, 34, 2), _s(_oWarm, _sw));
    canvas.drawRRect(_rr(26, 98, 128, 14, 1.5), _f(const Color(0xFF5a3a1d)));
    canvas.drawCircle(const Offset(90, 118), 2.2, _f(const Color(0xFFa86b3a)));

    // paper stack (two rotated sheets on desk)
    canvas.save();
    canvas.translate(8, 66);
    canvas.save();
    canvas.rotate(4 * math.pi / 180);
    canvas.drawRRect(_rr(0, 0, 40, 28, 1), _f(const Color(0xFFf0ece0)));
    canvas.drawRRect(_rr(0, 0, 40, 28, 1), _s(_oDark, 0.8));
    canvas.restore();
    canvas.save();
    canvas.rotate(-3 * math.pi / 180);
    canvas.drawRRect(_rr(2, 2, 40, 28, 1), _f(const Color(0xFFfff5e6)));
    canvas.drawRRect(_rr(2, 2, 40, 28, 1), _s(_oDark, 0.8));
    canvas.drawLine(const Offset(6, 10), const Offset(38, 10), _s(_oDark.withOpacity(0.3), 0.8));
    canvas.drawLine(const Offset(6, 16), const Offset(38, 16), _s(_oDark.withOpacity(0.3), 0.8));
    canvas.drawLine(const Offset(6, 22), const Offset(30, 22), _s(_oDark.withOpacity(0.3), 0.8));
    canvas.restore();
    canvas.restore();

    // easel calendar (tilted, on right side of desk)
    canvas.save();
    canvas.translate(140, 52);
    canvas.rotate(-6 * math.pi / 180);
    // easel legs
    canvas.drawLine(const Offset(8, 38), const Offset(2, 62), _s(const Color(0xFF3a230f), 1.8)..strokeCap = StrokeCap.round);
    canvas.drawLine(const Offset(36, 38), const Offset(42, 62), _s(const Color(0xFF3a230f), 1.8)..strokeCap = StrokeCap.round);
    canvas.drawLine(const Offset(10, 52), const Offset(34, 52), _s(const Color(0xFF3a230f), 1.4)..strokeCap = StrokeCap.round);
    // calendar card
    canvas.drawRRect(_rr(0, 0, 44, 38, 2), _f(const Color(0xFFfff5e6)));
    canvas.drawRRect(_rr(0, 0, 44, 38, 2), _s(_oDark, 1.0));
    // pink header
    canvas.drawRRect(_rr(0, 0, 44, 11, 2), _f(const Color(0xFFfb7185)));
    _paintText(canvas, 'MAY', const Offset(22, 5.5), 5, Colors.white);
    // dot grid
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        canvas.drawCircle(Offset(5 + col * 7.5, 18 + row * 6.0), 1.0, _f(const Color(0xFFa78bfa)));
      }
    }
    // date highlight ring
    canvas.drawCircle(const Offset(26, 24), 3.8,
        Paint()..color = const Color(0xFFef4444)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // binder rings at top
    canvas.drawCircle(const Offset(10, 0), 1.8, _f(const Color(0xFFef4444)));
    canvas.drawCircle(const Offset(22, 0), 1.8, _f(const Color(0xFFef4444)));
    canvas.drawCircle(const Offset(34, 0), 1.8, _f(const Color(0xFFef4444)));
    canvas.restore();

    // laptop
    canvas.save();
    canvas.translate(40, 32);
    canvas.drawRRect(_rr(0, 0, 100, 56, 4), _f(const Color(0xFF0f1230)));
    canvas.drawRRect(_rr(0, 0, 100, 56, 4), _s(_oDark, _sw));
    canvas.drawRRect(
      _rr(4, 4, 92, 48, 2),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          colors: const [Color(0xFFbfdfff), Color(0xFF3d6db0)],
        ).createShader(const Rect.fromLTWH(4, 4, 92, 48)),
    );
    canvas.drawRRect(_rr(9, 9, 34, 6, 1.5), _f(Colors.white.withOpacity(0.95)));
    canvas.drawRRect(_rr(9, 19, 58, 3, 1), _f(Colors.white.withOpacity(0.7)));
    canvas.drawRRect(_rr(9, 25, 46, 3, 1), _f(Colors.white.withOpacity(0.7)));
    canvas.drawRRect(_rr(60, 32, 30, 18, 2), _f(Colors.white));
    _paintText(canvas, r'$', const Offset(75, 41), 13, const Color(0xFF1e1b4b));
    // base
    final base = Path()
      ..moveTo(-8, 56)..lineTo(108, 56)..lineTo(102, 64)..lineTo(-2, 64)..close();
    canvas.drawPath(base, _f(const Color(0xFFcbd5e1)));
    canvas.drawPath(base, _s(_oDark, _sw));
    canvas.drawRect(const Rect.fromLTWH(42, 56, 16, 2), _f(_oDark));
    // screen glow halo
    canvas.drawRRect(
      _rr(-2, -2, 104, 60, 5),
      Paint()..color = _blue.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 2.4,
    );
    canvas.restore();

    // coffee mug
    canvas.save();
    canvas.translate(150, 56);
    canvas.drawRRect(_rr(0, 0, 22, 24, 3), _f(const Color(0xFFfb7185)));
    canvas.drawRRect(_rr(0, 0, 22, 24, 3), _s(_oDark, _sw));
    canvas.drawPath(
      Path()..moveTo(22, 6)..quadraticBezierTo(32, 12, 22, 18),
      _s(_oDark, _sw)..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(11, 1), width: 18, height: 4),
      _f(const Color(0xFF5a2030)),
    );
    canvas.drawPath(
      Path()..moveTo(6, -4)..quadraticBezierTo(8, -10, 6, -14),
      _s(Colors.white.withOpacity(0.75), 1.5)..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()..moveTo(14, -5)..quadraticBezierTo(16, -12, 14, -16),
      _s(Colors.white.withOpacity(0.75), 1.5)..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    canvas.restore();
  }

  // ── FRONT-RIGHT: LAUNDRY (washer + folded clothes) ───────────
  void _drawLaundry(Canvas canvas) {
    canvas.save();
    final ws = skins[FurnitureType.washer]!;
    canvas.translate(230, 350);

    _drawTapCue(canvas, 65, 85, 68, _pink);

    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(80, 148), width: 184, height: 14),
      _f(Colors.black.withOpacity(0.55)),
    );

    // washer body
    canvas.drawRRect(
      _rr(0, 20, 130, 130, 10),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ws.light, ws.primary],
        ).createShader(const Rect.fromLTWH(0, 20, 130, 130)),
    );
    canvas.drawRRect(_rr(0, 20, 130, 130, 10), _s(_oMid, _sw));

    // control panel
    canvas.drawRRect(_rr(6, 26, 118, 22, 3), _f(ws.dark));
    canvas.drawRRect(_rr(6, 26, 118, 22, 3), _s(ws.dark, _sw));
    // knob left
    canvas.drawCircle(const Offset(18, 37), 5, _f(Colors.white));
    canvas.drawCircle(const Offset(18, 37), 5, _s(_oMid, 1.2));
    canvas.drawLine(const Offset(18, 33), const Offset(18, 37),
        _s(_oMid, 1.2)..strokeCap = StrokeCap.round);
    // display
    canvas.drawRRect(_rr(32, 32, 62, 10, 2), _f(Color.lerp(ws.dark, Colors.white, 0.35)!));
    canvas.drawRRect(_rr(32, 32, 62, 10, 2), _s(_oMid, 1));
    canvas.drawCircle(const Offset(30, 37), 1.5, _f(const Color(0xFFfde047)));
    _paintText(canvas, 'SPIN', const Offset(63, 37), 6.5, Colors.white);
    // knob right
    canvas.drawCircle(const Offset(110, 37), 5, _f(Colors.white));
    canvas.drawCircle(const Offset(110, 37), 5, _s(_oMid, 1.2));

    // porthole rings
    canvas.drawCircle(const Offset(65, 100), 42, _f(_oMid));
    canvas.drawCircle(const Offset(65, 100), 36, _f(const Color(0xFF161028)));
    canvas.drawCircle(const Offset(65, 100), 36, _s(_oMid, 1.2));
    // porthole glass
    canvas.drawCircle(
      const Offset(65, 100),
      30,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          colors: const [Color(0xFFbfdfff), Color(0xFF2a3a78)],
        ).createShader(Rect.fromCircle(center: const Offset(65, 100), radius: 30)),
    );
    // tumbling clothes
    canvas.save();
    canvas.translate(56, 92); canvas.rotate(-15 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 12), _f(const Color(0xFFfb7185)));
    canvas.restore();
    canvas.save();
    canvas.translate(76, 106); canvas.rotate(20 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 10), _f(const Color(0xFFfde047)));
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 112), width: 14, height: 8),
      _f(const Color(0xFFa78bfa)),
    );
    // foam
    canvas.drawCircle(const Offset(48, 84), 3, _f(Colors.white.withOpacity(0.95)));
    canvas.drawCircle(const Offset(80, 92), 2.6, _f(Colors.white.withOpacity(0.9)));
    canvas.drawCircle(const Offset(68, 80), 2.4, _f(Colors.white.withOpacity(0.9)));
    // glass glint
    canvas.drawPath(
      Path()..moveTo(48, 84)..quadraticBezierTo(55, 76, 64, 76),
      _s(Colors.white.withOpacity(0.5), 2.2)..strokeCap = StrokeCap.round,
    );
    // body shine
    canvas.drawRRect(_rr(6, 56, 5, 92, 2), _f(Colors.white.withOpacity(0.5)));
    // feet
    canvas.drawRRect(_rr(6,   148, 14, 8, 2), _f(ws.dark));
    canvas.drawRRect(_rr(6,   148, 14, 8, 2), _s(_oMid, 1.2));
    canvas.drawRRect(_rr(110, 148, 14, 8, 2), _f(ws.dark));
    canvas.drawRRect(_rr(110, 148, 14, 8, 2), _s(_oMid, 1.2));

    // folded pile
    canvas.save();
    canvas.translate(132, 100);
    final pColors = [const Color(0xFFfb7185), const Color(0xFFfde047), const Color(0xFFa78bfa), const Color(0xFF7ab8ff)];
    final pY      = [42.0, 30.0, 18.0, 8.0];
    final pW      = [40.0, 36.0, 32.0, 28.0];
    final pX      = [0.0,  2.0,  4.0,  6.0];
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(_rr(pX[i], pY[i], pW[i], 12, 2), _f(pColors[i]));
      canvas.drawRRect(_rr(pX[i], pY[i], pW[i], 12, 2), _s(_oMid, 1.4));
      canvas.drawLine(Offset(20, pY[i]), Offset(20, pY[i] + 12), _s(_oMid, 1));
    }
    // sparkle
    final sp = _s(const Color(0xFFfde047), 1.6)..strokeCap = StrokeCap.round;
    final sp2 = _s(const Color(0xFFfde047), 1.1)..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(38, -2);
    canvas.drawLine(const Offset(0, -5), const Offset(0, 5), sp);
    canvas.drawLine(const Offset(-5, 0), const Offset(5, 0), sp);
    canvas.drawLine(const Offset(-3.5, -3.5), const Offset(3.5, 3.5), sp2);
    canvas.drawLine(const Offset(-3.5, 3.5), const Offset(3.5, -3.5), sp2);
    canvas.restore();
    canvas.restore();

    canvas.restore();
  }

  // ── Messy floor debris ───────────────────────────────────────
  void _drawFloorMess(Canvas canvas) {
    canvas.drawCircle(const Offset(120, 468), 3, _f(const Color(0xFF94a3b8)));
    canvas.drawCircle(const Offset(120, 468), 3, _s(_oDark, 1));
    canvas.drawCircle(const Offset(200, 478), 2.4, _f(const Color(0xFFfde047)));
    canvas.drawCircle(const Offset(200, 478), 2.4, _s(_oDark, 1));
    canvas.drawRRect(_rr(290, 475, 9, 4, 2), _f(const Color(0xFFa78bfa)));
    canvas.drawRRect(_rr(290, 475, 9, 4, 2), _s(_oDark, 1));
    canvas.drawPath(
      Path()..moveTo(170, 472)..quadraticBezierTo(173, 468, 176, 472),
      _s(const Color(0xFFfb7185), 1.4)..strokeCap = StrokeCap.round,
    );
    // extra mess near cleaning zone
    canvas.drawCircle(const Offset(70, 458), 2, _f(Colors.white.withOpacity(0.4)));
    canvas.drawRRect(_rr(42, 468, 14, 4, 2), _f(const Color(0xFF94a3b8).withOpacity(0.7)));
  }

  // ── Top vignette ─────────────────────────────────────────────
  void _drawTopVignette(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 80),
      _f(Colors.black.withOpacity(0.18)),
    );
  }

  // ── Quest badges ─────────────────────────────────────────────
  void _drawQuestBadges(Canvas canvas) {
    final entries = <(QuestCategory, double, double)>[
      (QuestCategory.cleaning,  52.0, 238.0),   // above the sink/vacuum
      (QuestCategory.groceries, 240.0, 180.0),  // above the fridge XP sticker
      (QuestCategory.laundry,   235.0, 370.0),  // top-right of the washer
      (QuestCategory.bills,     51.0, 375.0),   // above the laptop
    ];
    for (final (cat, x, y) in entries) {
      final count = badgeCounts[cat] ?? 0;
      if (count > 0) _drawBadge(canvas, x, y, count);
    }
  }

  void _drawBadge(Canvas canvas, double x, double y, int count) {
    const bw = 28.0, bh = 16.0, br = 6.0;
    final rect = Rect.fromCenter(center: Offset(x, y), width: bw, height: bh);
    final cx = rect.center.dx;
    final bottom = rect.bottom;

    // Draw tail first; body paints over its root for a seamless join.
    // Both bases must sit within the straight portion of the bottom edge
    // ([cx - (bw/2 - br), cx + (bw/2 - br)] = [cx-8, cx+8]) — anything past
    // that lands on the rounded corner and creates a visible gap.
    final tail = Path()
      ..moveTo(cx - 3, bottom)         // left base, inside the straight edge
      ..lineTo(cx + 6, bottom + 10)    // tip pointing down-right
      ..lineTo(cx + 5, bottom)         // right base, inside the straight edge
      ..close();
    canvas.drawPath(tail, _f(_red));

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(br)), _f(_red));

    final tp = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  // ── Text helper ──────────────────────────────────────────────
  void _paintText(Canvas canvas, String text, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_FlatRoomPainter old) =>
      old.messy != messy ||
      old.daytime != daytime ||
      old.breath != breath ||
      old.tapCueAngle != tapCueAngle ||
      old.badgeCounts != badgeCounts ||
      old.skins != skins;
}
