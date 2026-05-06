import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pip_mascot.dart';
import 'login_screen.dart';

class LogoutScreen extends ConsumerStatefulWidget {
  const LogoutScreen({super.key});

  @override
  ConsumerState<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends ConsumerState<LogoutScreen>
    with TickerProviderStateMixin {
  late final AnimationController _skyCtrl;
  late final AnimationController _starsCtrl;
  bool _sleeping = false;

  @override
  void initState() {
    super.initState();
    _skyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();

    _starsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _starsCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _sleeping = true);
    });
    Future.delayed(const Duration(milliseconds: 3200), _autoLogout);
  }

  @override
  void dispose() {
    _skyCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoLogout() async {
    if (!mounted) return;
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(authStateProvider).value?.displayName ?? 'Hero';

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_skyCtrl, _starsCtrl]),
        builder: (_, __) {
          final skyT   = CurvedAnimation(parent: _skyCtrl, curve: Curves.easeIn).value;
          final starsT = CurvedAnimation(parent: _starsCtrl, curve: Curves.easeOut).value;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(AppColors.surface2, AppColors.bgDeep, skyT)!,
                  AppColors.bgDeep,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Stars
                ...List.generate(6, (i) {
                  final delay = i / 6;
                  final opacity = ((starsT - delay) / (1 - delay)).clamp(0.0, 1.0);
                  return Positioned(
                    left: [0.1, 0.8, 0.25, 0.7, 0.45, 0.9][i] * MediaQuery.of(context).size.width,
                    top:  [0.08, 0.12, 0.22, 0.18, 0.06, 0.28][i] * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: opacity,
                      child: const Icon(Icons.star, color: AppColors.yellow, size: 14),
                    ),
                  );
                }),

                // Crescent moon
                Positioned(
                  top: 60,
                  right: 48,
                  child: Opacity(
                    opacity: starsT,
                    child: const _CrescentMoon(),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pip
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: _sleeping
                            ? const PipMascot(key: ValueKey('sleep'), size: 110, mood: 'sleep')
                            : const PipMascot(key: ValueKey('wave'), size: 110, wave: true),
                      ),
                      const SizedBox(height: 22),

                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _sleeping ? 'See you soon!' : 'Bye, $userName!',
                          key: ValueKey(_sleeping),
                          style: GoogleFonts.nunito(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _sleeping
                              ? 'Pip will guard the room 🌙'
                              : 'Logging you out…',
                          key: ValueKey(_sleeping),
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ),

                      // Floating Z's when sleeping
                      if (_sleeping) ...[
                        const SizedBox(height: 12),
                        const _FloatingZs(),
                      ],
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}

class _CrescentMoon extends StatelessWidget {
  const _CrescentMoon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(painter: _MoonPainter()),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.yellow;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.35),
      size.width * 0.38,
      Paint()..color = AppColors.bgDeep,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FloatingZs extends StatefulWidget {
  const _FloatingZs();

  @override
  State<_FloatingZs> createState() => _FloatingZsState();
}

class _FloatingZsState extends State<_FloatingZs> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
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
      builder: (_, __) {
        return SizedBox(
          width: 80,
          height: 48,
          child: Stack(
            children: [
              _zBubble(_ctrl.value, 0, 14.0, 20, 28),
              _zBubble((_ctrl.value + 0.33) % 1.0, 0.33, 18.0, 42, 10),
              _zBubble((_ctrl.value + 0.66) % 1.0, 0.66, 12.0, 60, 24),
            ],
          ),
        );
      },
    );
  }

  Widget _zBubble(double t, double offset, double size, double x, double y) {
    final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
    final dy = -t * 20;
    return Positioned(
      left: x,
      top: y + dy,
      child: Opacity(
        opacity: opacity,
        child: Text(
          'z',
          style: GoogleFonts.nunito(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
