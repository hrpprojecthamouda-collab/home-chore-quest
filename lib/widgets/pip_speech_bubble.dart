// Retro-gaming dialog box Pip uses to surface clean-home facts.
//
// Style: hard pixel-art look — square corners, thick double border (outer
// dark frame + inner cyan highlight), opaque dark fill, Press Start 2P
// font (Google Fonts) at a small size with wide letterspacing. Mimics the
// dialog windows from 8-bit RPGs.
//
// Flow: two-step dialogue. The first page is a congratulations line; tap
// advances to the second page, which is the fact. Tap again dismisses.
// A small blinking "▼ NEXT" / "▼ OK" indicator in the bottom-right hints
// at the tap interaction, like the chevron in classic JRPG message boxes.
//
// Animation: scales in from the bottom-center on appear so it visually
// emerges from Pip below. Scales out on dismiss. No auto-dismiss timer —
// user-paced (the player taps through).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PipSpeechBubble extends StatefulWidget {
  /// The fact / second-page text. The first page is a fixed
  /// congratulations line owned by this widget.
  final String text;
  final VoidCallback onDismissed;

  const PipSpeechBubble({
    super.key,
    required this.text,
    required this.onDismissed,
  });

  static const _congratsLine = 'CONGRATS! YOU ARE\nDOING A GOOD JOB!';

  @override
  State<PipSpeechBubble> createState() => _PipSpeechBubbleState();
}

class _PipSpeechBubbleState extends State<PipSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  // 0 = congrats page, 1 = fact page. Tap advances; tap on page 1 dismisses.
  int _page = 0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      // Snappy retro pop-in.
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();
  }

  Future<void> _onTap() async {
    if (_dismissed) return;
    if (_page == 0) {
      setState(() => _page = 1);
      return;
    }
    _dismissed = true;
    await _anim.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _page == 0 ? PipSpeechBubble._congratsLine : widget.text;
    final indicator = _page == 0 ? '▼ NEXT' : '▼ OK';
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) {
          // Pivot about the bottom-center so the bubble emerges from
          // Pip's mouth (which sits just below the bubble).
          return Align(
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: _scale.value.clamp(0.0, 1.0),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, minWidth: 160),
              child: _PixelDialogBox(text: body, indicator: indicator),
            ),
            // Downward pixel tail — three stacked rectangles, decreasing
            // width, to read as a stepped "speech tail" in 8-bit style.
            const _PixelTail(),
          ],
        ),
      ),
    );
  }
}

class _PixelDialogBox extends StatelessWidget {
  final String text;
  final String indicator;
  const _PixelDialogBox({required this.text, required this.indicator});

  // Outer black frame, inner cyan highlight ring, dark navy fill — the
  // classic NES dialog palette adapted to the app's deep-violet theme.
  static const _frameOuter = Color(0xFF0A0418);          // near-black
  static const _frameInner = AppColors.cyan;             // bright highlight
  static const _fill       = Color(0xFF181030);          // AppColors.bg

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer dark frame
      padding: const EdgeInsets.all(3),
      color: _frameOuter,
      child: Container(
        // Inner cyan highlight
        padding: const EdgeInsets.all(2),
        color: _frameInner,
        child: Container(
          // Body
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          color: _fill,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 9,
                  color: Colors.white,
                  height: 1.6,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Bottom-right "next / ok" hint — like the blinking
              // chevron in classic RPG dialog boxes.
              Align(
                alignment: Alignment.bottomRight,
                child: _BlinkingHint(text: indicator),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingHint extends StatefulWidget {
  final String text;
  const _BlinkingHint({required this.text});

  @override
  State<_BlinkingHint> createState() => _BlinkingHintState();
}

class _BlinkingHintState extends State<_BlinkingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink,
      child: Text(
        widget.text,
        style: GoogleFonts.pressStart2p(
          fontSize: 7,
          color: AppColors.cyan,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PixelTail extends StatelessWidget {
  const _PixelTail();

  // Three stepped rectangles, decreasing in width — the classic
  // 8-bit "stepped triangle" tail. Each row has a 1-pixel cyan
  // highlight side-walls and the dark frame underneath.
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _TailRow(width: 18, height: 4),
        _TailRow(width: 12, height: 4),
        _TailRow(width: 6,  height: 4),
      ],
    );
  }
}

class _TailRow extends StatelessWidget {
  final double width;
  final double height;
  const _TailRow({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: _PixelDialogBox._frameOuter,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        color: _PixelDialogBox._frameInner,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Container(color: _PixelDialogBox._fill),
      ),
    );
  }
}
