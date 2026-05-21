// Shared room-shell primitives reused by every room scene in the apartment.
//
// The shell is the painted backdrop common to all rooms — dark-violet wall,
// soft wall vignette, warm-wood floor with plank seams and scuffs, and a
// window panel that switches between day and night skies. Match
// `flat-room-scene.jsx` / `HANDOFF_ROOMS.md` from the design bundle
// (400 × 600 canvas, all coordinates in design space).
//
// Each room defines its own furniture on top of the shell.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Canvas constants (design space) ──────────────────────────────
const double kRoomCanvasW = 400;
const double kRoomCanvasH = 600;

// ── Shared palette (matches RC in three-rooms-scene.jsx) ─────────
class RoomPalette {
  static const wall    = Color(0xFF1A1030);
  static const wallHi  = Color(0xFF2a1a52);
  static const wallLo  = Color(0xFF120824);
  static const floor   = Color(0xFF3B2418);
  static const floorHi = Color(0xFF5a3520);
  static const seam    = Color(0xFF1f120a);
  static const outDark = Color(0xFF1a1238);
  static const outMid  = Color(0xFF3a2a6a);
  static const outWarm = Color(0xFF3a2010);

  // Category accents
  static const teal   = Color(0xFF3edcff); // cleaning (living) + bathroom
  static const amber  = Color(0xFFffb347); // admin
  static const blue   = Color(0xFF7ab8ff); // kitchen
  static const pink   = Color(0xFFd9a8ff); // laundry
  static const violet = Color(0xFFc98aff); // bedroom
}

// ── Paint helpers ────────────────────────────────────────────────
Paint fillPaint(Color c) => Paint()..color = c;

Paint strokePaint(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

RRect rr(double x, double y, double w, double h, double r) =>
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

// ── Shell: wall · baseboard · floor · seams · scuffs · vignettes ─
void paintRoomShell(Canvas canvas) {
  // Wall (top 380 px) with radial purple vignette.
  canvas.drawRect(const Rect.fromLTWH(0, 0, kRoomCanvasW, 380), fillPaint(RoomPalette.wall));
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, kRoomCanvasW, 380),
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, 0.1),
        radius: 0.78,
        colors: [Color(0x6B2a1a52), Color(0xE00a0418)],
      ).createShader(const Rect.fromLTWH(0, 0, kRoomCanvasW, 380)),
  );

  // Baseboard at the wall/floor seam.
  canvas.drawRect(const Rect.fromLTWH(0, 376, kRoomCanvasW, 3), fillPaint(RoomPalette.wallLo));
  canvas.drawRect(
    const Rect.fromLTWH(0, 379, kRoomCanvasW, 2),
    fillPaint(RoomPalette.wallHi.withValues(alpha: 0.5)),
  );

  // Floor.
  canvas.drawRect(const Rect.fromLTWH(0, 381, kRoomCanvasW, kRoomCanvasH - 381), fillPaint(RoomPalette.floor));

  // Plank seams (9 verticals).
  for (int i = 0; i < 9; i++) {
    canvas.drawRect(
      Rect.fromLTWH(i * 50.0, 381, 1.2, kRoomCanvasH - 381),
      fillPaint(RoomPalette.seam.withValues(alpha: 0.7)),
    );
  }

  // Horizontal scuff lines.
  for (int i = 0; i < 5; i++) {
    canvas.drawRect(
      Rect.fromLTWH(0, 420 + i * 38.0, kRoomCanvasW, 1),
      fillPaint(RoomPalette.floorHi.withValues(alpha: 0.18)),
    );
  }

  // Floor sheen — vertical warm gradient.
  canvas.drawRect(
    const Rect.fromLTWH(0, 381, kRoomCanvasW, kRoomCanvasH - 381),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x005a3520), Color(0x517a4a2a), Color(0x991a0e08)],
        stops: [0, 0.35, 1],
      ).createShader(const Rect.fromLTWH(0, 381, kRoomCanvasW, kRoomCanvasH - 381)),
  );

  // Ambient wall twinkles.
  final twinkle = fillPaint(Colors.white.withValues(alpha: 0.32));
  for (final p in const [(40.0, 60.0, 1.0), (180.0, 40.0, 1.2), (370.0, 90.0, 1.0), (220.0, 110.0, 0.9)]) {
    canvas.drawCircle(Offset(p.$1, p.$2), p.$3, twinkle);
  }

  // Top mood vignette removed — it cast a visible shade across the
  // quest board / TV after the canvas was scaled taller.
}

// ── Window panel ─────────────────────────────────────────────────
// Designed to be re-used by every room. Coordinates are in design space;
// pass top-left (x, y) of the glass and its size. `daytime` toggles the
// sun/stars/sky gradient.
void paintWindow(
  Canvas canvas, {
  required double x,
  required double y,
  required double w,
  required double h,
  required bool daytime,
}) {
  canvas.save();
  canvas.translate(x, y);

  // Outer warm frame.
  canvas.drawRRect(rr(-4, -4, w + 8, h + 8, 6), fillPaint(const Color(0xFF3a230f)));
  canvas.drawRRect(rr(-4, -4, w + 8, h + 8, 6), strokePaint(RoomPalette.outWarm, 1.6));

  // Sill.
  canvas.drawRRect(rr(-10, h, w + 20, 8, 2), fillPaint(const Color(0xFF5a3a1d)));
  canvas.drawRRect(rr(-10, h, w + 20, 8, 2), strokePaint(RoomPalette.outWarm, 1.6));

  // Sky gradient.
  final skyRect = Rect.fromLTWH(0, 0, w, h);
  canvas.drawRect(
    skyRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: daytime
            ? const [Color(0xFF6dc3ff), Color(0xFF3edcff), Color(0xFF2a1f4a)]
            : const [Color(0xFF0d1230), Color(0xFF2a2378), Color(0xFF5a3a8a)],
        stops: const [0, 0.55, 1],
      ).createShader(skyRect),
  );

  if (daytime) {
    // Sun.
    canvas.drawCircle(Offset(w - 32, h * 0.32), 16, fillPaint(const Color(0xFFffe66d)));
    canvas.drawCircle(Offset(w - 32, h * 0.32), 11, fillPaint(const Color(0xFFfffbe6)));
  } else {
    // Moon (crescent).
    canvas.drawCircle(Offset(w - 36, h * 0.28), 14, fillPaint(const Color(0xFFfef3c7).withValues(alpha: 0.95)));
    canvas.drawCircle(Offset(w - 40, h * 0.25), 11, fillPaint(const Color(0xFFfffbe6)));
    canvas.drawCircle(Offset(w - 44, h * 0.22), 2.5, fillPaint(const Color(0xFFe8d49a).withValues(alpha: 0.7)));
    // Stars.
    final star = fillPaint(Colors.white);
    for (final s in [
      (w * 0.14, h * 0.16, 1.2),
      (w * 0.28, h * 0.10, 0.9),
      (w * 0.44, h * 0.28, 1.0),
      (w * 0.20, h * 0.42, 0.9),
      (w * 0.55, h * 0.14, 1.1),
      (w * 0.88, h * 0.52, 0.9),
    ]) {
      canvas.drawCircle(Offset(s.$1, s.$2), s.$3, star);
    }
  }

  // Rolling hills (two stacked silhouettes).
  final hill1 = Path()
    ..moveTo(0, h * 0.8)
    ..quadraticBezierTo(w * 0.17, h * 0.7, w * 0.34, h * 0.77)
    ..quadraticBezierTo(w * 0.51, h * 0.83, w * 0.68, h * 0.72)
    ..quadraticBezierTo(w * 0.85, h * 0.62, w, h * 0.75)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(hill1, fillPaint(const Color(0xFF1a1238).withValues(alpha: 0.85)));
  final hill2 = Path()
    ..moveTo(0, h * 0.87)
    ..quadraticBezierTo(w * 0.21, h * 0.78, w * 0.43, h * 0.83)
    ..quadraticBezierTo(w * 0.64, h * 0.9, w * 0.86, h * 0.8)
    ..lineTo(w, h * 0.82)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(hill2, fillPaint(const Color(0xFF0d0820).withValues(alpha: 0.85)));

  // Mullions (cross-bars).
  canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), strokePaint(const Color(0xFF3a230f), 3));
  canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), strokePaint(const Color(0xFF3a230f), 3));

  // Glass glint.
  final glint = Path()..moveTo(6, 6)..lineTo(28, 6)..lineTo(6, 30)..close();
  canvas.drawPath(glint, fillPaint(Colors.white.withValues(alpha: 0.08)));

  canvas.restore();
}

// ── Rotating dashed tap-cue ring ────────────────────────────────
void paintTapCueRing(
  Canvas canvas, {
  required double cx,
  required double cy,
  required double r,
  required Color color,
  required double angle,
}) {
  final paint = Paint()
    ..color = color.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  const sweep = 20.0 * math.pi / 180.0;
  const step  = 45.0 * math.pi / 180.0;
  for (int i = 0; i < 8; i++) {
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      angle + i * step,
      sweep,
      false,
      paint,
    );
  }
  final bx = cx + r * math.cos(angle);
  final by = cy + r * math.sin(angle);
  canvas.drawCircle(Offset(bx, by), 3.0, fillPaint(Colors.white.withValues(alpha: 0.9)));
  canvas.drawCircle(Offset(bx, by), 1.5, fillPaint(color));
}

// ── Pill badge with a category label, drawn next to a furniture piece ─
void paintPillBadge(
  Canvas canvas, {
  required double cx,
  required double cy,
  required double width,
  required Color fillColor,
  required Color strokeColor,
  required Color textColor,
  required String label,
}) {
  const height = 18.0;
  final r = Rect.fromCenter(center: Offset(cx, cy), width: width, height: height);
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), fillPaint(fillColor));
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), strokePaint(strokeColor, 1.2));
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: textColor,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
}

// ── Villain (the messy-room presence) ────────────────────────────
//
// Split-personality face — white/angelic half on the left, black/evil half on
// the right — that peeks into the apartment whenever the home is messy. The
// living-room window paints him in full (he peeks above the hills there);
// the bedroom and bathroom windows show one half each so it feels like he's
// "around" — present, but not staring head-on.

enum VillainSide { full, leftHalf, rightHalf }

/// Paints the villain at the current canvas origin, scaled by [scale].
///
/// Origin = the BOTTOM-CENTRE of the face (so the chin sits at y=0 and the
/// head + horns extend upward and outward). This matches the existing home
/// scene placement where the hills clip the chin off.
///
/// [side] selects which half (or all) is rendered. Use a clipRect outside
/// this call to shape the peek silhouette (e.g. clip to the window glass).
void paintVillain(
  Canvas canvas, {
  required VillainSide side,
  double scale = 1.0,
}) {
  canvas.save();
  if (scale != 1.0) canvas.scale(scale, scale);

  const headW = 46.0;
  const headH = 36.0;
  final headRect = Rect.fromCenter(center: const Offset(0, -10), width: headW, height: headH);
  final isLeft  = side == VillainSide.leftHalf  || side == VillainSide.full;
  final isRight = side == VillainSide.rightHalf || side == VillainSide.full;

  // Soft red dread halo around the whole head (only when the evil side is
  // showing — the angelic half doesn't get a red glow).
  if (isRight) {
    const red = Color(0xFFFF5E6C);
    canvas.drawOval(
      headRect.inflate(8),
      Paint()
        ..shader = RadialGradient(
          colors: [red.withValues(alpha: 0.45), red.withValues(alpha: 0)],
        ).createShader(headRect.inflate(8)),
    );
  }

  // Horns.
  if (isLeft) {
    final hornGood = Path()..moveTo(-15, -22)..lineTo(-19, -36)..lineTo(-9, -22)..close();
    canvas.drawPath(hornGood, fillPaint(const Color(0xFFf5f5f5)));
    canvas.drawPath(hornGood, strokePaint(const Color(0xFFb0b0b0), 1.2));
  }
  if (isRight) {
    final hornEvil = Path()
      ..moveTo(15, -22)
      ..quadraticBezierTo(26, -32, 19, -38)
      ..quadraticBezierTo(20, -28, 9, -22)
      ..close();
    canvas.drawPath(hornEvil, fillPaint(const Color(0xFF050505)));
    canvas.drawPath(hornEvil, strokePaint(const Color(0xFF3a3a3a), 1.2));
  }

  // Head halves.
  if (isLeft) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(headRect.left - 2, headRect.top - 2, 0, headRect.bottom + 2));
    canvas.drawOval(headRect, fillPaint(const Color(0xFFf2f2f2)));
    canvas.restore();
  }
  if (isRight) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, headRect.top - 2, headRect.right + 2, headRect.bottom + 2));
    canvas.drawOval(headRect, fillPaint(const Color(0xFF0a0a0a)));
    canvas.restore();
  }

  // Outline + central seam — only when the full face shows.
  if (side == VillainSide.full) {
    canvas.drawOval(headRect, strokePaint(const Color(0xFF6a6a6a), 1.4));
    canvas.drawLine(
      Offset(0, headRect.top + 2),
      Offset(0, headRect.bottom - 2),
      strokePaint(const Color(0xFF7a7a7a), 1.0),
    );
  } else {
    // For half-views, give the visible half its own outer outline.
    canvas.save();
    if (isLeft) {
      canvas.clipRect(Rect.fromLTRB(headRect.left - 2, headRect.top - 2, 0, headRect.bottom + 2));
      canvas.drawOval(headRect, strokePaint(const Color(0xFF6a6a6a), 1.4));
    } else {
      canvas.clipRect(Rect.fromLTRB(0, headRect.top - 2, headRect.right + 2, headRect.bottom + 2));
      canvas.drawOval(headRect, strokePaint(const Color(0xFF6a6a6a), 1.4));
    }
    canvas.restore();
  }

  // Eyes.
  if (isLeft) {
    canvas.drawCircle(const Offset(-11, -12), 3.6, fillPaint(Colors.white));
    canvas.drawCircle(const Offset(-11, -12), 3.6, strokePaint(const Color(0xFF333333), 0.8));
    canvas.drawCircle(const Offset(-11, -12), 1.6, fillPaint(const Color(0xFF2a6dd1)));
    canvas.drawCircle(const Offset(-10.4, -12.4), 0.7, fillPaint(Colors.white));
  }
  if (isRight) {
    canvas.drawCircle(const Offset(11, -12), 5.5, fillPaint(const Color(0x66ff1111)));
    canvas.drawCircle(const Offset(11, -12), 3.4, fillPaint(const Color(0xFFff2a2a)));
    canvas.drawCircle(const Offset(11, -12), 1.4, fillPaint(Colors.white));
  }

  // Mouth halves.
  if (isLeft) {
    final smile = Path()..moveTo(-13, -2)..quadraticBezierTo(-7, 2, -1, -2);
    canvas.drawPath(smile, strokePaint(const Color(0xFF333333), 1.3));
  }
  if (isRight) {
    final grin = Path()..moveTo(1, -2)..quadraticBezierTo(7, 4, 13, -2);
    canvas.drawPath(grin, strokePaint(const Color(0xFFff2a2a), 1.6));
    canvas.drawPath(Path()..moveTo(4, -1)..lineTo(5.2, 4)..lineTo(7, -1)..close(),
        fillPaint(Colors.white));
    canvas.drawPath(Path()..moveTo(9, -1)..lineTo(10.2, 4)..lineTo(12, -1)..close(),
        fillPaint(Colors.white));
  }

  canvas.restore();
}
