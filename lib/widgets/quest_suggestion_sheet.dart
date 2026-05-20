// Modal bottom sheet that surfaces catalog suggestions for a single
// category. Opened by the "+ Add" button on each category sheet (and ONLY
// inside categories — the quest board still uses the free-form add).
//
// Each row is a suggestion ranked easiest → hardest. Tapping a row adds
// the quest to the user's pending list (it does NOT auto-complete). The
// "Add full set" button at the bottom adds every row at once.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/quest_catalog.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

void showQuestSuggestionSheet(BuildContext context, QuestCategory category) {
  final screenH = MediaQuery.of(context).size.height;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    constraints: BoxConstraints(maxHeight: screenH * 0.75),
    builder: (_) => _QuestSuggestionSheet(category: category),
  );
}

class _QuestSuggestionSheet extends ConsumerWidget {
  final QuestCategory category;
  const _QuestSuggestionSheet({required this.category});

  static String _tierLabel(int xp) {
    if (xp <= 5)  return 'Tiny';
    if (xp <= 10) return 'Easy';
    if (xp <= 20) return 'Solid';
    return 'Boss';
  }

  static Color _tierColor(int xp) {
    if (xp <= 5)  return AppColors.cyan;
    if (xp <= 10) return AppColors.green;
    if (xp <= 20) return AppColors.violet;
    return AppColors.pink;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = catalogFor(category);

    void addOne(CatalogQuest q) {
      ref.read(questListProvider.notifier).addQuest(q.name, q.xpReward, q.category);
      ref.read(soundServiceProvider).playSound(SoundType.addQuest);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.violet,
        content: Text('“${q.name}” added! ✨',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white)),
        duration: const Duration(seconds: 1),
      ));
    }

    void addAll() {
      final notifier = ref.read(questListProvider.notifier);
      for (final q in suggestions) {
        notifier.addQuest(q.name, q.xpReward, q.category);
      }
      ref.read(soundServiceProvider).playSound(SoundType.addQuest);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.green,
        content: Text('${suggestions.length} quests added! ✨',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.bg)),
        duration: const Duration(seconds: 1),
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x669D5CFF), blurRadius: 40, offset: Offset(0, -10)),
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle.
          SafeArea(
            bottom: false,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),

          // Header — category glyph + title, matches the category sheet hero.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Text(category.glyph, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a ${category.label.split(' ').last.toLowerCase()} quest',
                        style: GoogleFonts.nunito(
                          fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tap one to add it — or grab the full set.',
                        style: GoogleFonts.nunito(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Suggestion list.
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: suggestions.length,
              itemBuilder: (_, i) {
                final q = suggestions[i];
                final tier = _tierLabel(q.xpReward);
                final color = _tierColor(q.xpReward);
                final coins = coinsForTier(q.xpReward);
                return GestureDetector(
                  onTap: () => addOne(q),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Tier badge.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Text(
                            tier.toUpperCase(),
                            style: GoogleFonts.nunito(
                              fontSize: 9, fontWeight: FontWeight.w900,
                              color: color, letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quest name.
                        Expanded(
                          child: Text(
                            q.name,
                            style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // XP + coin payouts.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${q.xpReward} XP',
                              style: GoogleFonts.nunito(
                                fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.muted,
                              ),
                            ),
                            if (coins > 0) ...[
                              const SizedBox(width: 6),
                              Text('🪙$coins',
                                  style: GoogleFonts.nunito(
                                      fontSize: 11, fontWeight: FontWeight.w900,
                                      color: AppColors.yellow)),
                            ],
                          ],
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.add_circle_outline, color: AppColors.muted, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add full set button.
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: GestureDetector(
              onTap: addAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [category.color1, category.color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: category.color2.withValues(alpha: 0.3), offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    '📋  Add full set (${suggestions.length} quests)',
                    style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.bg,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
