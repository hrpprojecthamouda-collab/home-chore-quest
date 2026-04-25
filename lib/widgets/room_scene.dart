import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../theme/app_theme.dart';

// Hitboxes in SVG 400×250 space
const _workshopRect = Rect.fromLTWH(22, 114, 72, 68);
const _sinkRect     = Rect.fromLTWH(98, 104, 64, 76);
const _fridgeRect   = Rect.fromLTWH(173, 106, 52, 68);
const _deskRect     = Rect.fromLTWH(243, 106, 122, 76);

class RoomScene extends StatefulWidget {
  final bool messy;
  // Called with the tapped category and the furniture's rect in global screen coords.
  final void Function(QuestCategory, Rect sourceRect) onCategoryTap;
  final Map<QuestCategory, int> badgeCounts;

  const RoomScene({
    super.key,
    required this.messy,
    required this.onCategoryTap,
    this.badgeCounts = const {},
  });

  @override
  State<RoomScene> createState() => _RoomSceneState();
}

class _RoomSceneState extends State<RoomScene> with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        final sx = 400 / box.size.width;
        final sy = 250 / box.size.height;
        final pt = Offset(local.dx * sx, local.dy * sy);

        // Converts an SVG-space rect to global screen coordinates.
        Rect toScreen(Rect svgRect) {
          final tl = box.localToGlobal(
            Offset(svgRect.left / sx, svgRect.top / sy),
          );
          return Rect.fromLTWH(
            tl.dx, tl.dy, svgRect.width / sx, svgRect.height / sy,
          );
        }

        if (_workshopRect.contains(pt)) {
          widget.onCategoryTap(QuestCategory.upgrades, toScreen(_workshopRect));
        } else if (_sinkRect.contains(pt)) {
          widget.onCategoryTap(QuestCategory.cleaning, toScreen(_sinkRect));
        } else if (_fridgeRect.contains(pt)) {
          widget.onCategoryTap(QuestCategory.groceries, toScreen(_fridgeRect));
        } else if (_deskRect.contains(pt)) {
          widget.onCategoryTap(QuestCategory.bills, toScreen(_deskRect));
        }
      },
      child: AnimatedBuilder(
        animation: _breath,
        builder: (_, __) => CustomPaint(
          painter: _RoomPainter(messy: widget.messy, breath: _breath.value, badgeCounts: widget.badgeCounts),
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
  final double breath; // 0..1
  final Map<QuestCategory, int> badgeCounts;

  const _RoomPainter({required this.messy, required this.breath, this.badgeCounts = const {}});

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
    if (messy) _drawFloorMess(canvas);
    _drawAvatar(canvas);
  }

  void _drawBackground(Canvas canvas) {
    // Wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 400, 160),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2DB0), Color(0xFF2E1D5A)],
        ).createShader(Rect.fromLTWH(0, 0, 400, 160)),
    );
    // Floor
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
    // Window gradient
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
    // Stars
    final starP = _f(Colors.white);
    canvas.drawCircle(const Offset(170, 40), 1.2, starP);
    canvas.drawCircle(const Offset(232, 78), 1.0, starP);
    canvas.drawCircle(const Offset(222, 40), 1.0, starP);
    // Cloud
    canvas.drawOval(
      Rect.fromCenter(center: Offset(195, 55), width: 28, height: 12),
      _f(Colors.white.withOpacity(.55)),
    );
  }

  void _drawVillain(Canvas canvas) {
    // Simplified villain peeking from window edge
    final bobY = (breath * 8) - 4; // bobs up/down
    canvas.save();
    canvas.translate(192, 20 + bobY);
    // Dark head silhouette
    final headPath = Path()
      ..moveTo(-20, 26)
      ..quadraticBezierTo(-20, -4, 0, -4)
      ..quadraticBezierTo(20, -4, 20, 26);
    canvas.drawPath(headPath, _f(const Color(0xFF1A0820)));
    canvas.drawPath(headPath, _s(_red, 1.6));
    // Spiky horns
    final hornL = Path()
      ..moveTo(-16, 4)..lineTo(-12, -8)..lineTo(-8, 4);
    final hornR = Path()
      ..moveTo(8, 4)..lineTo(12, -8)..lineTo(16, 4);
    canvas.drawPath(hornL, _f(const Color(0xFF1A0820)));
    canvas.drawPath(hornR, _f(const Color(0xFF1A0820)));
    canvas.drawPath(hornL, _s(_red, 1.2));
    canvas.drawPath(hornR, _s(_red, 1.2));
    // Glowing eyes
    canvas.drawOval(Rect.fromCenter(center: Offset(-7, 14), width: 6.4, height: 4.8), _f(AppColors.yellow));
    canvas.drawOval(Rect.fromCenter(center: Offset(7, 14), width: 6.4, height: 4.8), _f(AppColors.yellow));
    // Pupils
    canvas.drawCircle(const Offset(-7, 14), 1.8, _f(const Color(0xFF1A0820)));
    canvas.drawCircle(const Offset(7, 14), 1.8, _f(const Color(0xFF1A0820)));
    canvas.restore();
  }

  // WORKSHOP (Upgrades) ─ translate(22, 130)
  void _drawWorkshop(Canvas canvas) {
    canvas.save();
    canvas.translate(22, 130);

    // Pegboard
    canvas.drawRRect(_rr(6, -8, 58, 14, 3), _f(_surface));
    canvas.drawRRect(_rr(6, -8, 58, 14, 3), _s(_outline, 2));
    // Tools on pegboard
    canvas.drawRRect(_rr(14, -4, 6, 8, 1), _f(_yellow));
    canvas.drawRRect(_rr(26, -3, 10, 6, 1), _f(_green));
    canvas.drawCircle(const Offset(48, 0), 4, _s(_outline, 2.5));

    // Workbench top
    canvas.drawRRect(_rr(0, 14, 70, 8, 3), _f(_pink));
    canvas.drawRRect(_rr(0, 14, 70, 8, 3), _s(_outline, 2.5));
    // Cabinet
    canvas.drawRRect(_rr(4, 22, 62, 28, 4), _f(_surface2));
    canvas.drawRRect(_rr(4, 22, 62, 28, 4), _s(_outline, 2));

    // Hammer on bench (at 34,18)
    canvas.drawRRect(_rr(32, 17, 14, 3, 1), _f(_yellow));
    canvas.drawRRect(_rr(34, 13, 6, 11, 1.5), _f(_yellow));
    canvas.drawRRect(_rr(32, 17, 14, 3, 1), _s(_outline, 2));
    canvas.drawRRect(_rr(34, 13, 6, 11, 1.5), _s(_outline, 2));

    // Messy: scattered tools
    if (messy) {
      canvas.save();
      canvas.translate(44, 22);
      canvas.rotate(0.35);
      canvas.drawRRect(_rr(0, 0, 14, 3, 1), _f(_green));
      canvas.restore();
      final upgradesCount = badgeCounts[QuestCategory.upgrades] ?? 0;
      if (upgradesCount > 0) _drawBadge(canvas, 56, 4, upgradesCount);
    } else {
      // Tidy: glowing crystal
      final crystalPath = Path()
        ..moveTo(48, 18)..lineTo(52, 24)..lineTo(48, 30)..lineTo(44, 24)..close();
      canvas.drawPath(crystalPath, _f(_cyan));
      canvas.drawCircle(const Offset(48, 24), 6, _f(_cyan.withOpacity(.25)));
    }

    canvas.restore();
  }

  // SINK (Cleaning) ─ translate(100, 130)
  void _drawSink(Canvas canvas) {
    canvas.save();
    canvas.translate(100, 130);

    // Counter top (pink surface)
    canvas.drawRRect(_rr(0, 14, 60, 8, 3), _f(_pink));
    canvas.drawRRect(_rr(0, 14, 60, 8, 3), _s(_outline, 2.5));
    // Cabinet
    canvas.drawRRect(_rr(4, 22, 52, 28, 4), _f(_surface2));
    canvas.drawRRect(_rr(4, 22, 52, 28, 4), _s(_outline, 2));
    // Basin
    canvas.drawRRect(_rr(14, 6, 34, 14, 4), _f(const Color(0xFF0F7C99)));
    canvas.drawRRect(_rr(14, 6, 34, 14, 4), _s(_outline, 2.5));
    // Faucet
    final faucet = Path()
      ..moveTo(22, 6)..lineTo(22, 0)..lineTo(36, 0)..lineTo(36, 4);
    canvas.drawPath(faucet, _s(_outline, 2));
    canvas.drawCircle(const Offset(36, 4), 1.4, _f(_outline));

    if (messy) {
      // Dirty dish stack (tilted plates)
      canvas.save();
      canvas.translate(0, 0);
      canvas.save();
      canvas.rotate(-0.14);
      canvas.drawOval(Rect.fromCenter(center: Offset(22, 11), width: 18, height: 4.8), _f(const Color(0xFFCBD5E1)));
      canvas.restore();
      canvas.drawOval(Rect.fromCenter(center: Offset(22, 9), width: 18, height: 4.8), _f(const Color(0xFFE2E8F0)));
      canvas.drawRRect(_rr(32, 6, 9, 6, 1), _f(const Color(0xFF94A3B8)));
      // Stink lines
      final stink = _s(const Color(0xFF3DF09B), 1.2);
      for (final dx in [18.0, 26.0, 34.0]) {
        final p = Path()
          ..moveTo(dx, -1)
          ..quadraticBezierTo(dx + 2, -4, dx, -6);
        canvas.drawPath(p, stink);
      }
      canvas.restore();
      final cleaningCount = badgeCounts[QuestCategory.cleaning] ?? 0;
      if (cleaningCount > 0) _drawBadge(canvas, -2, 2, cleaningCount);
    } else {
      // Drying rack with plates
      canvas.drawRect(Rect.fromLTWH(50, 10, 14, 2), _f(_outline));
      for (final dx in [52.0, 56.0, 60.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(dx, 6), width: 2.8, height: 10), _f(Colors.white));
      }
      // Sparkle in basin
      final sp = Path()
        ..moveTo(26, 13)..lineTo(27, 11)..lineTo(28, 13)
        ..lineTo(30, 14)..lineTo(28, 15)..lineTo(27, 17)..lineTo(26, 15)
        ..lineTo(24, 14)..close();
      canvas.drawPath(sp, _f(_cyan));
    }

    canvas.restore();
  }

  // FRIDGE (Groceries) ─ translate(175, 108)
  void _drawFridge(Canvas canvas) {
    canvas.save();
    canvas.translate(175, 108);

    canvas.drawRRect(_rr(0, 0, 48, 62, 10), _f(_green));
    canvas.drawRRect(_rr(0, 0, 48, 62, 10), _s(_outline, 2.5));
    canvas.drawLine(const Offset(0, 22), const Offset(48, 22), _s(_outline, 2));
    // Handles
    canvas.drawRRect(_rr(38, 6, 4, 10, 1.5), _f(_outline));
    canvas.drawRRect(_rr(38, 32, 4, 14, 1.5), _f(_outline));

    if (messy) {
      // Empty inside with exclamation
      canvas.drawRRect(_rr(6, 6, 14, 3, 1), _f(Colors.white.withOpacity(.12)));
      canvas.drawRRect(_rr(6, 11, 8, 3, 1), _f(Colors.white.withOpacity(.12)));
      final groceriesCount = badgeCounts[QuestCategory.groceries] ?? 0;
      if (groceriesCount > 0) _drawBadge(canvas, -3, 4, groceriesCount);
    } else {
      // Sticky note
      canvas.drawRRect(_rr(6, 28, 10, 8, 1), _f(_yellow));
      canvas.drawRRect(_rr(6, 28, 10, 8, 1), _s(_outline, 2));
      // Food items
      canvas.drawRRect(_rr(6, 6, 6, 3, 1), _f(_yellow));
      canvas.drawRRect(_rr(14, 6, 10, 3, 1), _f(_violet));
      canvas.drawRRect(_rr(6, 11, 14, 3, 1), _f(_cyan));
    }

    canvas.restore();
  }

  // DESK (Bills) ─ translate(245, 108)
  void _drawDesk(Canvas canvas) {
    canvas.save();
    canvas.translate(245, 108);

    // Desk surface
    canvas.drawRRect(_rr(0, 40, 120, 10, 3), _f(_yellow));
    canvas.drawRRect(_rr(0, 40, 120, 10, 3), _s(_outline, 2.5));
    // Legs
    canvas.drawRRect(_rr(4, 50, 6, 22, 2), _f(_yellow));
    canvas.drawRRect(_rr(110, 50, 6, 22, 2), _f(_yellow));
    canvas.drawRRect(_rr(4, 50, 6, 22, 2), _s(_outline, 2));
    canvas.drawRRect(_rr(110, 50, 6, 22, 2), _s(_outline, 2));

    // Lamp
    canvas.drawLine(const Offset(14, 40), const Offset(14, 22), _s(_outline, 2));
    final lampShade = Path()
      ..moveTo(8, 22)..lineTo(22, 22)..lineTo(17, 16)..lineTo(11, 16)..close();
    canvas.drawPath(lampShade, _f(_violet));
    canvas.drawPath(lampShade, _s(_outline, 2));
    // Lamp glow
    canvas.drawCircle(const Offset(15, 28), 8, _f(_yellow.withOpacity(messy ? .08 : .2)));

    // Computer screen
    canvas.drawRRect(_rr(28, 20, 22, 18, 3), _f(_surface));
    canvas.drawRRect(_rr(28, 20, 22, 18, 3), _s(_outline, 2));
    canvas.drawRect(
      Rect.fromLTWH(30, 22, 18, 14),
      _f(messy ? const Color(0xFFEF4444) : const Color(0xFF22D3EE)),
    );

    if (messy) {
      // Scattered overdue bills
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
      // Coffee stain
      canvas.drawOval(Rect.fromCenter(center: Offset(106, 38), width: 12, height: 4), _f(const Color(0xFF78350F).withOpacity(.6)));
      final billsCount = badgeCounts[QuestCategory.bills] ?? 0;
      if (billsCount > 0) _drawBadge(canvas, -4, 20, billsCount);
    } else {
      // Neat papers
      canvas.drawRRect(_rr(64, 22, 22, 18, 1), _f(Colors.white));
      // Ruled lines
      for (final dy in [26.0, 29.0, 32.0]) {
        canvas.drawLine(Offset(68, dy), Offset(82, dy), _s(const Color(0xFF94A3B8), 1));
      }
      // Tidy mug
      canvas.drawRRect(_rr(95, 30, 10, 10, 2), _f(_cyan));
    }

    canvas.restore();
  }

  // AVATAR (Pip) ─ translate(310, 198 + breathOffset)
  void _drawAvatar(Canvas canvas) {
    final yOff = breath * 1.6 - 0.8;
    canvas.save();
    canvas.translate(310, 198 + yOff);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 42), width: 44, height: 8),
      _f(Colors.black.withOpacity(.4)),
    );
    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 20), width: 44, height: 44),
      _f(_violet),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 20), width: 44, height: 44),
      _s(_outline, 2),
    );
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 26), width: 28, height: 22),
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
    final mouthPath = Path()
      ..moveTo(-4, 24)..quadraticBezierTo(0, 28, 4, 24);
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

    // Dust bunny
    canvas.drawOval(Rect.fromCenter(center: Offset(170, 240), width: 18, height: 6), _f(Color(0xFF475569).withOpacity(.55)));
    canvas.drawCircle(const Offset(170, 237), 2, _f(Color(0xFF475569).withOpacity(.55)));
    // Crumpled papers
    for (final cx in [110.0, 180.0, 250.0]) {
      canvas.drawCircle(Offset(cx, 212), 4, _f(const Color(0xFFF1F5F9)));
    }
  }

  void _drawBadge(Canvas canvas, double x, double y, int count) {
    canvas.drawCircle(Offset(x, y), 7, _f(_red));
    canvas.drawCircle(Offset(x, y), 7, _s(_outline, 2));
    final tp = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.messy != messy || old.breath != breath || old.badgeCounts != badgeCounts;
}
