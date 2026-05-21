import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PuffyButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool small;
  final bool fullWidth;

  const PuffyButton({
    super.key,
    required this.label,
    this.color = AppColors.pink,
    this.onTap,
    this.small = false,
    this.fullWidth = true,
  });

  @override
  State<PuffyButton> createState() => _PuffyButtonState();
}

class _PuffyButtonState extends State<PuffyButton> {
  bool _pressed = false;

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = _darken(widget.color, .28);
    final vPad = widget.small ? 8.0 : 14.0;
    final hPad = widget.small ? 14.0 : 22.0;
    final fontSize = widget.small ? 12.0 : 15.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [BoxShadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: .5,
          ),
        ),
      ),
    );
  }
}
