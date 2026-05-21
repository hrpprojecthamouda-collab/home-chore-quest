// Bedroom (room 0) — painted scene from the three-rooms design handoff.
//
// Contents:
//   • Wardrobe (decorative, back-left)
//   • Window (top-center, day/night)
//   • Desk + laptop + lamp + papers + calendar + chair  → ADMIN (QuestCategory.admin)
//   • Bed (decorative, full-width bottom band)
//   • Pip on the pillow, rendered as PipWithItems so equipment shows
//
// Geometry matches `HANDOFF_ROOMS.md` and `three-rooms-scene.jsx → BedroomScene`
// from the design bundle. Canvas is 400 × 600; tap-hit detection scales back
// from widget pixels into design coordinates.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animation/reward_controllers.dart';
import '../models/furniture_skin.dart';
import '../models/quest.dart';
import '../providers/furniture_providers.dart';
import '../providers/game_providers.dart';
import 'pip_mascot.dart';
import 'quest_count_badge.dart';
import 'room_shell_painter.dart';

// Hit targets in design space (400 × 600).
// Desk (back-right) → Admin. Bed (full-width front) → Bedroom.
const _kDeskRect = Rect.fromLTWH(200, 260, 180, 192);
const _kBedRect  = Rect.fromLTWH(20,  470, 320, 110);

// Pip lives on the pillow at design coord (70, 430) per handoff doc, scale 0.95.
const double _kPipSize = 60.0; // close to scale 0.95 × 64-default
const Offset _kPipPos  = Offset(70, 430);

class BedroomScene extends ConsumerStatefulWidget {
  /// When true, the villain peeks into the bedroom window (right-half — the
  /// evil/black side). Matches the messy-state villain in the living room.
  final bool messy;
  final void Function(QuestCategory category, Rect sourceRect)? onCategoryTap;
  final bool showPip;
  final PipController? pipController;
  /// Optional skin overrides for the customize preview. When null, the
  /// scene reads the live equipped skins from `resolvedFurnitureSkinsProvider`.
  final Map<FurnitureType, FurnitureSkin>? skinOverrides;
  /// True when this scene is the currently visible PageView page. False
  /// freezes the tap-cue ring animation so off-screen rooms don't burn the
  /// frame budget.
  final bool active;

  const BedroomScene({
    super.key,
    this.messy = false,
    this.onCategoryTap,
    this.showPip = true,
    this.pipController,
    this.skinOverrides,
    this.active = true,
  });

  @override
  ConsumerState<BedroomScene> createState() => _BedroomSceneState();
}

class _BedroomSceneState extends ConsumerState<BedroomScene>
    with TickerProviderStateMixin {
  late final AnimationController _tapCueCtrl;

  @override
  void initState() {
    super.initState();
    _tapCueCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    if (widget.active) _tapCueCtrl.repeat();
  }

  @override
  void didUpdateWidget(BedroomScene old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _tapCueCtrl.repeat();
      } else {
        _tapCueCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _tapCueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tapsEnabled = widget.onCategoryTap != null;
    return GestureDetector(
      onTapUp: !tapsEnabled
          ? null
          : (details) {
              final box = context.findRenderObject()! as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final sx = kRoomCanvasW / box.size.width;
              final sy = kRoomCanvasH / box.size.height;
              final pt = Offset(local.dx * sx, local.dy * sy);
              Rect toScreen(Rect r) {
                final tl = box.localToGlobal(Offset(r.left / sx, r.top / sy));
                return Rect.fromLTWH(tl.dx, tl.dy, r.width / sx, r.height / sy);
              }
              if (_kDeskRect.contains(pt)) {
                widget.onCategoryTap!(QuestCategory.admin, toScreen(_kDeskRect));
              } else if (_kBedRect.contains(pt)) {
                widget.onCategoryTap!(QuestCategory.bedroom, toScreen(_kBedRect));
              }
            },
      child: LayoutBuilder(
        builder: (_, constraints) {
          final sx = constraints.maxWidth / kRoomCanvasW;
          final sy = constraints.maxHeight / kRoomCanvasH;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _tapCueCtrl,
                builder: (_, __) {
                  final hour = DateTime.now().hour;
                  final daytime = hour >= 6 && hour < 19;
                  final providerSkins = ref.watch(resolvedFurnitureSkinsProvider);
                  final skins = widget.skinOverrides != null
                      ? {for (final t in FurnitureType.values) t: widget.skinOverrides![t] ?? kDefaultSkins[t]!}
                      : providerSkins;
                  return CustomPaint(
                    painter: _BedroomPainter(
                      daytime: daytime,
                      tapCueAngle: _tapCueCtrl.value * 2 * math.pi,
                      messy: widget.messy,
                      skins: skins,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
              if (widget.showPip)
                Positioned(
                  left: _kPipPos.dx * sx - _kPipSize / 2,
                  top:  _kPipPos.dy * sy - _kPipSize / 2,
                  child: PipWithItems(
                    size: _kPipSize,
                    controller: widget.pipController,
                  ),
                ),
              // Admin (desk) badge — top-right corner of the desk.
              Positioned(
                left: 285 * sx,
                top:  250 * sy,
                child: QuestCountBadge(
                  count: ref.watch(
                    pendingQuestsByCategory(QuestCategory.admin),
                  ).length,
                ),
              ),
              // Bedroom (bed) badge — centered above the bed.
              Positioned(
                left: 180 * sx,
                top:  455 * sy,
                child: QuestCountBadge(
                  count: ref.watch(
                    pendingQuestsByCategory(QuestCategory.bedroom),
                  ).length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BedroomPainter extends CustomPainter {
  final bool daytime;
  final double tapCueAngle;
  final bool messy;
  final Map<FurnitureType, FurnitureSkin> skins;

  _BedroomPainter({
    required this.daytime,
    required this.tapCueAngle,
    required this.skins,
    this.messy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.scale(size.width / kRoomCanvasW, size.height / kRoomCanvasH);

    paintRoomShell(canvas);

    // Window — and if the apartment is messy, the villain leans in from
    // OUTSIDE the right edge of the glass so only his angelic/white side
    // crosses into view. Paint the full head and let the clipRect do the
    // peeking: most of him stays hidden behind the wall, only the half
    // that crosses the glass shows.
    const winX = 150.0, winY = 50.0, winW = 170.0, winH = 150.0;
    paintWindow(canvas, x: winX, y: winY, w: winW, h: winH, daytime: daytime);
    if (messy) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(winX, winY, winW, winH));
      // Chin sits at ~55% down the glass; head center is 5px PAST the right
      // edge of the glass so the seam line and the evil half stay hidden
      // behind the right wall — only the angelic-left half is exposed.
      canvas.translate(winX + winW + 5, winY + winH * 0.55);
      paintVillain(canvas, side: VillainSide.full);
      canvas.restore();
    }

    // Amber zone glow under the desk (Admin).
    final glowRect = Rect.fromCenter(center: const Offset(310, 450), width: 240, height: 120);
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [RoomPalette.amber.withValues(alpha: 0.55), RoomPalette.amber.withValues(alpha: 0)],
        ).createShader(glowRect),
    );

    _drawWardrobe(canvas);
    _drawDeskAdmin(canvas);
    _drawBed(canvas);

    // Tap-cue ring centred over the desk top (Admin). Sits on the laptop +
    // desk surface so it's clearly the desk that's tappable — not the bed.
    paintTapCueRing(
      canvas,
      cx: 290,
      cy: 380,
      r: 50,
      color: RoomPalette.amber,
      angle: tapCueAngle,
    );

    // ADMIN pill badge above the desk corner.
    paintPillBadge(
      canvas,
      cx: 337,
      cy: 340,
      width: 46,
      fillColor: RoomPalette.amber,
      strokeColor: RoomPalette.outWarm,
      textColor: const Color(0xFF3a1c00),
      label: 'ADMIN',
    );

    // Tap-cue ring near the foot of the bed (Bedroom — making the bed,
    // changing sheets, organizing the wardrobe).
    paintTapCueRing(
      canvas,
      cx: 180,
      cy: 520,
      r: 70,
      color: RoomPalette.violet,
      angle: tapCueAngle,
    );

    // BEDROOM pill badge above the headboard.
    paintPillBadge(
      canvas,
      cx: 60,
      cy: 458,
      width: 64,
      fillColor: RoomPalette.violet,
      strokeColor: RoomPalette.outDark,
      textColor: const Color(0xFF2a1058),
      label: 'BEDROOM',
    );

    canvas.restore();
  }

  // ── Wardrobe (back-left, decorative) ───────────────────────────
  void _drawWardrobe(Canvas canvas) {
    final ws = skins[FurnitureType.wardrobe]!;
    canvas.save();
    canvas.translate(30, 130);

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(55, 248), width: 120, height: 10),
      fillPaint(Colors.black.withValues(alpha: 0.5)),
    );

    // Body (frame color).
    canvas.drawRRect(rr(0, 0, 110, 250, 6), fillPaint(ws.light));
    canvas.drawRRect(rr(0, 0, 110, 250, 6), strokePaint(RoomPalette.outWarm, 1.6));

    // Doors (primary color).
    canvas.drawRRect(rr(6, 8, 46, 234, 3), fillPaint(ws.primary));
    canvas.drawRRect(rr(6, 8, 46, 234, 3), strokePaint(RoomPalette.outWarm, 1.2));
    canvas.drawRRect(rr(58, 8, 46, 234, 3), fillPaint(ws.primary));
    canvas.drawRRect(rr(58, 8, 46, 234, 3), strokePaint(RoomPalette.outWarm, 1.2));

    // Inset panels (dark accent).
    final inset = fillPaint(ws.dark.withValues(alpha: 0.6));
    canvas.drawRRect(rr(12, 20, 34, 90, 2), inset);
    canvas.drawRRect(rr(64, 20, 34, 90, 2), inset);
    canvas.drawRRect(rr(12, 124, 34, 110, 2), inset);
    canvas.drawRRect(rr(64, 124, 34, 110, 2), inset);

    // Handles.
    canvas.drawRRect(rr(44, 118, 3, 14, 1.5), fillPaint(const Color(0xFFfde047)));
    canvas.drawRRect(rr(63, 118, 3, 14, 1.5), fillPaint(const Color(0xFFfde047)));

    // Mirror disc on left door.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(29, 68), width: 22, height: 26),
      fillPaint(RoomPalette.outMid),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(29, 68), width: 22, height: 26),
      strokePaint(RoomPalette.outWarm, 1.2),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(26, 64), width: 12, height: 14),
      fillPaint(const Color(0xFF7ab8ff).withValues(alpha: 0.7)),
    );

    canvas.restore();
  }

  // ── Desk + laptop + lamp + papers + calendar + chair (ADMIN) ───
  void _drawDeskAdmin(Canvas canvas) {
    final ds = skins[FurnitureType.desk]!;
    canvas.save();
    canvas.translate(200, 200);

    final lampOn = !daytime;

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 244), width: 200, height: 12),
      fillPaint(Colors.black.withValues(alpha: 0.55)),
    );

    // Lamp warm glow when night.
    if (lampOn) {
      final glowRect = Rect.fromCenter(center: const Offset(32, 40), width: 160, height: 110);
      canvas.drawOval(
        glowRect,
        fillPaint(RoomPalette.amber.withValues(alpha: 0.35)),
      );
    }

    // Desk top (primary).
    canvas.drawRRect(rr(0, 160, 180, 12, 3), fillPaint(ds.primary));
    canvas.drawRRect(rr(0, 160, 180, 12, 3), strokePaint(RoomPalette.outWarm, 1.6));

    // Legs (dark).
    canvas.drawRect(const Rect.fromLTWH(6, 172, 10, 80), fillPaint(ds.dark));
    canvas.drawRect(const Rect.fromLTWH(6, 172, 10, 80), strokePaint(RoomPalette.outWarm, 1.2));
    canvas.drawRect(const Rect.fromLTWH(164, 172, 10, 80), fillPaint(ds.dark));
    canvas.drawRect(const Rect.fromLTWH(164, 172, 10, 80), strokePaint(RoomPalette.outWarm, 1.2));

    // Drawer cabinet (dark body, lighter drawer faces).
    canvas.drawRRect(rr(100, 174, 68, 78, 2), fillPaint(ds.dark));
    canvas.drawRRect(rr(100, 174, 68, 78, 2), strokePaint(RoomPalette.outWarm, 1.6));
    for (final dy in const [178.0, 204.0, 230.0]) {
      final h = dy == 230.0 ? 20.0 : 22.0;
      canvas.drawRRect(rr(104, dy, 60, h, 1.5), fillPaint(ds.light));
      canvas.drawRRect(rr(104, dy, 60, h, 1.5), strokePaint(RoomPalette.outWarm, 1.2));
      canvas.drawRRect(rr(124, dy + 9, 14, 3, 1), fillPaint(ds.primary));
    }

    // Laptop (open).
    canvas.save();
    canvas.translate(50, 108);
    canvas.drawRRect(rr(0, 0, 86, 50, 4), fillPaint(const Color(0xFF0f1230)));
    canvas.drawRRect(rr(0, 0, 86, 50, 4), strokePaint(RoomPalette.outDark, 1.6));
    canvas.drawRRect(rr(4, 4, 78, 42, 2), fillPaint(const Color(0xFF7ab8ff)));
    canvas.drawRRect(rr(9, 9, 32, 6, 1.5), fillPaint(Colors.white.withValues(alpha: 0.95)));
    canvas.drawRRect(rr(9, 19, 50, 3, 1), fillPaint(Colors.white.withValues(alpha: 0.7)));
    canvas.drawRRect(rr(9, 25, 42, 3, 1), fillPaint(Colors.white.withValues(alpha: 0.7)));
    canvas.drawRRect(rr(50, 30, 28, 14, 2), fillPaint(Colors.white));
    _paintText(canvas, r'$', const Offset(64, 37), 11, const Color(0xFF1e1b4b));
    final base = Path()
      ..moveTo(-6, 50)
      ..lineTo(92, 50)
      ..lineTo(86, 58)
      ..lineTo(0, 58)
      ..close();
    canvas.drawPath(base, fillPaint(const Color(0xFFcbd5e1)));
    canvas.drawPath(base, strokePaint(RoomPalette.outDark, 1.6));
    if (lampOn) {
      canvas.drawRRect(
        rr(-2, -2, 90, 54, 5),
        Paint()
          ..color = RoomPalette.amber.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.restore();

    // Desk lamp.
    canvas.save();
    canvas.translate(10, 60);
    canvas.drawRRect(rr(8, 92, 22, 6, 2), fillPaint(const Color(0xFF3a230f)));
    canvas.drawRRect(rr(8, 92, 22, 6, 2), strokePaint(RoomPalette.outWarm, 1.2));
    canvas.drawRect(const Rect.fromLTWH(17, 40, 4, 54), fillPaint(const Color(0xFFa86b3a)));
    canvas.drawLine(const Offset(19, 40), const Offset(35, 16), strokePaint(const Color(0xFFa86b3a), 3));
    final shade = Path()
      ..moveTo(24, 22)
      ..quadraticBezierTo(38, 6, 50, 14)
      ..lineTo(42, 32)
      ..quadraticBezierTo(30, 28, 24, 24)
      ..close();
    canvas.drawPath(shade, fillPaint(lampOn ? const Color(0xFFffe4a3) : const Color(0xFF5a3a1d)));
    canvas.drawPath(shade, strokePaint(RoomPalette.outWarm, 1.4));
    if (lampOn) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(38, 22), width: 12, height: 6),
        fillPaint(const Color(0xFFfff5e0).withValues(alpha: 0.85)),
      );
    }
    canvas.restore();

    // Paper stack on desk corner.
    canvas.save();
    canvas.translate(8, 140);
    canvas.save();
    canvas.translate(17, 13);
    canvas.rotate(-4 * math.pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), fillPaint(const Color(0xFFfef9c3)));
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), strokePaint(RoomPalette.outWarm, 1));
    canvas.restore();
    canvas.save();
    canvas.translate(19, 7);
    canvas.rotate(3 * math.pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), fillPaint(Colors.white));
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), strokePaint(RoomPalette.outWarm, 1));
    canvas.restore();
    canvas.save();
    canvas.translate(21, 1);
    canvas.rotate(-2 * math.pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), fillPaint(const Color(0xFFffd9ec)));
    canvas.drawRect(const Rect.fromLTWH(-17, -3, 34, 6), strokePaint(RoomPalette.outWarm, 1));
    canvas.restore();
    canvas.restore();

    // Calendar on desk.
    canvas.save();
    canvas.translate(140, 130);
    final easel = Path()
      ..moveTo(4, 24)
      ..lineTo(30, 24)
      ..lineTo(28, 30)
      ..lineTo(6, 30)
      ..close();
    canvas.drawPath(easel, fillPaint(const Color(0xFF3a230f)));
    canvas.drawRRect(rr(0, 0, 34, 26, 2), fillPaint(const Color(0xFFfff5e6)));
    canvas.drawRRect(rr(0, 0, 34, 26, 2), strokePaint(RoomPalette.outDark, 1.2));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 34, 8), fillPaint(RoomPalette.amber));
    _paintText(canvas, 'ADMIN', const Offset(17, 4), 5.5, Colors.white);
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 4; c++) {
        canvas.drawCircle(Offset(5 + c * 7.0, 14 + r * 5.0), 1, fillPaint(const Color(0xFFa78bfa)));
      }
    }
    canvas.drawCircle(
      const Offset(26, 19),
      2.4,
      Paint()
        ..color = const Color(0xFFef4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();

    // Chair back peeking out from behind the desk — uses the desk's wood tones.
    canvas.save();
    canvas.translate(30, 174);
    canvas.drawRRect(rr(0, 0, 50, 70, 4), fillPaint(ds.dark));
    canvas.drawRRect(rr(0, 0, 50, 70, 4), strokePaint(RoomPalette.outWarm, 1.4));
    canvas.drawRRect(rr(6, 6, 38, 34, 3), fillPaint(ds.light));
    canvas.restore();

    canvas.restore();
  }

  // ── Bed (front, decorative) ────────────────────────────────────
  void _drawBed(Canvas canvas) {
    final bs = skins[FurnitureType.bed]!;
    canvas.save();
    canvas.translate(20, 420);

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(160, 160), width: 340, height: 16),
      fillPaint(Colors.black.withValues(alpha: 0.55)),
    );

    // Frame base (dark — wood frame).
    canvas.drawRRect(rr(0, 50, 320, 100, 8), fillPaint(bs.dark));
    canvas.drawRRect(rr(0, 50, 320, 100, 8), strokePaint(RoomPalette.outWarm, 1.6));

    // Mattress (light).
    canvas.drawRRect(rr(6, 34, 308, 34, 6), fillPaint(bs.light));
    canvas.drawRRect(rr(6, 34, 308, 34, 6), strokePaint(RoomPalette.outMid, 1.4));

    // Fitted-sheet stripe (primary tinted).
    canvas.drawRect(
      const Rect.fromLTWH(6, 58, 308, 10),
      fillPaint(bs.primary.withValues(alpha: 0.5)),
    );

    // Headboard (wood frame, slightly lighter than the base).
    canvas.drawRRect(rr(0, -10, 80, 60, 6), fillPaint(bs.dark));
    canvas.drawRRect(rr(0, -10, 80, 60, 6), strokePaint(RoomPalette.outWarm, 1.6));
    canvas.drawRRect(rr(6, -4, 68, 48, 4), fillPaint(Colors.black.withValues(alpha: 0.3)));

    // Footboard (wood frame).
    canvas.drawRRect(rr(282, 50, 38, 30, 4), fillPaint(bs.dark));
    canvas.drawRRect(rr(282, 50, 38, 30, 4), strokePaint(RoomPalette.outWarm, 1.6));

    // Pillow (stays white).
    canvas.drawRRect(rr(14, 6, 74, 36, 10), fillPaint(Colors.white));
    canvas.drawRRect(rr(14, 6, 74, 36, 10), strokePaint(RoomPalette.outMid, 1.4));
    canvas.drawRRect(rr(20, 12, 44, 6, 3), fillPaint(const Color(0xFFe8e2ff)));

    // Duvet drape (primary — the dominant color of the bed skin).
    final drape = Path()
      ..moveTo(94, 34)
      ..quadraticBezierTo(180, 30, 270, 38)
      ..lineTo(270, 66)
      ..quadraticBezierTo(180, 60, 94, 66)
      ..close();
    canvas.drawPath(drape, fillPaint(bs.primary));
    canvas.drawPath(drape, strokePaint(RoomPalette.outMid, 1.4));
    // Fold hint lines.
    final fold = strokePaint(RoomPalette.outMid.withValues(alpha: 0.6), 0.8);
    final f1 = Path()..moveTo(130, 38)..quadraticBezierTo(130, 50, 134, 64);
    final f2 = Path()..moveTo(200, 38)..quadraticBezierTo(198, 50, 202, 64);
    canvas.drawPath(f1, fold);
    canvas.drawPath(f2, fold);

    // Moon embroidery on duvet.
    canvas.drawCircle(const Offset(220, 50), 5, fillPaint(const Color(0xFFfde047).withValues(alpha: 0.95)));
    canvas.drawCircle(const Offset(220, 50), 5, strokePaint(RoomPalette.outMid, 0.8));
    canvas.drawCircle(const Offset(222, 50), 3.6, fillPaint(const Color(0xFF7ab8ff)));

    // Legs.
    canvas.drawRRect(rr(2, 148, 10, 10, 2), fillPaint(const Color(0xFF3a230f)));
    canvas.drawRRect(rr(308, 148, 10, 10, 2), fillPaint(const Color(0xFF3a230f)));

    canvas.restore();
  }

  // ── Text helper ────────────────────────────────────────────────
  void _paintText(Canvas canvas, String text, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_BedroomPainter old) =>
      old.daytime != daytime ||
      old.tapCueAngle != tapCueAngle ||
      old.messy != messy ||
      old.skins != skins;
}
