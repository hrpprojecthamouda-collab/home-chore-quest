import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pip_mascot.dart';
import '../widgets/puffy_button.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  /// True when shown right after signup — flips the headline + subtitle
  /// to greet a new player instead of welcoming a returning one.
  final bool isNew;

  const WelcomeBackScreen({super.key, this.isNew = false});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen>
    with TickerProviderStateMixin {
  late final AnimationController _doorCtrl;
  late final Animation<double> _doorAnim;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _doorAnim = CurvedAnimation(
      parent: _doorCtrl,
      curve: const Cubic(0.6, 0.1, 0.3, 1),
    );
    _startSequence();
    // Persist today's login once the welcome screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(loginStreakProvider.notifier).recordLogin();
    });
  }

  void _startSequence() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _phase = 1);
      _doorCtrl.forward();
    });
    for (final (ms, p) in [(900, 2), (1700, 3), (2400, 4), (3200, 5)]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) setState(() => _phase = p);
      });
    }
  }

  @override
  void dispose() {
    _doorCtrl.dispose();
    super.dispose();
  }

  void _claimAndEnter() {
    final streak = ref.read(loginStreakProvider);
    ref.read(xpProvider.notifier).addXp(_xpForDay(streak));
    ref.read(coinProvider.notifier).addCoins(_coinsForDay(streak));
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(authStateProvider).value?.displayName ?? 'Hero';
    final streak   = ref.watch(loginStreakProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface2, AppColors.bgDeep],
          ),
        ),
        child: Stack(
          children: [
            _buildDoor(),
            _buildPip(),
            if (_phase >= 3 && _phase < 5) _buildHeartPop(),
            if (_phase >= 3)
              Positioned.fill(
                child: IgnorePointer(child: _ConfettiLayer(phase: _phase)),
              ),
            _buildWelcomeText(userName),
            _buildStreakChip(streak),
            _buildRewardsCard(streak),
          ],
        ),
      ),
    );
  }

  Widget _buildDoor() {
    return Positioned(
      top: 90,
      left: 0, right: 0,
      child: Center(
        child: Container(
          width: 130,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
              bottom: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.violet, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withOpacity(.45),
                blurRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Inside glow
              AnimatedOpacity(
                opacity: _phase >= 1 ? 0.7 : 0,
                duration: const Duration(milliseconds: 800),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.2),
                      radius: 0.7,
                      colors: [AppColors.yellow, Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Door slab — perspective opening
              AnimatedBuilder(
                animation: _doorAnim,
                builder: (_, child) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003)
                    ..rotateY(-_doorAnim.value * 1.36),
                  child: child,
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFCC2E6E), AppColors.pink],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Top panel groove
                      Positioned(
                        top: 14, left: 14, right: 14, height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withOpacity(.2),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Bottom panel groove
                      Positioned(
                        bottom: 14, left: 14, right: 14, height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withOpacity(.2),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Knob
                      Positioned(
                        right: 10, top: 82,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPip() {
    return Positioned(
      top: 168,
      left: 0, right: 0,
      child: AnimatedOpacity(
        opacity: _phase >= 2 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: AnimatedScale(
            scale: _phase >= 3 ? 1.1 : _phase >= 2 ? 0.85 : 0.5,
            duration: const Duration(milliseconds: 700),
            curve: const Cubic(0.5, 1.7, 0.4, 1),
            child: PipMascot(
              size: 140,
              wave: _phase >= 2 && _phase < 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartPop() {
    return Positioned(
      top: 150,
      left: 0, right: 0,
      child: Center(
        child: AnimatedScale(
          scale: _phase >= 4 ? 1.4 : 0.4,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _phase >= 4 ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: const Text('💜', style: TextStyle(fontSize: 40)),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(String userName) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      top: _phase >= 3 ? 330 : 355,
      left: 0, right: 0,
      child: AnimatedOpacity(
        opacity: _phase >= 3 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isNew ? 'WELCOME' : 'WELCOME BACK',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$userName!  ',
                    style: GoogleFonts.nunito(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const TextSpan(text: '👋', style: TextStyle(fontSize: 26)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isNew
                  ? "Pip's been waiting to meet you ✨"
                  : 'Pip kept the room safe ✨',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakChip(int streak) {
    final label = streak <= 1 ? 'FIRST DAY!' : 'STREAK · $streak DAYS';
    return Positioned(
      top: 440,
      left: 0, right: 0,
      child: Center(
        child: AnimatedScale(
          scale: _phase >= 4 ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 500),
          curve: const Cubic(0.5, 1.8, 0.4, 1),
          child: AnimatedOpacity(
            opacity: _phase >= 4 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.yellow, AppColors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(color: AppColors.pink.withOpacity(.5), offset: const Offset(0, 5)),
                  BoxShadow(color: AppColors.yellow.withOpacity(.3), blurRadius: 20),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.bgDeep,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+${_xpForDay(streak)} XP · 🪙${_coinsForDay(streak)}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsCard(int streak) {
    final today  = math.max(1, streak);
    final start  = math.max(1, today - 1);
    final slots  = List.generate(5, (i) => start + i);
    final dayLbl = today == 1 ? 'First login reward!' : 'Day $today reward!';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: const Cubic(0.5, 1.6, 0.4, 1),
      bottom: _phase >= 5 ? 16 : -280,
      left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x669D5CFF), blurRadius: 30, offset: Offset(0, -10)),
            BoxShadow(color: Color(0x80000000), offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY REWARD',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayLbl,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'RESETS 24h',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: slots.map((d) {
                final isToday = d == today;
                final isPast  = d < today;
                final icon    = d % 7 == 0 ? '🎁' : d % 5 == 0 ? '⭐' : '💎';
                final xpLbl   = isPast || isToday ? '${_xpForDay(d)}' : '?';
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? const LinearGradient(
                              colors: [AppColors.yellow, AppColors.pink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isToday ? null : AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'D$d',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isToday ? AppColors.bgDeep : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(isPast ? '✅' : icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          xpLbl,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isToday ? AppColors.bgDeep : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            PuffyButton(
              label: 'CLAIM & ENTER ✓',
              color: AppColors.pink,
              onTap: _claimAndEnter,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  static int _xpForDay(int day) {
    const table = [10, 15, 20, 30, 40, 50, 65, 80, 100, 120];
    return table[math.min(math.max(day - 1, 0), table.length - 1)];
  }

  static int _coinsForDay(int day) {
    const table = [10, 12, 15, 20, 25, 30, 40, 50, 60, 80];
    return table[math.min(math.max(day - 1, 0), table.length - 1)];
  }
}

// ── Confetti ──────────────────────────────────────────────────
class _ConfettiLayer extends StatefulWidget {
  final int phase;
  const _ConfettiLayer({required this.phase});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
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
        painter: _ConfettiPainter(_ctrl.value, widget.phase),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final int phase;
  static const _colors = [
    AppColors.pink, AppColors.cyan, AppColors.yellow, AppColors.green,
  ];

  const _ConfettiPainter(this.t, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    if (phase < 3) return;
    final opacity = (phase >= 3 && phase < 5) ? 0.9 * t : 0.0;
    if (opacity <= 0) return;

    final cx = size.width / 2;
    final cy = size.height * 0.52;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2;
      final dist = (80.0 + (i % 3) * 30) * t;
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;
      final paint = Paint()
        ..color = _colors[i % 4].withOpacity(opacity);

      if (i % 2 == 0) {
        canvas.drawCircle(Offset(px, py), 4, paint);
      } else {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(i * 0.5);
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || old.phase != phase;
}
