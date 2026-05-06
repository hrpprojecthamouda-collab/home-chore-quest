import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_quest_dialog.dart';
import '../widgets/quest_detail_sheet.dart';
import 'celebration_screen.dart';

class AllQuestsScreen extends ConsumerStatefulWidget {
  const AllQuestsScreen({super.key});

  @override
  ConsumerState<AllQuestsScreen> createState() => _AllQuestsScreenState();
}

class _AllQuestsScreenState extends ConsumerState<AllQuestsScreen> {

  Future<void> _completeQuest(int index, Quest quest) async {
    final sound   = ref.read(soundServiceProvider);
    final prevLvl = levelFromXp(ref.read(xpProvider));

    ref.read(questListProvider.notifier).completeQuest(index);
    ref.read(xpProvider.notifier).addXp(quest.xpReward);
    if (quest.isCleanRoomQuest) {
      ref.read(roomCleanProvider.notifier).cleanRoom();
      ref.read(coinProvider.notifier).addCoins(50);
    }

    final newLvl = levelFromXp(ref.read(xpProvider));
    if (newLvl > prevLvl) {
      ref.read(coinProvider.notifier).addCoins(50);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await sound.playSound(SoundType.levelUp);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CelebrationScreen(level: newLvl)),
      );
    } else {
      await sound.playSound(SoundType.questComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questList = ref.watch(questListProvider);
    final pending   = questList.where((q) => !q.isCompleted).toList();

    // Group pending quests by category, preserving QuestCategory enum order.
    // Clean-room quest has category = cleaning, so it appears under that section.
    final sections = [
      for (final cat in QuestCategory.values)
        (cat, pending.where((q) => q.category == cat).toList()),
    ].where((s) => s.$2.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quest Board',
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text(
                          pending.isEmpty
                              ? 'All clear!'
                              : '${pending.length} quest${pending.length == 1 ? '' : 's'} pending',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showAddQuestBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.pink,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0xFFA8125C),
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('ADD',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Empty state ────────────────────────────────────────
            if (sections.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 12),
                      Text('All done!',
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Pip is proud of you.',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted)),
                    ],
                  ),
                ),
              ),

            // ── Category sections ──────────────────────────────────
            for (final (cat, quests) in sections) ...[
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [cat.color1, cat.color2],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: cat.color2.withOpacity(.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(cat.glyph,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          cat.label.split(' ').last.toUpperCase(),
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${quests.length}',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quest cards
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final quest     = quests[i];
                    final realIndex = questList.indexOf(quest);
                    final canEdit   = !quest.isCleanRoomQuest && !quest.isOngoing && realIndex != -1;

                    final card = Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _QuestCard(
                        quest: quest,
                        onTapDetail: () {
                          if (quest.isOngoing) {
                            ref
                                .read(soundServiceProvider)
                                .playSound(SoundType.buttonPress);
                            ref
                                .read(questListProvider.notifier)
                                .cancelQuest(realIndex);
                          } else {
                            ref
                                .read(soundServiceProvider)
                                .playSound(SoundType.questDisplay);
                            showQuestDetailSheet(
                              context,
                              quest: quest,
                              onComplete: () =>
                                  _completeQuest(realIndex, quest),
                            );
                          }
                        },
                        onStart: () {
                          ref
                              .read(soundServiceProvider)
                              .playSound(SoundType.ongoingQuest);
                          ref
                              .read(questListProvider.notifier)
                              .startQuest(realIndex);
                        },
                        onComplete: () => _completeQuest(realIndex, quest),
                        onEdit: canEdit
                            ? () {
                                ref
                                    .read(soundServiceProvider)
                                    .playSound(SoundType.questEdit);
                                showAddQuestBottomSheet(
                                  context,
                                  editIndex: realIndex,
                                  questToEdit: quest,
                                );
                              }
                            : null,
                      ),
                    );

                    if (!canEdit) return card;
                    return Dismissible(
                      key: ValueKey(quest.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref
                          .read(questListProvider.notifier)
                          .deleteQuest(realIndex),
                      background: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Container(
                          decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 26),
                        ),
                      ),
                      child: card,
                    );
                  },
                  childCount: quests.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Quest card ────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onTapDetail;

  const _QuestCard({
    required this.quest,
    required this.onStart,
    required this.onComplete,
    this.onEdit,
    this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final c1 = quest.category.color1;
    final c2 = quest.category.color2;
    final ongoing = quest.isOngoing;

    return GestureDetector(
      onTap: onTapDetail,
      onLongPress: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
              : const [
                  BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4)),
                  BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
                ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [c1, c2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x33FFFFFF), offset: Offset(0, 2))
                ],
              ),
              child: Center(
                  child: Text(quest.category.glyph,
                      style: const TextStyle(fontSize: 22))),
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
                        child: Text(quest.name,
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('+${quest.xpReward} XP',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.yellow)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: ongoing ? onComplete : onStart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
        ),
      ),
    );
  }
}
