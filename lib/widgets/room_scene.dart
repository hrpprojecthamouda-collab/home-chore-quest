import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';

// Hitboxes in SVG 400×250 space
const _workshopRect = Rect.fromLTWH(22, 114, 72, 68);
const _sinkRect     = Rect.fromLTWH(98, 104, 64, 76);
const _fridgeRect   = Rect.fromLTWH(173, 106, 52, 68);
const _deskRect     = Rect.fromLTWH(243, 106, 122, 76);

class RoomScene extends ConsumerStatefulWidget {
  final bool messy;
  final void Function(QuestCategory, Rect sourceRect)? onCategoryTap;
  final bool showPip;
  final bool showTapCues;

  const RoomScene({
    super.key,
    required this.messy,
    this.onCategoryTap,
    this.showPip = true,
    this.showTapCues = true,
  });

  @override
  ConsumerState<RoomScene> createState() => _RoomSceneState();
}

class _RoomSceneState extends ConsumerState<RoomScene> with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _tapCueCtrl;
  late final AnimationController _villainCtrl;
  late final Animation<double> _breath;
  late final Animation<double> _tapCueProg;
  late final Animation<double> _villainBreath;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _tapCueCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
    _tapCueProg = _tapCueCtrl;

    _villainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _villainBreath = CurvedAnimation(parent: _villainCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _tapCueCtrl.dispose();
    _villainCtrl.dispose();
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

    return GestureDetector(
      onTapUp: widget.onCategoryTap == null ? null : (details) {
        final box = context.findRenderObject()! as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        final sx = 400 / box.size.width;
        final sy = 250 / box.size.height;
        final pt = Offset(local.dx * sx, local.dy * sy);

        Rect toScreen(Rect svgRect) {
          final tl = box.localToGlobal(
            Offset(svgRect.left / sx, svgRect.top / sy),
          );
          return Rect.fromLTWH(
            tl.dx, tl.dy, svgRect.width / sx, svgRect.height / sy,
          );
        }

        if (_workshopRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.laundry, toScreen(_workshopRect));
        } else if (_sinkRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.cleaning, toScreen(_sinkRect));
        } else if (_fridgeRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.groceries, toScreen(_fridgeRect));
        } else if (_deskRect.contains(pt)) {
          widget.onCategoryTap!(QuestCategory.bills, toScreen(_deskRect));
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _tapCueProg, _villainBreath]),
        builder: (_, __) => CustomPaint(
          painter: _RoomPainter(
            messy: widget.messy,
            breath: _breath.value,
            tapCueAngle: _tapCueProg.value * 2 * math.pi,
            villainBreath: _villainBreath.value,
            badgeCounts: badgeCounts,
            showPip: widget.showPip,
            showTapCues: widget.showTapCues,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────
class _RoomPainter extends CustomPainter {
  final bool messy;
  final double breath;        // 0..1 (Pip bobbing)
  final double tapCueAngle;   // 0..2π (rotating dashed rings)
  final double villainBreath; // 0..1 (villain bobbing)
  final Map<QuestCategory, int> badgeCounts;
  final bool showPip;
  final bool showTapCues;

  const _RoomPainter({
    required this.messy,
    required this.breath,
    required this.tapCueAngle,
    required this.villainBreath,
    this.badgeCounts = const {},
    this.showPip = true,
    this.showTapCues = true,
  });

  static const _outline  = Color(0xFF0D0820);
  static const _pink     = AppColors.pink;
  static const _cyan     = AppColors.cyan;
  static const _green    = AppColors.green;
  static const _yellow   = AppColors.yellow;
  static const _violet   = AppColors.violet;
  static const _surface2 = AppColors.surface2;
  static const _surface  = AppColors.surface;
  static const _red      = AppColors.red;

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
    canvas.scale(size.width / 400, size.height / 250);
    _drawAll(canvas);
    canvas.restore();
  }

  void _drawAll(Canvas canvas) {
    _drawBackground(canvas);
    _drawWindow(canvas);
    if (messy) _drawVillain(canvas);
    _drawWorkshop(canvas);
    _drawSink(canvas);
    _drawFridge(canvas);
    _drawDesk(canvas);
    _drawQuestBadges(canvas);
    if (messy) _drawFloorMess(canvas);
    if (showPip) _drawAvatar(canvas);
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 400, 160),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2DB0), Color(0xFF2E1D5A)],
        ).createShader(Rect.fromLTWH(0, 0, 400, 160)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 160, 400, 90),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2475), Color(0xFF1A0F3D)],
        ).createShader(Rect.fromLTWH(0, 160, 400, 90)),
    );
    canvas.drawLine(const Offset(0, 160), const Offset(400, 160), _s(_outline, 2));
  }

  void _drawWindow(Canvas canvas) {
    final wr = Rect.fromLTWH(155, 22, 100, 76);
    canvas.drawRRect(
      _rr(155, 22, 100, 76, 14),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3EDCFF), Color(0xFF9D5CFF), Color(0xFFFF4D8D)],
          stops: [0, .55, 1],
        ).createShader(wr),
    );
    canvas.drawRRect(_rr(155, 22, 100, 76, 14), _s(_outline, 3));
    final starP = _f(Colors.white);
    canvas.drawCircle(const Offset(170, 40), 1.2, starP);
    canvas.drawCircle(const Offset(232, 78), 1.0, starP);
    canvas.drawCircle(const Offset(222, 40), 1.0, starP);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(195, 55), width: 28, height: 12),
      _f(Colors.white.withOpacity(.55)),
    );
  }

  // ── Monokuma-style Dustlord villain ─────────────────────────
  void _drawVillain(Canvas canvas) {
    final bobY = (villainBreath * 8) - 4;
    canvas.save();
    canvas.translate(192, 20 + bobY);
    canvas.clipRect(const Rect.fromLTRB(-40, -8, 40, 40));

    // White left half
    final whitePath = Path()
      ..moveTo(-20, 28)
      ..lineTo(-20, 6)
      ..quadraticBezierTo(-20, -2, -12, -2)
      ..lineTo(0, -2)
      ..lineTo(0, 28)
      ..close();
    canvas.drawPath(whitePath, _f(const Color(0xFFF5F5F5)));

    // Black right half
    final blackPath = Path()
      ..moveTo(0, -2)
      ..lineTo(12, -2)
      ..quadraticBezierTo(20, -2, 20, 6)
      ..lineTo(20, 28)
      ..lineTo(0, 28)
      ..close();
    canvas.drawPath(blackPath, _f(const Color(0xFF0A0A0A)));

    // Center seam
    canvas.drawLine(const Offset(0, -2), const Offset(0, 28), _s(const Color(0xFF555555), 1.0));

    // Outer outline
    final outlinePath = Path()
      ..moveTo(-20, 28)
      ..lineTo(-20, 6)
      ..quadraticBezierTo(-20, -2, -12, -2)
      ..lineTo(12, -2)
      ..quadraticBezierTo(20, -2, 20, 6)
      ..lineTo(20, 28)
      ..close();
    canvas.drawPath(outlinePath, _s(const Color(0xFF333333), 1.5));

    // Cute left eye (white side)
    canvas.drawCircle(const Offset(-9, 12), 4.2, _f(Colors.white));
    canvas.drawCircle(const Offset(-9, 12), 4.2, _s(const Color(0xFF333333), 0.8));
    canvas.drawCircle(const Offset(-8.5, 12), 2.0, _f(const Color(0xFF1A1030)));
    canvas.drawCircle(const Offset(-7.5, 11), 0.8, _f(Colors.white));

    // Spiky starburst behind red eye
    final starPath = Path();
    const starPoints = [
      Offset(9, 2), Offset(11, 9), Offset(18, 12), Offset(11, 15),
      Offset(9, 22), Offset(7, 15), Offset(0, 12), Offset(7, 9),
    ];
    starPath.moveTo(starPoints[0].dx, starPoints[0].dy);
    for (int i = 1; i < starPoints.length; i++) {
      starPath.lineTo(starPoints[i].dx, starPoints[i].dy);
    }
    starPath.close();
    canvas.drawPath(starPath, _f(const Color(0xFFFF2A2A).withOpacity(0.55)));

    // Glaring red eye (radial gradient)
    canvas.drawCircle(
      const Offset(9, 12), 6.5,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFF8080), Color(0xFFFF0000), Color(0xFF8B0000)],
          stops: const [0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: const Offset(9, 12), radius: 6.5)),
    );
    canvas.drawCircle(const Offset(9.5, 13), 2.2, _f(const Color(0xFF0A0A0A)));
    canvas.drawCircle(const Offset(10.5, 10.5), 1.0, _f(Colors.white.withOpacity(0.7)));

    // Jagged mouth
    final mouthPath = Path()
      ..moveTo(-8, 22)
      ..lineTo(-5, 25)
      ..lineTo(-2, 22)
      ..lineTo(1, 26)
      ..lineTo(5, 22)
      ..lineTo(8, 25);
    canvas.drawPath(mouthPath, _s(const Color(0xFF555555), 1.4));

    canvas.restore();
  }

  // ── Rotating dashed ring + sparkle badge ────────────────────
  void _drawTapCue(Canvas canvas, double cx, double cy, double r, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // 8 arcs × 20° sweep, 25° gap → 8 × 45° = 360°
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

    // Sparkle badge at leading edge
    final bx = cx + r * math.cos(tapCueAngle);
    final by = cy + r * math.sin(tapCueAngle);
    canvas.drawCircle(Offset(bx, by), 3.2, _f(Colors.white.withOpacity(0.95)));
    canvas.drawCircle(Offset(bx, by), 1.6, _f(_yellow));
  }

  // ── WORKSHOP (Upgrades) ── translate(22, 130) ─────────────
  void _drawWorkshop(Canvas canvas) {
    canvas.save();
    canvas.translate(22, 130);

    if (showTapCues) _drawTapCue(canvas, 35, 22, 42, _pink);

    canvas.drawRRect(_rr(6, -8, 58, 14, 3), _f(_surface));
    canvas.drawRRect(_rr(6, -8, 58, 14, 3), _s(_outline, 2));
    canvas.drawRRect(_rr(14, -4, 6, 8, 1), _f(_yellow));
    canvas.drawRRect(_rr(26, -3, 10, 6, 1), _f(_green));
    canvas.drawCircle(const Offset(48, 0), 4, _s(_outline, 2.5));

    canvas.drawRRect(_rr(0, 14, 70, 8, 3), _f(_pink));
    canvas.drawRRect(_rr(0, 14, 70, 8, 3), _s(_outline, 2.5));
    canvas.drawRRect(_rr(4, 22, 62, 28, 4), _f(_surface2));
    canvas.drawRRect(_rr(4, 22, 62, 28, 4), _s(_outline, 2));

    canvas.drawRRect(_rr(32, 17, 14, 3, 1), _f(_yellow));
    canvas.drawRRect(_rr(34, 13, 6, 11, 1.5), _f(_yellow));
    canvas.drawRRect(_rr(32, 17, 14, 3, 1), _s(_outline, 2));
    canvas.drawRRect(_rr(34, 13, 6, 11, 1.5), _s(_outline, 2));

    if (messy) {
      canvas.save();
      canvas.translate(44, 22);
      canvas.rotate(0.35);
      canvas.drawRRect(_rr(0, 0, 14, 3, 1), _f(_green));
      canvas.restore();
    } else {
      final crystalPath = Path()
        ..moveTo(48, 18)..lineTo(52, 24)..lineTo(48, 30)..lineTo(44, 24)..close();
      canvas.drawPath(crystalPath, _f(_cyan));
      canvas.drawCircle(const Offset(48, 24), 6, _f(_cyan.withOpacity(.25)));
    }

    canvas.restore();
  }

  // ── SINK (Cleaning) ── translate(100, 130) ────────────────
  void _drawSink(Canvas canvas) {
    canvas.save();
    canvas.translate(100, 130);

    if (showTapCues) _drawTapCue(canvas, 30, 26, 32, _cyan);

    canvas.drawRRect(_rr(0, 14, 60, 8, 3), _f(_pink));
    canvas.drawRRect(_rr(0, 14, 60, 8, 3), _s(_outline, 2.5));
    canvas.drawRRect(_rr(4, 22, 52, 28, 4), _f(_surface2));
    canvas.drawRRect(_rr(4, 22, 52, 28, 4), _s(_outline, 2));
    canvas.drawRRect(_rr(14, 6, 34, 14, 4), _f(const Color(0xFF0F7C99)));
    canvas.drawRRect(_rr(14, 6, 34, 14, 4), _s(_outline, 2.5));
    final faucet = Path()
      ..moveTo(22, 6)..lineTo(22, 0)..lineTo(36, 0)..lineTo(36, 4);
    canvas.drawPath(faucet, _s(_outline, 2));
    canvas.drawCircle(const Offset(36, 4), 1.4, _f(_outline));

    if (messy) {
      canvas.save();
      canvas.save();
      canvas.rotate(-0.14);
      canvas.drawOval(Rect.fromCenter(center: const Offset(22, 11), width: 18, height: 4.8), _f(const Color(0xFFCBD5E1)));
      canvas.restore();
      canvas.drawOval(Rect.fromCenter(center: const Offset(22, 9), width: 18, height: 4.8), _f(const Color(0xFFE2E8F0)));
      canvas.drawRRect(_rr(32, 6, 9, 6, 1), _f(const Color(0xFF94A3B8)));
      final stink = _s(const Color(0xFF3DF09B), 1.2);
      for (final dx in [18.0, 26.0, 34.0]) {
        final p = Path()
          ..moveTo(dx, -1)
          ..quadraticBezierTo(dx + 2, -4, dx, -6);
        canvas.drawPath(p, stink);
      }
      canvas.restore();
    } else {
      canvas.drawRect(Rect.fromLTWH(50, 10, 14, 2), _f(_outline));
      for (final dx in [52.0, 56.0, 60.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(dx, 6), width: 2.8, height: 10), _f(Colors.white));
      }
      final sp = Path()
        ..moveTo(26, 13)..lineTo(27, 11)..lineTo(28, 13)
        ..lineTo(30, 14)..lineTo(28, 15)..lineTo(27, 17)..lineTo(26, 15)
        ..lineTo(24, 14)..close();
      canvas.drawPath(sp, _f(_cyan));
    }

    canvas.restore();
  }

  // ── FRIDGE (Groceries) ── translate(175, 108) ─────────────
  void _drawFridge(Canvas canvas) {
    canvas.save();
    canvas.translate(175, 108);

    if (showTapCues) _drawTapCue(canvas, 24, 31, 36, _green);

    canvas.drawRRect(_rr(0, 0, 48, 62, 10), _f(_green));
    canvas.drawRRect(_rr(0, 0, 48, 62, 10), _s(_outline, 2.5));
    canvas.drawLine(const Offset(0, 22), const Offset(48, 22), _s(_outline, 2));
    canvas.drawRRect(_rr(38, 6, 4, 10, 1.5), _f(_outline));
    canvas.drawRRect(_rr(38, 32, 4, 14, 1.5), _f(_outline));

    if (messy) {
      canvas.drawRRect(_rr(6, 6, 14, 3, 1), _f(Colors.white.withOpacity(.12)));
      canvas.drawRRect(_rr(6, 11, 8, 3, 1), _f(Colors.white.withOpacity(.12)));
    } else {
      canvas.drawRRect(_rr(6, 28, 10, 8, 1), _f(_yellow));
      canvas.drawRRect(_rr(6, 28, 10, 8, 1), _s(_outline, 2));
      canvas.drawRRect(_rr(6, 6, 6, 3, 1), _f(_yellow));
      canvas.drawRRect(_rr(14, 6, 10, 3, 1), _f(_violet));
      canvas.drawRRect(_rr(6, 11, 14, 3, 1), _f(_cyan));
    }

    canvas.restore();
  }

  // ── DESK (Bills) ── translate(245, 108) ───────────────────
  void _drawDesk(Canvas canvas) {
    canvas.save();
    canvas.translate(245, 108);

    if (showTapCues) _drawTapCue(canvas, 60, 36, 56, _yellow);

    canvas.drawRRect(_rr(0, 40, 120, 10, 3), _f(_yellow));
    canvas.drawRRect(_rr(0, 40, 120, 10, 3), _s(_outline, 2.5));
    canvas.drawRRect(_rr(4, 50, 6, 22, 2), _f(_yellow));
    canvas.drawRRect(_rr(110, 50, 6, 22, 2), _f(_yellow));
    canvas.drawRRect(_rr(4, 50, 6, 22, 2), _s(_outline, 2));
    canvas.drawRRect(_rr(110, 50, 6, 22, 2), _s(_outline, 2));

    canvas.drawLine(const Offset(14, 40), const Offset(14, 22), _s(_outline, 2));
    final lampShade = Path()
      ..moveTo(8, 22)..lineTo(22, 22)..lineTo(17, 16)..lineTo(11, 16)..close();
    canvas.drawPath(lampShade, _f(_violet));
    canvas.drawPath(lampShade, _s(_outline, 2));
    canvas.drawCircle(const Offset(15, 28), 8, _f(_yellow.withOpacity(messy ? .08 : .2)));

    canvas.drawRRect(_rr(28, 20, 22, 18, 3), _f(_surface));
    canvas.drawRRect(_rr(28, 20, 22, 18, 3), _s(_outline, 2));
    canvas.drawRect(
      Rect.fromLTWH(30, 22, 18, 14),
      _f(messy ? const Color(0xFFEF4444) : const Color(0xFF22D3EE)),
    );

    if (messy) {
      canvas.save();
      canvas.translate(56, 22);
      canvas.rotate(-0.14);
      canvas.drawRRect(_rr(0, 0, 22, 18, 1), _f(Colors.white));
      canvas.restore();
      canvas.save();
      canvas.translate(62, 20);
      canvas.rotate(0.1);
      canvas.drawRRect(_rr(0, 0, 22, 18, 1), _f(const Color(0xFFFEF3C7)));
      canvas.restore();
      canvas.save();
      canvas.translate(80, 18);
      canvas.rotate(-0.05);
      canvas.drawRRect(_rr(0, 0, 22, 22, 1), _f(const Color(0xFFFECACA)));
      canvas.drawRRect(_rr(0, 0, 22, 22, 1), _s(_red, 1.5));
      canvas.restore();
      canvas.drawOval(Rect.fromCenter(center: const Offset(106, 38), width: 12, height: 4), _f(const Color(0xFF78350F).withOpacity(.6)));
    } else {
      canvas.drawRRect(_rr(64, 22, 22, 18, 1), _f(Colors.white));
      for (final dy in [26.0, 29.0, 32.0]) {
        canvas.drawLine(Offset(68, dy), Offset(82, dy), _s(const Color(0xFF94A3B8), 1));
      }
      canvas.drawRRect(_rr(95, 30, 10, 10, 2), _f(_cyan));
    }

    canvas.restore();
  }

  // ── AVATAR (Pip) ── translate(310, 198 + breath) ──────────
  void _drawAvatar(Canvas canvas) {
    final yOff = breath * 1.6 - 0.8;
    canvas.save();
    canvas.translate(310, 198 + yOff);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 42), width: 44, height: 8),
      _f(Colors.black.withOpacity(.4)),
    );
    // Body — square rounded
    final bodyRR = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 20), width: 44, height: 44),
      const Radius.circular(10),
    );
    canvas.drawRRect(bodyRR, _f(_violet));
    canvas.drawRRect(bodyRR, _s(_outline, 2));
    // Belly
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 26), width: 28, height: 22),
        const Radius.circular(5),
      ),
      _f(const Color(0xFFC98AFF).withOpacity(.5)),
    );
    // Eyes
    canvas.drawCircle(const Offset(-7, 13), 4.2, _f(Colors.white));
    canvas.drawCircle(const Offset(7, 13), 4.2, _f(Colors.white));
    canvas.drawCircle(const Offset(-6, 14), 2, _f(_outline));
    canvas.drawCircle(const Offset(8, 14), 2, _f(_outline));
    canvas.drawCircle(const Offset(-5, 13), .8, _f(Colors.white));
    canvas.drawCircle(const Offset(9, 13), .8, _f(Colors.white));
    // Cheeks
    canvas.drawCircle(const Offset(-12, 22), 2.6, _f(const Color(0xFFFF4D8D).withOpacity(.7)));
    canvas.drawCircle(const Offset(12, 22), 2.6, _f(const Color(0xFFFF4D8D).withOpacity(.7)));
    // Mouth
    final mouthPath = Path()..moveTo(-4, 24)..quadraticBezierTo(0, 28, 4, 24);
    canvas.drawPath(mouthPath, _s(_outline, 2));

    canvas.restore();
  }

  void _drawFloorMess(Canvas canvas) {
    final items = [
      (fill: const Color(0xFFFB7185), x: 90.0, y: 218.0, w: 16.0, h: 4.0, rot: -0.21),
      (fill: _yellow, x: 130.0, y: 222.0, w: 6.0, h: 6.0, rot: 0.31),
      (fill: const Color(0xFFCBD5E1), x: 156.0, y: 226.0, w: 12.0, h: 4.0, rot: 0.14),
      (fill: _green, x: 230.0, y: 224.0, w: 6.0, h: 4.0, rot: 0.38),
      (fill: _cyan, x: 280.0, y: 232.0, w: 8.0, h: 8.0, rot: 0.0),
      (fill: const Color(0xFF94A3B8), x: 60.0, y: 232.0, w: 14.0, h: 4.0, rot: 0.07),
      (fill: _pink, x: 320.0, y: 218.0, w: 7.0, h: 4.0, rot: -0.44),
    ];

    for (final it in items) {
      canvas.save();
      final cx = it.x + it.w / 2;
      final cy = it.y + it.h / 2;
      canvas.translate(cx, cy);
      canvas.rotate(it.rot);
      canvas.drawRRect(
        _rr(-it.w / 2, -it.h / 2, it.w, it.h, 1.5),
        _f(it.fill.withOpacity(.85)),
      );
      canvas.restore();
    }

    canvas.drawOval(Rect.fromCenter(center: const Offset(170, 240), width: 18, height: 6), _f(const Color(0xFF475569).withOpacity(.55)));
    canvas.drawCircle(const Offset(170, 237), 2, _f(const Color(0xFF475569).withOpacity(.55)));
    for (final cx in [110.0, 180.0, 250.0]) {
      canvas.drawCircle(Offset(cx, 212), 4, _f(const Color(0xFFF1F5F9)));
    }
  }

  // Draws all category badges in one clean pass with no active transform
  void _drawQuestBadges(Canvas canvas) {
    // Absolute SVG coordinates (400×250 space). (x,y) = badge center.
    final entries = <(QuestCategory, double, double)>[
      (QuestCategory.laundry,   57.0, 108.0),  // above laundry zone
      (QuestCategory.cleaning, 130.0, 112.0),  // above sink faucet
      (QuestCategory.groceries,199.0,  90.0),  // above fridge top
      (QuestCategory.bills,    270.0, 108.0),  // above desk lamp
    ];
    for (final (cat, x, y) in entries) {
      final count = badgeCounts[cat] ?? 0;
      if (count > 0) _drawBadge(canvas, x, y, count);
    }
  }

  // Red pill badge; (x, y) = center of badge in SVG space
  void _drawBadge(Canvas canvas, double x, double y, int count) {
    const bw = 24.0;
    const bh = 14.0;
    const br = 7.0;
    // Bubble body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: bw, height: bh),
        const Radius.circular(br),
      ),
      _f(_red),
    );
    // Downward tail (triangle)
    final tailPath = Path()
      ..moveTo(x - 4, y + bh / 2 - 1)
      ..lineTo(x + 4, y + bh / 2 - 1)
      ..lineTo(x, y + bh / 2 + 5)
      ..close();
    canvas.drawPath(tailPath, _f(_red));
    // Count text
    final tp = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(x - tp.width / 2, y - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.messy != messy ||
      old.breath != breath ||
      old.tapCueAngle != tapCueAngle ||
      old.villainBreath != villainBreath ||
      old.badgeCounts != badgeCounts ||
      old.showPip != showPip ||
      old.showTapCues != showTapCues;
}
