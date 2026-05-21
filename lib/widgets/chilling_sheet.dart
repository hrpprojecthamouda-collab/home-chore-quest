// Chilling sheet — the SPEND side of the economy.
//
// Tapping the TV on the home scene opens this modal bottom sheet. Each row
// is a leisure reward the player can redeem by spending coins (snack, episode,
// stroll, gaming session, nap). Vibrant when at least one reward is affordable,
// locked (greyed) when the balance is below the cheapest reward.
//
// On REDEEM:
//   1. coinProvider.spend(cost) — atomically subtracts the cost (or returns
//      false if the balance dropped between display and tap).
//   2. Plays a small confirmation sound.
//   3. Pops the sheet and shows a brief "Enjoy!" SnackBar.
//
// No quest is created, no XP is awarded. This is purely a coin sink and a
// permission slip — "you've earned this break, enjoy."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'puffy_button.dart';

/// One leisure reward the player can redeem.
class ChillingReward {
  final String id;
  final String glyph;
  final String name;
  final int cost;       // coins
  final String tagline; // one-liner under the name

  const ChillingReward({
    required this.id,
    required this.glyph,
    required this.name,
    required this.cost,
    required this.tagline,
  });
}

const List<ChillingReward> kChillingRewards = [
  ChillingReward(
    id: 'snack',
    glyph: '🍫',
    name: 'A snack of your choice',
    cost: 15,
    tagline: 'Something from the good shelf.',
  ),
  ChillingReward(
    id: 'episode',
    glyph: '📺',
    name: 'Watch one episode',
    cost: 20,
    tagline: 'Eyes off chores, on the show.',
  ),
  ChillingReward(
    id: 'walk',
    glyph: '🌳',
    name: 'Outdoor stroll',
    cost: 25,
    tagline: 'Phone-free, fresh-air mode.',
  ),
  ChillingReward(
    id: 'gaming',
    glyph: '🎮',
    name: '30 min gaming session',
    cost: 30,
    tagline: 'Pick up the controller — no guilt.',
  ),
  ChillingReward(
    id: 'nap',
    glyph: '🛋️',
    name: 'Guilt-free 1-hr nap',
    cost: 50,
    tagline: 'Pip will watch the door.',
  ),
];

void showChillingSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChillingSheet(),
  );
}

class _ChillingSheet extends ConsumerStatefulWidget {
  const _ChillingSheet();

  @override
  ConsumerState<_ChillingSheet> createState() => _ChillingSheetState();
}

class _ChillingSheetState extends ConsumerState<_ChillingSheet> {
  String? _selectedId;

  static const _cheapestCost = 15; // the snack

  ChillingReward? get _selected =>
      _selectedId == null ? null : kChillingRewards.firstWhere((r) => r.id == _selectedId);

  Future<void> _redeem() async {
    final reward = _selected;
    if (reward == null) return;
    final ok = ref.read(coinProvider.notifier).spend(reward.cost);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          content: Text("Not enough coins for ${reward.name}",
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
      );
      return;
    }
    await ref.read(soundServiceProvider).playSound(SoundType.saveConfirm);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.violet,
        content: Text("Enjoy ${reward.name}! ✨",
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinProvider);
    final navBarBottom = MediaQuery.of(context).padding.bottom;
    final affordableAtAll = coins >= _cheapestCost;
    final reward = _selected;
    final canRedeem = reward != null && coins >= reward.cost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x66FF8AD9), blurRadius: 40, offset: Offset(0, -10)),
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle.
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 44, height: 5,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Hero — title + coin balance pill.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Text('📺', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chilling',
                          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(
                        affordableAtAll
                            ? 'Spend coins on something good.'
                            : "Finish quests in any room to earn coins.",
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _CoinPill(coins: coins),
              ],
            ),
          ),

          // Rewards list.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kChillingRewards.length,
              itemBuilder: (_, i) {
                final r = kChillingRewards[i];
                final affordable = coins >= r.cost;
                final selected = _selectedId == r.id;
                return _RewardRow(
                  reward: r,
                  affordable: affordable,
                  selected: selected,
                  onTap: () => setState(() => _selectedId = r.id),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // CTA.
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 18 + navBarBottom),
            child: PuffyButton(
              label: reward == null
                  ? 'PICK A REWARD'
                  : canRedeem
                      ? 'REDEEM · 🪙 ${reward.cost}'
                      : 'NEED ${reward.cost - coins} MORE COINS',
              color: canRedeem ? AppColors.pink : AppColors.surface2,
              onTap: canRedeem ? _redeem : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7A5A00),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final ChillingReward reward;
  final bool affordable;
  final bool selected;
  final VoidCallback onTap;

  const _RewardRow({
    required this.reward,
    required this.affordable,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.bgDeep;
    final accent = const Color(0xFFff8ad9);
    final disabled = !affordable;
    return GestureDetector(
      onTap: affordable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.06),
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withValues(alpha: 0.35), offset: const Offset(0, 3))]
              : null,
        ),
        child: Opacity(
          opacity: disabled ? 0.55 : 1.0,
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: disabled
                      ? null
                      : LinearGradient(
                          colors: [accent, AppColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: disabled ? AppColors.surface2 : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reward.glyph, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.name,
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(reward.tagline,
                        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: disabled ? AppColors.surface2 : AppColors.yellow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: disabled ? AppColors.border : const Color(0xFF7A5A00),
                    width: 1,
                  ),
                ),
                child: Text(
                  disabled ? '🔒 ${reward.cost}' : '🪙 ${reward.cost}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: disabled ? AppColors.muted : const Color(0xFF7A5A00),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
