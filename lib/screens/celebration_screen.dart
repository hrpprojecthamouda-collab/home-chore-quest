import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pip_mascot.dart';
import '../widgets/puffy_button.dart';

class CelebrationScreen extends ConsumerWidget {
  final int level;

  const CelebrationScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.4),
            radius: 1.2,
            colors: [AppColors.violet, AppColors.bgDeep],
          ),
        ),
        child: Stack(
          children: [
            // Sun rays
            const _SunRays(),
            // Confetti
            const _ConfettiLayer(),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PipMascot(size: 140, hat: true),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3))],
                      ),
                      child: Text(
                        'LEVEL UP!',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.bgDeep,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [Shadow(color: Color(0x66000000), offset: Offset(0, 4))],
                        ),
                        children: [
                          const TextSpan(text: "You're "),
                          TextSpan(
                            text: 'LV $level',
                            style: const TextStyle(color: AppColors.yellow),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quest accepted, brave adventurer!\nPip is so proud 💜',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Unlocked reward card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4)),
                          BoxShadow(
                            color: Color(0x1AFFFFFF),
                            offset: Offset(0, 1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.yellow, AppColors.pink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Color(0x33FFFFFF), offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Center(child: Text('🪙', style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+50 Coins',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Level-up bonus — spend in the shop!',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Chip(label: '+20 XP', color: AppColors.yellow, dark: true),
                        const SizedBox(width: 8),
                        _Chip(label: '🔥 Streak bonus', color: AppColors.pink),
                      ],
                    ),
                    const SizedBox(height: 28),
                    PuffyButton(
                      label: 'Awesome!',
                      color: AppColors.pink,
                      onTap: () {
                        ref.read(soundServiceProvider).playSound(SoundType.awesome);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;

  const _Chip({required this.label, required this.color, this.dark = false});

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0, 1)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: _darken(color, .2), offset: const Offset(0, 2))],
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: dark ? AppColors.bgDeep : Colors.white,
        ),
      ),
    );
  }
}

class _SunRays extends StatelessWidget {
  const _SunRays();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: .45,
        child: CustomPaint(painter: _SunRaysPainter()),
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * .35;
    final paint = Paint()
      ..color = const Color(0xFFFFD23F)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x1 = cx + 60 * math.cos(angle);
      final y1 = cy + 60 * math.sin(angle);
      final x2 = cx + 160 * math.cos(angle);
      final y2 = cy + 160 * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  static const _pieces = [
    (x: 30.0, y: 60.0, c: AppColors.pink, r: 8.0, rot: 12.0, circle: false),
    (x: 320.0, y: 80.0, c: AppColors.cyan, r: 6.0, rot: -15.0, circle: true),
    (x: 60.0, y: 180.0, c: AppColors.yellow, r: 7.0, rot: 30.0, circle: false),
    (x: 280.0, y: 220.0, c: AppColors.green, r: 5.0, rot: -25.0, circle: true),
    (x: 100.0, y: 280.0, c: AppColors.pink, r: 6.0, rot: 18.0, circle: false),
    (x: 340.0, y: 380.0, c: AppColors.violet, r: 8.0, rot: -10.0, circle: true),
    (x: 40.0, y: 420.0, c: AppColors.cyan, r: 5.0, rot: 22.0, circle: false),
    (x: 360.0, y: 140.0, c: AppColors.yellow, r: 6.0, rot: -5.0, circle: false),
    (x: 20.0, y: 320.0, c: AppColors.green, r: 4.0, rot: 40.0, circle: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _ConfettiPainter(pieces: _pieces)),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<({double x, double y, Color c, double r, double rot, bool circle})> pieces;

  _ConfettiPainter({required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      if (p.x > size.width || p.y > size.height) continue;
      final paint = Paint()
        ..color = p.c.withOpacity(.85)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot * 3.14159 / 180);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.r, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.r * 2, height: p.r * 2),
            const Radius.circular(4),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
