// Small red quest-count badge with a downward tail. Used to overlay
// pending-quest counts on top of category furniture in the room scenes
// (bedroom desk for admin, bedroom bed for bedroom quests, bathroom
// toilet for bathroom quests, washer for laundry). The living-room scene
// draws its own badges via CustomPaint — this widget is for the rooms
// that don't have an integrated badge in their painter.

import 'package:flutter/material.dart';

class QuestCountBadge extends StatelessWidget {
  final int count;
  const QuestCountBadge({super.key, required this.count});

  static const _red = Color(0xFFFF5E6C);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 8),
          painter: _BadgeTailPainter(),
        ),
      ],
    );
  }
}

class _BadgeTailPainter extends CustomPainter {
  static const _red = Color(0xFFFF5E6C);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _red;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.7, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
