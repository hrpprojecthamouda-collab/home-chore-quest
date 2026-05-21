import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../theme/app_theme.dart';

void showQuestDetailSheet(
  BuildContext context, {
  required Quest quest,
  VoidCallback? onComplete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuestDetailSheet(quest: quest, onComplete: onComplete),
  );
}

class _QuestDetailSheet extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onComplete;

  const _QuestDetailSheet({required this.quest, this.onComplete});

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
  Widget build(BuildContext context) {
    final cat           = quest.category;
    final navBarBottom  = MediaQuery.of(context).padding.bottom;
    final canComplete   = !quest.isCompleted && onComplete != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x669D5CFF), blurRadius: 40, offset: Offset(0, -10)),
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.muted.withOpacity(.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Category gradient header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cat.color1, cat.color2]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(cat.glyph, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.label.split(' ').last.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quest.name,
                        style: GoogleFonts.nunito(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // XP + Difficulty tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _InfoTile(
                  top: '+${quest.xpReward}',
                  topColor: AppColors.yellow,
                  bottom: 'XP Reward',
                ),
                const SizedBox(width: 10),
                _InfoTile(
                  top: _tierLabel(quest.xpReward),
                  topColor: _tierColor(quest.xpReward),
                  bottom: 'Difficulty',
                ),
                const SizedBox(width: 10),
                _InfoTile(
                  top: quest.isCompleted ? '✓ Done' : '⏳ Open',
                  topColor: quest.isCompleted ? AppColors.green : AppColors.muted,
                  bottom: 'Status',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DO IT button
          if (canComplete)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + navBarBottom),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onComplete!();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF22894A), offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    'START QUEST  ✓',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.bgDeep,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 16 + navBarBottom),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String top;
  final Color  topColor;
  final String bottom;

  const _InfoTile({required this.top, required this.topColor, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              top,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: topColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bottom,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
