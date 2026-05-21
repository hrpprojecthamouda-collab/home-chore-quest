// Run with: flutter test test/generate_icon_test.dart
// Outputs:  assets/icon/icon.png  (1024×1024)
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate app icon', () async {
    const s = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, s, s));

    _paint(canvas, s);

    final picture = recorder.endRecording();
    final image   = await picture.toImage(s.toInt(), s.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = Directory('assets/icon');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('assets/icon/icon.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('\n✅  Icon saved → ${file.absolute.path}\n');
  });
}

// ─── Painter ─────────────────────────────────────────────────────────────────

void _paint(ui.Canvas c, double s) {
  _bg(c, s);
  _sparkles(c, s);
  _body(c, s);
  _belly(c, s);
  _eyes(c, s);
  _cheeks(c, s);
  _mouth(c, s);
  _starBadge(c, s);
}

ui.Paint _fill(ui.Color col) => ui.Paint()..color = col;

ui.Paint _stroke(ui.Color col, double w) => ui.Paint()
  ..color = col
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = ui.StrokeCap.round
  ..strokeJoin = ui.StrokeJoin.round;

// Background — deep violet radial gradient
void _bg(ui.Canvas c, double s) {
  c.drawRect(
    ui.Rect.fromLTWH(0, 0, s, s),
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.50, s * 0.38),
        s * 0.80,
        const [ui.Color(0xFF5B3DD0), ui.Color(0xFF1A0F3D)],
      ),
  );
  // soft inner glow behind Pip
  c.drawCircle(
    ui.Offset(s * 0.50, s * 0.50),
    s * 0.36,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.50, s * 0.50),
        s * 0.36,
        [const ui.Color(0x4D9D5CFF), const ui.Color(0x009D5CFF)],
      ),
  );
}

// Tiny background stars
void _sparkles(ui.Canvas c, double s) {
  final p = _fill(const ui.Color(0x99FFFFFF));
  for (final (x, y, r) in [
    (0.13, 0.10, 4.5), (0.84, 0.08, 3.5), (0.91, 0.29, 3.0),
    (0.07, 0.36, 3.5), (0.20, 0.82, 2.5), (0.81, 0.77, 3.5),
    (0.69, 0.13, 2.5), (0.33, 0.87, 2.5), (0.55, 0.92, 2.0),
  ]) {
    c.drawCircle(ui.Offset(s * x, s * y), r, p);
  }
}

// Pip's rounded-square body
void _body(ui.Canvas c, double s) {
  final rect = ui.Rect.fromLTWH(s * 0.195, s * 0.305, s * 0.610, s * 0.558);
  final rr   = ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(s * 0.130));

  c.drawRRect(
    rr,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.355, s * 0.415),
        s * 0.46,
        const [ui.Color(0xFFC98AFF), ui.Color(0xFF9D5CFF), ui.Color(0xFF5B2EB5)],
        [0.0, 0.55, 1.0],
      ),
  );
  c.drawRRect(rr, _stroke(const ui.Color(0xFF1A1030), s * 0.016));
}

// Belly highlight
void _belly(ui.Canvas c, double s) {
  c.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(s * 0.315, s * 0.498, s * 0.370, s * 0.272),
      ui.Radius.circular(s * 0.078),
    ),
    _fill(const ui.Color(0x55C98AFF)),
  );
}

// Eyes: white → pupil → shine
void _eyes(ui.Canvas c, double s) {
  const lx = 0.361;
  const rx = 0.639;
  const ey = 0.466;

  // whites
  c.drawCircle(ui.Offset(s * lx, s * ey), s * 0.066, _fill(ui.Color(0xFFFFFFFF)));
  c.drawCircle(ui.Offset(s * rx, s * ey), s * 0.066, _fill(ui.Color(0xFFFFFFFF)));
  // pupils
  c.drawCircle(ui.Offset(s * (lx + 0.013), s * (ey + 0.018)), s * 0.033,
      _fill(const ui.Color(0xFF1A1030)));
  c.drawCircle(ui.Offset(s * (rx + 0.013), s * (ey + 0.018)), s * 0.033,
      _fill(const ui.Color(0xFF1A1030)));
  // shines
  c.drawCircle(ui.Offset(s * (lx + 0.026), s * (ey - 0.010)), s * 0.012,
      _fill(ui.Color(0xFFFFFFFF)));
  c.drawCircle(ui.Offset(s * (rx + 0.026), s * (ey - 0.010)), s * 0.012,
      _fill(ui.Color(0xFFFFFFFF)));
}

// Pink cheeks
void _cheeks(ui.Canvas c, double s) {
  final p = _fill(const ui.Color(0xA6FF4D8D));
  c.drawCircle(ui.Offset(s * 0.268, s * 0.559), s * 0.048, p);
  c.drawCircle(ui.Offset(s * 0.732, s * 0.559), s * 0.048, p);
}

// Smile
void _mouth(ui.Canvas c, double s) {
  final path = ui.Path()
    ..moveTo(s * 0.410, s * 0.624)
    ..quadraticBezierTo(s * 0.500, s * 0.706, s * 0.590, s * 0.624);
  c.drawPath(path, _stroke(const ui.Color(0xFF1A1030), s * 0.022));
}

// Gold star badge — top-right
void _starBadge(ui.Canvas c, double s) {
  final cx = s * 0.805;
  final cy = s * 0.195;
  final r  = s * 0.108;

  // gold disc
  c.drawCircle(
    ui.Offset(cx, cy),
    r,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(cx - r * 0.22, cy - r * 0.22),
        r,
        const [ui.Color(0xFFFFE970), ui.Color(0xFFFFD23F)],
      ),
  );
  c.drawCircle(ui.Offset(cx, cy), r, _stroke(const ui.Color(0xFF5A3800), s * 0.008));

  // 5-pointed star inside disc
  _star5(c, cx, cy, r * 0.60, r * 0.25, _fill(const ui.Color(0x885A3800)));
}

void _star5(ui.Canvas c, double cx, double cy, double outerR, double innerR, ui.Paint p) {
  final path = ui.Path();
  for (var i = 0; i < 5; i++) {
    final ao = i * 2 * math.pi / 5 - math.pi / 2;
    final ai = ao + math.pi / 5;
    final op = ui.Offset(cx + outerR * math.cos(ao), cy + outerR * math.sin(ao));
    final ip = ui.Offset(cx + innerR * math.cos(ai), cy + innerR * math.sin(ai));
    if (i == 0) {
      path.moveTo(op.dx, op.dy);
    } else {
      path.lineTo(op.dx, op.dy);
    }
    path.lineTo(ip.dx, ip.dy);
  }
  path.close();
  c.drawPath(path, p);
}
