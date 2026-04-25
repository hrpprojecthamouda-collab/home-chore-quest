import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../theme/app_theme.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}

/// Zooms from the furniture's screen rect to fill the display.
///
/// Phase 1 (0 → 60 %): the category gradient + glyph expand from [sourceRect]
///   to full screen, so the user sees the furniture "opening up."
/// Phase 2 (55 → 100 %): the actual category screen fades in on top while
///   the glyph fades out.  The category screen's own entry animations start
///   after the route completes (see CategoryScreen).
class FurnitureZoomRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Rect sourceRect;
  final QuestCategory category;

  FurnitureZoomRoute({
    required this.page,
    required this.sourceRect,
    required this.category,
  }) : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
            final size = MediaQuery.of(context).size;
            final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

            final zoomCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.62, curve: Curves.easeInOutCubic),
            );
            final contentCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.52, 1.0, curve: Curves.easeOut),
            );
            final glyphCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.52, 0.82, curve: Curves.easeOut),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (_, child) {
                final zoomT    = zoomCurve.value;
                final contentT = contentCurve.value;
                final glyphT   = glyphCurve.value;

                final rect   = Rect.lerp(sourceRect, screenRect, zoomT)!;
                final radius = (1 - zoomT) * 18.0;

                return Stack(
                  children: [
                    // Phase 1 — expanding furniture graphic
                    Positioned.fromRect(
                      rect: rect,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Category gradient (matches the furniture's colours)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [category.color1, category.color2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Glyph — fades out as the content fades in
                            if (glyphT < 1)
                              Opacity(
                                opacity: (1 - glyphT).clamp(0.0, 1.0),
                                child: Center(
                                  child: Text(category.glyph, style: const TextStyle(fontSize: 52)),
                                ),
                              ),
                            // Phase 2 — actual category screen fading in
                            Opacity(opacity: contentT, child: child),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: pageChild,
            );
          },
        );
}
