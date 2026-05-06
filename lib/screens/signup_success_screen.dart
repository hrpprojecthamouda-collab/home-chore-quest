import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/pip_mascot.dart';
import 'home_screen.dart';

class SignupSuccessScreen extends StatefulWidget {
  const SignupSuccessScreen({super.key});

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _panelCtrl;
  int _phase = 0; // 0=check, 1=pip+confetti, 2=bar, 3=panel

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _panelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _phase = 1);
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _phase = 2);
      _barCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() => _phase = 3);
      _panelCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 3400), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (r) => false,
    );
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _barCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.3),
            radius: 1.1,
            colors: [AppColors.violet, AppColors.bgDeep],
          ),
        ),
        child: Stack(
          children: [
            // Confetti layer
            if (_phase >= 1)
              const Positioned.fill(child: _ConfettiLayer()),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Green checkmark burst
                  AnimatedBuilder(
                    animation: _checkCtrl,
                    builder: (_, __) {
                      final t = CurvedAnimation(
                        parent: _checkCtrl,
                        curve: Curves.elasticOut,
                      ).value;
                      return Transform.scale(
                        scale: t,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Pip waving
                  AnimatedOpacity(
                    opacity: _phase >= 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSlide(
                      offset: _phase >= 1 ? Offset.zero : const Offset(0, 0.3),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: const PipMascot(size: 100, wave: true),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _phase >= 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      "You're in, hero!",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Loading bar
                  if (_phase >= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _barCtrl,
                            builder: (_, __) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: CurvedAnimation(
                                    parent: _barCtrl,
                                    curve: Curves.easeInOut,
                                  ).value,
                                  minHeight: 8,
                                  backgroundColor: AppColors.surface2,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Setting up your room…',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // "Logging you in" panel slides up from bottom
            AnimatedBuilder(
              animation: _panelCtrl,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: _panelCtrl,
                  curve: Curves.easeOut,
                ).value;
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x669D5CFF), blurRadius: 40, offset: Offset(0, -8)),
                        ],
                      ),
                      child: Text(
                        'Logging you in… ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer();

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static final _rng = math.Random(42);
  static final _dots = List.generate(14, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble() * 0.5,
    color: [
      AppColors.pink, AppColors.cyan, AppColors.yellow,
      AppColors.green, AppColors.violet,
    ][i % 5],
    size: 5.0 + _rng.nextDouble() * 5,
    vx: (_rng.nextDouble() - 0.5) * 0.3,
    vy: 0.1 + _rng.nextDouble() * 0.2,
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_ctrl.value, _dots),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<({double x, double y, Color color, double size, double vx, double vy})> dots;

  const _ConfettiPainter(this.t, this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final px = (d.x + d.vx * t) % 1.0;
      final py = (d.y + d.vy * t) % 1.0;
      canvas.drawCircle(
        Offset(px * size.width, py * size.height),
        d.size,
        Paint()..color = d.color.withOpacity(0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
