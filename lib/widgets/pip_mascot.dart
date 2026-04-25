import 'package:flutter/material.dart';

class PipMascot extends StatelessWidget {
  final double size;
  final bool hat;

  const PipMascot({super.key, this.size = 80, this.hat = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PipPainter(hat: hat)),
    );
  }
}

class _PipPainter extends CustomPainter {
  final bool hat;
  const _PipPainter({required this.hat});

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

    // Body gradient
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .5, h * .60), width: w * .72, height: h * .68),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.2, -.3),
          radius: .7,
          colors: const [Color(0xFFC98AFF), Color(0xFF9D5CFF), Color(0xFF5B2EB5)],
          stops: const [.0, .6, 1.0],
        ).createShader(Rect.fromLTWH(w * .14, h * .26, w * .72, h * .68)),
    );

    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .5, h * .68), width: w * .44, height: h * .36),
      _fill(const Color(0xFFC98AFF).withOpacity(.45)),
    );

    // Eyes white
    canvas.drawCircle(Offset(w * .38, h * .52), w * .06, _fill(Colors.white));
    canvas.drawCircle(Offset(w * .62, h * .52), w * .06, _fill(Colors.white));

    // Pupils
    canvas.drawCircle(Offset(w * .39, h * .53), w * .03, _fill(const Color(0xFF1A1030)));
    canvas.drawCircle(Offset(w * .63, h * .53), w * .03, _fill(const Color(0xFF1A1030)));

    // Eye shine
    canvas.drawCircle(Offset(w * .40, h * .515), w * .01, _fill(Colors.white));
    canvas.drawCircle(Offset(w * .64, h * .515), w * .01, _fill(Colors.white));

    // Cheeks
    canvas.drawCircle(Offset(w * .32, h * .64), w * .04, _fill(const Color(0xFFFF4D8D).withOpacity(.65)));
    canvas.drawCircle(Offset(w * .68, h * .64), w * .04, _fill(const Color(0xFFFF4D8D).withOpacity(.65)));

    // Mouth
    final mouth = Path()
      ..moveTo(w * .44, h * .66)
      ..quadraticBezierTo(w * .5, h * .72, w * .56, h * .66);
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
  bool shouldRepaint(_PipPainter old) => old.hat != hat;
}
