import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animation/reward_choreographer.dart';
import '../animation/reward_controllers.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/quest_completion.dart';
import '../widgets/add_quest_dialog.dart';
import '../widgets/quest_detail_sheet.dart';
import '../widgets/quest_suggestion_sheet.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final QuestCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {

  // Reward animation controllers + orchestrator.
  final PipController _pipCtrl = PipController();
  final CoinChipController _coinCtrl = CoinChipController();
  final XpBarController _xpCtrl = XpBarController();
  late final RewardChoreographer _choreographer;

  @override
  void initState() {
    super.initState();

    _choreographer = RewardChoreographer(
      pip: _pipCtrl,
      coin: _coinCtrl,
      xp: _xpCtrl,
      sound: ref.read(soundServiceProvider),
    );
  }

  @override
  void dispose() {
    _choreographer.cancel();
    super.dispose();
  }

  Future<void> _completeQuest(int questIndex, Quest quest) {
    return runQuestCompletion(
      ref: ref,
      choreographer: _choreographer,
      context: context,
      index: questIndex,
      quest: quest,
    );
  }


  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cat       = widget.category;
    final questList = ref.watch(questsByCategory(cat));
    // Same screen-derived cap chilling uses (`* 0.42`). Stable across the
    // slide animation, scrolls inside the list once exceeded.
    final screenH = MediaQuery.of(context).size.height;
    final listMaxH = screenH * 0.55;
    final navBarBottom = MediaQuery.of(context).padding.bottom;

    // Presented as a modal bottom sheet — 12 px horizontal margin so the
    // sheet floats with the same width as the chilling sheet, rounded top
    // corners, soft violet halo + drop shadow. Bottom stays flush with the
    // screen edge (same as chilling).
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

              // ── Header ─────────────────────────────────────────────────
              // No category gradient — uses the same surface colour as the
              // rest of the sheet, like the chilling sheet hero. Compact
              // padding so the header height matches chilling's.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big category glyph (e.g. 🍳 for kitchen, 🚽 for
                    // bathroom). Sized like chilling's 📺.
                    Text(cat.glyph, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.label.split(' ').last,
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Quest list ───────────────────────────────────────────────
              // Mirrors the chilling sheet's structure: Flexible + a
              // ConstrainedBox with a SCREEN-derived maxHeight, plus
              // ListView.builder(shrinkWrap: true). The viewport is stable
              // across frames during the sheet's slide-up animation (because
              // screen height doesn't change), so the layout doesn't thrash
              // and the content doesn't flicker.
              //
              // Index layout:
              //   0          = "On your list" header row
              //   1          = optional empty-state placeholder
              //   1 + N      = the N quest cards
              //   last       = "+ Add a [category] quest" button
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: listMaxH),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  // Infinite cacheExtent forces every item to build on the
                  // sliver's first layout, before the sheet starts sliding
                  // up. Without this, items pop in mid-slide as the viewport
                  // grows — visible as flicker.
                  cacheExtent: double.infinity,
                  // Header (1) + empty-state-or-cards (max(1, N)) + add button (1).
                  itemCount: 1 + (questList.isEmpty ? 1 : questList.length) + 1,
                  itemBuilder: (context, idx) {
                    // 0 — section title row.
                    if (idx == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              'On your list',
                              style: GoogleFonts.nunito(
                                  fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const Spacer(),
                            if (questList.any((q) => q.isCompleted))
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Clear history?',
                                          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white)),
                                      content: Text('This will remove all completed quests from this category.',
                                          style: GoogleFonts.nunito(color: AppColors.muted, fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.muted)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref.read(questListProvider.notifier).clearCategoryHistory(cat);
                                            Navigator.pop(context);
                                          },
                                          child: Text('Clear', style: GoogleFonts.nunito(color: AppColors.red, fontWeight: FontWeight.w900)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  'Clear history',
                                  style: GoogleFonts.nunito(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    // Empty state — only when there are zero quests.
                    if (questList.isEmpty && idx == 1) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No quests here yet!',
                            style: GoogleFonts.nunito(
                                color: AppColors.muted, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }

                    // Add quest button — last slot.
                    final addBtnIdx = 1 + (questList.isEmpty ? 1 : questList.length);
                    if (idx == addBtnIdx) {
                      return GestureDetector(
                        onTap: () => showQuestSuggestionSheet(context, cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '+ Add a ${cat.label.split(' ').last.toLowerCase()} quest',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted),
                            ),
                          ),
                        ),
                      );
                    }

                    // A quest card (lazy-built).
                    final questIdx = idx - 1;
                    final quest = questList[questIdx];
                    final realIndex = ref.read(questListProvider).indexOf(quest);
                    final canEdit = !quest.isCleanRoomQuest && !quest.isCompleted && !quest.isOngoing && realIndex != -1;

                    final card = RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryQuestCard(
                          quest: quest,
                          onDelete: quest.isCompleted && realIndex != -1
                              ? () => ref.read(questListProvider.notifier).deleteQuest(realIndex)
                              : null,
                          onTapDetail: () {
                            if (quest.isOngoing) {
                              ref.read(soundServiceProvider).playSound(SoundType.buttonPress);
                              ref.read(questListProvider.notifier).cancelQuest(realIndex);
                            } else if (!quest.isCompleted) {
                              ref.read(soundServiceProvider).playSound(SoundType.questDisplay);
                              showQuestDetailSheet(
                                context,
                                quest: quest,
                                onComplete: realIndex != -1
                                    ? () => _completeQuest(realIndex, quest)
                                    : null,
                              );
                            }
                          },
                          onStart: realIndex != -1 && !quest.isCompleted
                              ? () {
                                  ref.read(soundServiceProvider).playSound(SoundType.ongoingQuest);
                                  ref.read(questListProvider.notifier).startQuest(realIndex);
                                }
                              : null,
                          onComplete: realIndex != -1
                              ? () => _completeQuest(realIndex, quest)
                              : null,
                          onEdit: canEdit
                              ? () => showAddQuestBottomSheet(
                                  context,
                                  editIndex: realIndex,
                                  questToEdit: quest,
                                )
                              : null,
                        ),
                      ),
                    );

                    if (!canEdit) return card;
                    return Dismissible(
                      key: ValueKey(quest.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          ref.read(questListProvider.notifier).deleteQuest(realIndex),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                      ),
                      child: card,
                    );
                  },
                ),
              ),
              SizedBox(height: 12 + navBarBottom),
            ],
          ),
        );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _CategoryQuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onTapDetail;
  final VoidCallback? onDelete;

  const _CategoryQuestCard({
    required this.quest,
    this.onStart,
    this.onComplete,
    this.onEdit,
    this.onTapDetail,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c1      = quest.category.color1;
    final c2      = quest.category.color2;
    final ongoing = quest.isOngoing;

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quest.isCompleted ? AppColors.bgDeep : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ongoing ? const Color(0xFFFFAB00) : AppColors.border,
          width: ongoing ? 1.5 : 1,
        ),
        boxShadow: ongoing
            ? const [
                BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4)),
                BoxShadow(color: Color(0x33FFAB00), blurRadius: 8, offset: Offset(0, 2)),
              ]
            : const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: quest.isCompleted
                    ? [AppColors.surface2, AppColors.surface]
                    : [c1, c2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: quest.isCompleted
                  ? const Icon(Icons.check, color: AppColors.green, size: 22)
                  : Text(quest.category.glyph, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (ongoing) ...[
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        quest.name,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: quest.isCompleted ? AppColors.muted : Colors.white,
                          decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${quest.xpReward} XP',
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow),
                  ),
                ),
              ],
            ),
          ),
          if (!quest.isCompleted) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: ongoing ? onComplete : onStart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 96,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ongoing ? const Color(0xFFFFAB00) : AppColors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ongoing
                          ? const Color(0xFFCC8800)
                          : const Color(0xFF22894A),
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  ongoing ? 'DONE!' : 'START QUEST',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.bgDeep),
                ),
              ),
            ),
          ],
          if (quest.isCompleted) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle, color: AppColors.green, size: 22),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.delete_outline, color: AppColors.muted, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
    return GestureDetector(
      onTap: onTapDetail,
      onLongPress: onEdit,
      child: card,
    );
  }
}
