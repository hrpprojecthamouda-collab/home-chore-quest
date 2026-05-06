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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w     = constraints.maxWidth;
            final fillW = w * pct;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  width: fillW,
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
                Positioned(
                  left: 0, top: 2,
                  height: 3,
                  width: fillW * .6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
