// Bathroom (room 2) — painted scene from the three-rooms design handoff.
//
// Contents:
//   • Window (top-center, day/night)
//   • Mirror + sink + cabinet  → BATHROOM (back-right)
//   • Toilet                   → BATHROOM (back-left)
//   • Washing machine          → LAUNDRY  (front-right)
//   • Pip on the floor (front-left), rendered as PipWithItems so equipment shows
//
// Note: the decorative bathtub and bath mat from the original handoff were
// removed at the user's request — the bathroom now reads more like a powder room.
//
// Geometry matches `HANDOFF_ROOMS.md` and `three-rooms-scene.jsx → BathroomScene`
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

// Hit targets in design space (400 × 600), per handoff hit-percent table.
// Toilet and mirror+sink both route to QuestCategory.bathroom.
const _kToiletRect    = Rect.fromLTWH(38,  230, 120, 160); // toilet → Bathroom (back-left)
const _kMirrorRect    = Rect.fromLTWH(258, 150, 118, 226); // mirror + sink → Bathroom
const _kWasherRect    = Rect.fromLTWH(240, 386, 140, 190); // washer → Laundry

const double _kPipSize = 54.0; // close to scale 0.85 × 64-default
const Offset _kPipPos  = Offset(120, 510);

class BathroomScene extends ConsumerStatefulWidget {
  /// When true, the villain peeks into the bathroom window (left-half — the
  /// angelic/white side). Matches the messy-state villain in the living room.
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

  const BathroomScene({
    super.key,
    this.messy = false,
    this.onCategoryTap,
    this.showPip = true,
    this.pipController,
    this.skinOverrides,
    this.active = true,
  });

  @override
  ConsumerState<BathroomScene> createState() => _BathroomSceneState();
}

class _BathroomSceneState extends ConsumerState<BathroomScene>
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
  void didUpdateWidget(BathroomScene old) {
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
              // Bathroom (toilet, mirror+sink, tub) has its own category,
              // distinct from living-area cleaning. Either the toilet or the
              // mirror+sink can open it.
              if (_kToiletRect.contains(pt)) {
                widget.onCategoryTap!(QuestCategory.bathroom, toScreen(_kToiletRect));
              } else if (_kMirrorRect.contains(pt)) {
                widget.onCategoryTap!(QuestCategory.bathroom, toScreen(_kMirrorRect));
              } else if (_kWasherRect.contains(pt)) {
                widget.onCategoryTap!(QuestCategory.laundry, toScreen(_kWasherRect));
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
                    painter: _BathroomPainter(
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
              // Bathroom badge — top-right of the toilet.
              Positioned(
                left: 140 * sx,
                top:  220 * sy,
                child: QuestCountBadge(
                  count: ref.watch(
                    pendingQuestsByCategory(QuestCategory.bathroom),
                  ).length,
                ),
              ),
              // Laundry badge — top-right of the washer.
              Positioned(
                left: 345 * sx,
                top:  380 * sy,
                child: QuestCountBadge(
                  count: ref.watch(
                    pendingQuestsByCategory(QuestCategory.laundry),
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
class _BathroomPainter extends CustomPainter {
  final bool daytime;
  final double tapCueAngle;
  final bool messy;
  final Map<FurnitureType, FurnitureSkin> skins;

  _BathroomPainter({
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

    // Subtle white tile pattern over the wall (12 × 9 grid of 36 × 36 squares).
    final tile = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 12; c++) {
        canvas.drawRect(Rect.fromLTWH(c * 36.0, 50 + r * 36.0, 34, 34), tile);
      }
    }

    // Window — and if messy, the villain leans in from OUTSIDE the left
    // edge of the glass so only his evil/dark side crosses into view. Paint
    // the full head and let the clipRect do the peeking: most of him stays
    // hidden behind the wall, only the half that crosses the glass shows.
    // Smaller window → smaller villain scale.
    const winX = 158.0, winY = 36.0, winW = 84.0, winH = 94.0;
    paintWindow(canvas, x: winX, y: winY, w: winW, h: winH, daytime: daytime);
    if (messy) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(winX, winY, winW, winH));
      // Head center 5px PAST the left edge — so the angelic-left half and the
      // seam stay hidden behind the wall and only the evil-right half is
      // exposed. Chin at ~55% down the glass.
      canvas.translate(winX - 5, winY + winH * 0.55);
      paintVillain(canvas, side: VillainSide.full, scale: 0.75);
      canvas.restore();
    }

    // Zone glows — toilet (teal, front-left) and washer (pink, front-right).
    _drawZoneGlow(canvas, const Offset(96, 330), 200, 160, RoomPalette.teal, 0.4);
    _drawSoftOval(canvas, const Offset(310, 490), 200, 120, RoomPalette.pink.withValues(alpha: 0.18));

    _drawMirrorSink(canvas);
    _drawToiletCleaning(canvas);
    _drawWasherLaundry(canvas);
    // Bath mat removed per design revision.

    // Tap cues — toilet + mirror are both Bathroom (teal), washer is
    // Laundry (pink).
    paintTapCueRing(
      canvas,
      cx: 96,
      cy: 320,
      r: 56,
      color: RoomPalette.teal,
      angle: tapCueAngle,
    );
    paintTapCueRing(
      canvas,
      cx: 315,
      cy: 250,
      r: 56,
      color: RoomPalette.teal,
      angle: tapCueAngle,
    );
    paintTapCueRing(
      canvas,
      cx: 310,
      cy: 490,
      r: 70,
      color: RoomPalette.pink,
      angle: tapCueAngle,
    );

    canvas.restore();
  }

  // ── Helpers ────────────────────────────────────────────────────
  void _drawZoneGlow(Canvas canvas, Offset center, double rx, double ry, Color color, double op) {
    final r = Rect.fromCenter(center: center, width: rx, height: ry);
    canvas.drawOval(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.55 * op), color.withValues(alpha: 0)],
        ).createShader(r),
    );
  }

  void _drawSoftOval(Canvas canvas, Offset center, double rx, double ry, Color color) {
    final r = Rect.fromCenter(center: center, width: rx, height: ry);
    canvas.drawOval(r, fillPaint(color));
  }

  // ── Mirror + sink + cabinet ────────────────────────────────────
  void _drawMirrorSink(Canvas canvas) {
    final ms = skins[FurnitureType.mirrorSink]!;
    canvas.save();
    canvas.translate(260, 150);

    // Mirror frame (primary).
    canvas.drawRRect(rr(0, 0, 110, 100, 10), fillPaint(ms.primary));
    canvas.drawRRect(rr(0, 0, 110, 100, 10), strokePaint(RoomPalette.outWarm, 1.6));
    canvas.drawRRect(rr(6, 6, 98, 88, 6), fillPaint(const Color(0xFF2a2050)));
    canvas.drawRRect(rr(6, 6, 98, 88, 6), strokePaint(RoomPalette.outMid, 1));
    // Teal reflection tint.
    canvas.drawRRect(rr(6, 6, 98, 88, 6), fillPaint(RoomPalette.teal.withValues(alpha: 0.18)));
    // Highlight.
    final glint = Path()..moveTo(12, 12)..lineTo(36, 12)..lineTo(12, 40)..close();
    canvas.drawPath(glint, fillPaint(Colors.white.withValues(alpha: 0.08)));

    // Shelf (primary).
    canvas.drawRRect(rr(-6, 106, 122, 6, 2), fillPaint(ms.primary));
    canvas.drawRRect(rr(-6, 106, 122, 6, 2), strokePaint(RoomPalette.outWarm, 1.2));

    // Soap pump (stays neutral white + pink top).
    canvas.save();
    canvas.translate(8, 96);
    canvas.drawRRect(rr(0, 0, 12, 14, 2), fillPaint(Colors.white));
    canvas.drawRRect(rr(0, 0, 12, 14, 2), strokePaint(RoomPalette.outDark, 1));
    canvas.drawRRect(rr(3, -4, 6, 6, 1), fillPaint(RoomPalette.pink));
    canvas.restore();

    // Toothbrush cup (stays amber).
    canvas.save();
    canvas.translate(86, 96);
    canvas.drawRRect(rr(0, 0, 10, 12, 1.5), fillPaint(RoomPalette.amber));
    canvas.drawRRect(rr(0, 0, 10, 12, 1.5), strokePaint(RoomPalette.outDark, 1));
    canvas.drawRRect(rr(2, -2, 6, 2, 1), fillPaint(Colors.white));
    canvas.restore();

    // Sink basin (light — porcelain).
    canvas.drawRRect(rr(-4, 118, 118, 32, 14), fillPaint(const Color(0xFFf3f1ff)));
    canvas.drawRRect(rr(-4, 118, 118, 32, 14), strokePaint(RoomPalette.outMid, 1.6));
    // Inner water uses skin's light tone (e.g. brass → warm; chrome → cool).
    canvas.drawRRect(rr(6, 124, 98, 22, 10), fillPaint(ms.light));
    canvas.drawRRect(rr(6, 124, 98, 22, 10), strokePaint(RoomPalette.outMid, 1));

    // Drain.
    canvas.drawCircle(const Offset(55, 138), 3, fillPaint(RoomPalette.outDark));

    // Cabinet under sink (primary outer, dark inner panels).
    canvas.drawRRect(rr(-2, 150, 114, 76, 3), fillPaint(ms.primary));
    canvas.drawRRect(rr(-2, 150, 114, 76, 3), strokePaint(RoomPalette.outWarm, 1.6));
    canvas.drawRRect(rr(2, 154, 54, 68, 2), fillPaint(ms.dark));
    canvas.drawRRect(rr(2, 154, 54, 68, 2), strokePaint(RoomPalette.outWarm, 1));
    canvas.drawRRect(rr(58, 154, 52, 68, 2), fillPaint(ms.dark));
    canvas.drawRRect(rr(58, 154, 52, 68, 2), strokePaint(RoomPalette.outWarm, 1));
    canvas.drawCircle(const Offset(54, 188), 1.4, fillPaint(const Color(0xFFa86b3a)));
    canvas.drawCircle(const Offset(60, 188), 1.4, fillPaint(const Color(0xFFa86b3a)));

    // Mini faucet over the basin.
    canvas.drawRRect(rr(51, 106, 3, 14, 1), fillPaint(const Color(0xFFcbd5e1)));
    final mini = Path()..moveTo(53, 120)..quadraticBezierTo(53, 126, 58, 128);
    canvas.drawPath(mini, strokePaint(const Color(0xFFcbd5e1), 2.4));

    canvas.restore();
  }

  // ── Toilet (BATHROOM) ──────────────────────────────────────────
  // Sits in the back-left of the room with its tank against the back wall
  // (canvas y:230–290) and the base resting on the floor seam (y:380).
  void _drawToiletCleaning(Canvas canvas) {
    final ts = skins[FurnitureType.toilet]!;
    canvas.save();
    canvas.translate(38, 230);

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 172), width: 140, height: 12),
      fillPaint(Colors.black.withValues(alpha: 0.55)),
    );

    // Tank (ceramic primary).
    canvas.drawRRect(rr(20, 0, 76, 60, 6), fillPaint(ts.primary));
    canvas.drawRRect(rr(20, 0, 76, 60, 6), strokePaint(RoomPalette.outMid, 1.6));
    canvas.drawLine(const Offset(20, 14), const Offset(96, 14), strokePaint(RoomPalette.outMid, 1));

    // Flush button (metallic — stays neutral).
    canvas.drawRRect(rr(50, 4, 16, 6, 2), fillPaint(const Color(0xFFcbd5e1)));
    canvas.drawRRect(rr(50, 4, 16, 6, 2), strokePaint(RoomPalette.outMid, 1));

    // Seat top (ceramic primary outer, water-blue inner).
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 76), width: 112, height: 32),
      fillPaint(ts.primary),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 76), width: 112, height: 32),
      strokePaint(RoomPalette.outMid, 1.6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 76), width: 88, height: 20),
      fillPaint(ts.light),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 76), width: 88, height: 20),
      strokePaint(RoomPalette.outMid, 1),
    );

    // Bowl front (ceramic primary).
    final bowl = Path()
      ..moveTo(8, 80)
      ..quadraticBezierTo(8, 124, 36, 142)
      ..lineTo(80, 142)
      ..quadraticBezierTo(108, 124, 108, 80)
      ..lineTo(100, 76)
      ..quadraticBezierTo(100, 110, 80, 124)
      ..lineTo(36, 124)
      ..quadraticBezierTo(16, 110, 16, 76)
      ..close();
    canvas.drawPath(bowl, fillPaint(ts.primary));
    canvas.drawPath(bowl, strokePaint(RoomPalette.outMid, 1.6));

    // Shine.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(34, 92), width: 16, height: 6),
      fillPaint(Colors.white.withValues(alpha: 0.9)),
    );

    // Base (ceramic primary).
    canvas.drawRRect(rr(40, 138, 38, 22, 3), fillPaint(ts.primary));
    canvas.drawRRect(rr(40, 138, 38, 22, 3), strokePaint(RoomPalette.outMid, 1.4));

    // BATHROOM badge sits just below the toilet base on the floor.
    canvas.restore();
    paintPillBadge(
      canvas,
      cx: 96,
      cy: 410,
      width: 64,
      fillColor: RoomPalette.teal,
      strokeColor: RoomPalette.outDark,
      textColor: const Color(0xFF0a3540),
      label: 'BATHROOM',
    );
  }

  // ── Washing machine (LAUNDRY) ──────────────────────────────────
  void _drawWasherLaundry(Canvas canvas) {
    canvas.save();
    canvas.translate(240, 386);

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(70, 192), width: 160, height: 12),
      fillPaint(Colors.black.withValues(alpha: 0.55)),
    );

    // Body.
    canvas.drawRRect(rr(0, 0, 140, 180, 10), fillPaint(const Color(0xFFf4f6ff)));
    canvas.drawRRect(rr(0, 0, 140, 180, 10), strokePaint(RoomPalette.outMid, 1.6));

    // Control panel.
    canvas.drawRRect(rr(6, 6, 128, 24, 3), fillPaint(const Color(0xFFa78bfa)));
    canvas.drawRRect(rr(6, 6, 128, 24, 3), strokePaint(RoomPalette.outMid, 1.6));
    canvas.drawCircle(const Offset(20, 18), 5, fillPaint(Colors.white));
    canvas.drawCircle(const Offset(20, 18), 5, strokePaint(RoomPalette.outMid, 1));
    canvas.drawLine(const Offset(20, 14), const Offset(20, 18), strokePaint(RoomPalette.outMid, 1.2));
    canvas.drawRRect(rr(34, 13, 68, 10, 2), fillPaint(RoomPalette.pink));
    canvas.drawRRect(rr(34, 13, 68, 10, 2), strokePaint(RoomPalette.outMid, 1));
    _paintText(canvas, 'SPIN ⟳', const Offset(68, 18), 7, Colors.white);
    canvas.drawCircle(const Offset(120, 18), 5, fillPaint(Colors.white));
    canvas.drawCircle(const Offset(120, 18), 5, strokePaint(RoomPalette.outMid, 1));

    // Porthole.
    canvas.drawCircle(const Offset(70, 100), 46, fillPaint(RoomPalette.outMid));
    canvas.drawCircle(const Offset(70, 100), 40, fillPaint(const Color(0xFF161028)));
    canvas.drawCircle(const Offset(70, 100), 40, strokePaint(RoomPalette.outMid, 1.2));
    canvas.drawCircle(const Offset(70, 100), 34, fillPaint(const Color(0xFFbfeaff)));

    // Tumbling clothes.
    canvas.save();
    canvas.translate(60, 92);
    canvas.rotate(-15 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20, height: 12), fillPaint(const Color(0xFFfb7185)));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20, height: 12), strokePaint(RoomPalette.outMid, 1));
    canvas.restore();
    canvas.save();
    canvas.translate(82, 108);
    canvas.rotate(20 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 10), fillPaint(const Color(0xFFfde047)));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 10), strokePaint(RoomPalette.outMid, 1));
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(64, 114), width: 14, height: 8),
      fillPaint(const Color(0xFFa78bfa)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(64, 114), width: 14, height: 8),
      strokePaint(RoomPalette.outMid, 1),
    );

    // Foam.
    canvas.drawCircle(const Offset(50, 84), 3, fillPaint(Colors.white.withValues(alpha: 0.95)));
    canvas.drawCircle(const Offset(86, 92), 2.6, fillPaint(Colors.white.withValues(alpha: 0.9)));
    canvas.drawCircle(const Offset(72, 80), 2.4, fillPaint(Colors.white.withValues(alpha: 0.9)));

    // Glass glint.
    final portGlint = Path()
      ..moveTo(50, 84)
      ..quadraticBezierTo(58, 76, 70, 76);
    canvas.drawPath(portGlint, strokePaint(Colors.white.withValues(alpha: 0.5), 2.2));

    // Body shine stripe.
    canvas.drawRRect(rr(6, 40, 5, 130, 2), fillPaint(Colors.white.withValues(alpha: 0.5)));

    // Feet.
    canvas.drawRRect(rr(8, 178, 16, 10, 2), fillPaint(const Color(0xFF9d8be0)));
    canvas.drawRRect(rr(8, 178, 16, 10, 2), strokePaint(RoomPalette.outMid, 1));
    canvas.drawRRect(rr(116, 178, 16, 10, 2), fillPaint(const Color(0xFF9d8be0)));
    canvas.drawRRect(rr(116, 178, 16, 10, 2), strokePaint(RoomPalette.outMid, 1));

    canvas.restore();

    // LAUNDRY pill near base (world coords).
    paintPillBadge(
      canvas,
      cx: 310,
      cy: 582,
      width: 64,
      fillColor: RoomPalette.pink,
      strokeColor: RoomPalette.outDark,
      textColor: const Color(0xFF3a1030),
      label: 'LAUNDRY',
    );
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
  bool shouldRepaint(_BathroomPainter old) =>
      old.daytime != daytime ||
      old.tapCueAngle != tapCueAngle ||
      old.messy != messy ||
      old.skins != skins;
}
