import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_providers.dart';
import 'providers/game_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/pip_mascot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GamifiedApp(),
    ),
  );
}

class GamifiedApp extends ConsumerWidget {
  const GamifiedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Chore Quest',
      theme: AppTheme.theme,
      home: LaunchCinematicGate(authState: authState),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}

class LaunchCinematicGate extends StatefulWidget {
  const LaunchCinematicGate({super.key, required this.authState});

  final AsyncValue<dynamic> authState;

  @override
  State<LaunchCinematicGate> createState() => _LaunchCinematicGateState();
}

class _LaunchCinematicGateState extends State<LaunchCinematicGate> {
  bool _minDone = false;

  @override
  void initState() {
    super.initState();
    // 2.5 s minimum — enough for one full Pip breathing cycle + title read.
    // We also wait for Firebase auth to resolve, so the real gate is
    // max(2500 ms, auth_init_time). No extra delay if auth takes longer.
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      setState(() => _minDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authReady = !widget.authState.isLoading;

    if (!_minDone || !authReady) {
      return const _SplashScreen();
    }

    return widget.authState.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}

// ─── Direction B Splash Screen ────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _dotsCtrl;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.35),
            radius: 1.1,
            colors: [AppColors.violet, AppColors.bgDeep],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _StarFieldPainter()),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pip floats gently up and down
                  AnimatedBuilder(
                    animation: _breath,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _breath.value * -6),
                      child: const PipMascot(size: 120),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Home Chore Quest',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x66000000), offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your cozy adventure awaits ✨',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Three-dot wave loader
                  AnimatedBuilder(
                    animation: _dotsCtrl,
                    builder: (_, __) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final phase = (_dotsCtrl.value + i / 3) % 1.0;
                          final scale = 0.5 + 0.5 * math.sin(phase * math.pi);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.pink,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  // Positions as fractions of screen width/height, radius in logical px
  static const _stars = [
    (x: 0.08, y: 0.06, r: 1.2), (x: 0.22, y: 0.14, r: 0.8),
    (x: 0.78, y: 0.08, r: 1.4), (x: 0.91, y: 0.18, r: 0.9),
    (x: 0.15, y: 0.32, r: 1.0), (x: 0.85, y: 0.27, r: 1.1),
    (x: 0.05, y: 0.52, r: 0.7), (x: 0.95, y: 0.44, r: 0.8),
    (x: 0.12, y: 0.72, r: 1.3), (x: 0.88, y: 0.68, r: 0.6),
    (x: 0.30, y: 0.88, r: 1.0), (x: 0.70, y: 0.92, r: 0.9),
    (x: 0.50, y: 0.04, r: 1.5), (x: 0.42, y: 0.19, r: 0.7),
    (x: 0.60, y: 0.22, r: 0.8), (x: 0.25, y: 0.60, r: 0.6),
    (x: 0.75, y: 0.55, r: 1.1), (x: 0.35, y: 0.78, r: 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(.5);
    for (final s in _stars) {
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
