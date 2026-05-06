import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../utils/auth_errors.dart';
import '../widgets/pip_mascot.dart';
import '../widgets/puffy_button.dart';
import 'welcome_back_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _isPasswordVisible   = false;
  bool _isLoading           = false;
  int _selectedMood         = 0;

  bool _signupDone  = false;
  int _successPhase = 0;
  late final AnimationController _checkCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _panelCtrl;

  static const _moods = ['😎', '😴', '🤓', '🧙'];

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _barCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _panelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _checkCtrl.dispose();
    _barCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      _showError("Those passwords don't match. Give it another look.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );
      if (!mounted) return;
      _startSuccess();
    } catch (e) {
      if (mounted) {
        _showError(friendlyAuthError(e));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _startSuccess() {
    setState(() => _signupDone = true);
    _checkCtrl.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _successPhase = 1);
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _successPhase = 2);
      _barCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() => _successPhase = 3);
      _panelCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeBackScreen()),
        (r) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_signupDone) return _buildSuccessScaffold(context);
    return _buildFormScaffold(context);
  }

  Widget _buildSuccessScaffold(BuildContext context) {
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
            if (_successPhase >= 1)
              const Positioned.fill(child: _ConfettiLayer()),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _successPhase >= 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSlide(
                      offset: _successPhase >= 1 ? Offset.zero : const Offset(0, 0.3),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: const PipMascot(size: 100, wave: true),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _successPhase >= 1 ? 1.0 : 0.0,
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
                  if (_successPhase >= 2)
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

            AnimatedBuilder(
              animation: _panelCtrl,
              builder: (_, __) {
                final t = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut).value;
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

  Widget _buildFormScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Back',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Hi! I'm Pip!",
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'What should I call you?',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PipMascot(size: 80),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Together we'll turn your messy room into pure VICTORY ✨",
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SignupField(
                  label: 'Your name',
                  controller: _usernameController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Name is required';
                    if (v.length < 3) return 'At least 3 characters';
                    if (v.length > 20) return 'At most 20 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _SignupField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _SignupField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _SignupField(
                  label: 'Confirm password',
                  controller: _confirmController,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Pick your starter mood',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_moods.length, (i) {
                    final selected = i == _selectedMood;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMood = i),
                        child: Container(
                          margin: EdgeInsets.only(right: i < _moods.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.violet : AppColors.bgDeep,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? AppColors.pink : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: selected
                                ? [const BoxShadow(color: Color(0xFF5B2EB5), offset: Offset(0, 4))]
                                : [const BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3))],
                          ),
                          child: Center(
                            child: Text(_moods[i], style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                PuffyButton(
                  label: _isLoading ? 'Creating account…' : 'START ADVENTURE',
                  color: AppColors.pink,
                  onTap: _isLoading ? null : _handleSignup,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Log in',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: AppColors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _SignupField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgDeep,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(.08), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.violet, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
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
