import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class XpBar extends StatelessWidget {
  final int value;
  final int max;

  const XpBar({super.key, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(.4), width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.yellow, AppColors.pink, AppColors.hotPink],
                    stops: [0, .6, 1],
                  ),
                ),
              ),
            ),
            // Shine overlay
            Positioned(
              top: 2,
              left: 0,
              right: 0,
              height: 3,
              child: FractionallySizedBox(
                widthFactor: pct * .6,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
