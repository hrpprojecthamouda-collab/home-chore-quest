import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animation/reward_controllers.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import 'animated_coin_counter.dart';
import 'pip_mascot.dart';
import 'xp_bar.dart';

/// Header strip with the XP bar, controllable via [XpBarController].
///
/// Used on home (above the room) and on category / all-quests screens
/// (overlaid at the top of the scaffold body). The reward coin chip is
/// rendered separately by each screen — on home it sits in the header row
/// next to this widget; on category / all-quests it lives in the bottom-right
/// corner alongside the Pip.
class RewardOverlayHeader extends ConsumerWidget {
  final XpBarController xpController;
  /// Whether to show the small "X / Y XP" subtitle line under the bar.
  final bool showXpLabels;

  const RewardOverlayHeader({
    super.key,
    required this.xpController,
    this.showXpLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpProgress = ref.watch(xpProgressProvider);
    final currentLevel = ref.watch(levelProvider);
    final maxXp = xpForLevel(currentLevel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          XpBar(
            value: xpProgress,
            max: maxXp,
            controller: xpController,
          ),
          if (showXpLabels) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$xpProgress / $maxXp XP',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coin chip with glow halo controlled by [CoinChipController.highlight].
class RewardCoinChip extends StatefulWidget {
  final CoinChipController controller;
  const RewardCoinChip({super.key, required this.controller});

  @override
  State<RewardCoinChip> createState() => _RewardCoinChipState();
}

class _RewardCoinChipState extends State<RewardCoinChip>
    with SingleTickerProviderStateMixin {
  static const _color = Color(0xFF7A5A00);
  late final AnimationController _glowCtrl;
  // Composed controller — the inner counter handles count-up + punch; this
  // wrapper handles the surrounding glow halo.
  final _innerCtrl = CoinChipController();

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0, 1)).toColor();
  }

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _attach();
  }

  void _attach() {
    widget.controller.attach(
      highlight: () {
        // Glow halo on the chip + small punch on the counter.
        _glowCtrl.forward(from: 0).then((_) => _glowCtrl.reverse());
        _innerCtrl.highlight();
      },
      countTo: (target) => _innerCtrl.countTo(target),
      snap: (v) => _innerCtrl.snap(v),
    );
  }

  @override
  void didUpdateWidget(covariant RewardCoinChip old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller.detach();
      _attach();
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        final glow = _glowCtrl.value;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: _darken(_color, .2), offset: const Offset(0, 2)),
              if (glow > 0)
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.6 * glow),
                  blurRadius: 14 * glow,
                  spreadRadius: 1.5 * glow,
                ),
            ],
            border: glow > 0
                ? Border.all(color: AppColors.yellow.withOpacity(glow), width: 1.5)
                : null,
          ),
          child: AnimatedCoinCounter(
            prefix: '🪙 ',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            controller: _innerCtrl,
          ),
        );
      },
    );
  }
}

/// Small Pip in the corner — used on category and all-quests screens where
/// Pip isn't naturally on screen. Wired to a [PipController] so the
/// choreographer can trigger her happiness reaction.
class RewardCornerPip extends StatelessWidget {
  final PipController controller;
  final double size;
  const RewardCornerPip({super.key, required this.controller, this.size = 64});

  @override
  Widget build(BuildContext context) {
    // PipWithItems renders the equipped hat + costume on top of the base
    // mascot — same look the player customized in the customize screen.
    return PipWithItems(size: size, controller: controller);
  }
}
