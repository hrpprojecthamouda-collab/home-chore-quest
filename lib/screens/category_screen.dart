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

class CategoryScreen extends ConsumerStatefulWidget {
  final QuestCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with SingleTickerProviderStateMixin {
  bool   _showReward = false;
  String _rewardMsg  = '';

  late final AnimationController _entryCtrl;
  late final Animation<Offset>   _headerSlide;
  late final Animation<double>   _headerFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // Header sweeps in from the right (full width off-screen)
    _headerSlide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.45)),
    );

    // Start after the route transition completes (FurnitureZoomRoute: 520 ms)
    Future.delayed(const Duration(milliseconds: 530), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _showToast(String msg) {
    setState(() { _rewardMsg = msg; _showReward = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showReward = false);
    });
  }

  Future<void> _completeQuest(int questIndex, Quest quest) async {
    final sound   = ref.read(soundServiceProvider);
    final prevLvl = levelFromXp(ref.read(xpProvider));

    ref.read(questListProvider.notifier).completeQuest(questIndex);
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
    } else if (quest.isCleanRoomQuest) {
      await sound.playSound(SoundType.questComplete);
      _showToast('+${quest.xpReward} XP · 🪙50 — Room cleaned!');
    } else {
      await sound.playSound(SoundType.questComplete);
      _showToast('+${quest.xpReward} XP — Quest done!');
    }
  }

  void _addQuestSet() {
    final cat      = widget.category;
    final notifier = ref.read(questListProvider.notifier);

    final quests = switch (cat) {
      QuestCategory.groceries => [
        ('Buy weekly groceries',       30, cat),
        ('Restock pantry essentials',  20, cat),
      ],
      QuestCategory.cleaning => [
        ('Gather trash from every room',          10, cat),
        ('Sort and put everything in its place',  20, cat),
        ('Wipe down all surfaces',                20, cat),
        ('Take out the trash',                    10, cat),
      ],
      _ => <(String, int, QuestCategory)>[],
    };

    for (final (name, xp, category) in quests) {
      notifier.addQuest(name, xp, category);
    }
    if (quests.isNotEmpty) {
      ref.read(soundServiceProvider).playSound(SoundType.addQuest);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '${quests.length} quests added! ✨',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
      backgroundColor: cat.color1,
      duration: const Duration(seconds: 1),
    ));
  }

  // Returns staggered animation value for quest card at [index].
  double _itemT(int index) {
    const stagger = 0.13;
    final start = (index * stagger).clamp(0.0, 0.60);
    final end   = (start + 0.45).clamp(0.0, 1.0);
    final raw   = (_entryCtrl.value - start) / (end - start);
    return Curves.easeOutBack.transform(raw.clamp(0.0, 1.0));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cat         = widget.category;
    final questList   = ref.watch(questsByCategory(cat));
    final pendingList = ref.watch(pendingQuestsByCategory(cat));
    final c1          = cat.color1;
    final c2          = cat.color2;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // ── Gradient header ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c1, c2],
                  ),
                ),
                // ClipRect prevents the sliding header content from painting
                // outside the gradient container during the entry animation.
                child: ClipRect(
                  child: SafeArea(
                    bottom: false,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios_new,
                                        color: AppColors.bgDeep.withOpacity(.8), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.bgDeep.withOpacity(.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.roomLabel,
                                          style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.bgDeep.withOpacity(.6),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          cat.label.split(' ').last,
                                          style: GoogleFonts.nunito(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.bgDeep,
                                          ),
                                        ),
                                        Text(
                                          '${pendingList.length} sparkly quests',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.bgDeep.withOpacity(.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(cat.glyph, style: const TextStyle(fontSize: 70)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _MiniStat(
                                    label: 'Done this week',
                                    value: questList.where((q) => q.isCompleted).length.toString(),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniStat(
                                    label: 'Earned',
                                    value: '${questList.where((q) => q.isCompleted).fold(0, (s, q) => s + q.xpReward)} XP',
                                  ),
                                  const SizedBox(width: 10),
                                  const _MiniStat(label: 'Best streak', value: '5'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Quest list ───────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Section title fades in early
                    AnimatedBuilder(
                      animation: _entryCtrl,
                      builder: (_, child) => Opacity(
                        opacity: CurvedAnimation(
                          parent: _entryCtrl,
                          curve: const Interval(0, 0.35),
                        ).value,
                        child: child,
                      ),
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
                    ),
                    const SizedBox(height: 10),

                    // Empty state
                    if (questList.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No quests here yet!',
                            style: GoogleFonts.nunito(
                                color: AppColors.muted, fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    else
                      // Quest cards — staggered rise from below
                      ...questList.asMap().entries.map((entry) {
                        final i     = entry.key;
                        final quest = entry.value;
                        final realIndex = ref.read(questListProvider).indexOf(quest);
                        final canEdit = !quest.isCleanRoomQuest && !quest.isCompleted && !quest.isOngoing && realIndex != -1;

                        final animatedCard = AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) {
                            final t = _itemT(i);
                            return Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 30),
                                child: child,
                              ),
                            );
                          },
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

                        if (!canEdit) return animatedCard;
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
                          child: animatedCard,
                        );
                      }),

                    // Add quest button
                    GestureDetector(
                      onTap: () => showAddQuestBottomSheet(context, initialCategory: cat),
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
                    ),

                    // Add Set button — groceries & cleaning only
                    if (cat == QuestCategory.groceries || cat == QuestCategory.cleaning) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _addQuestSet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c1.withOpacity(.15), c2.withOpacity(.15)],
                            ),
                            border: Border.all(color: c1.withOpacity(.55), width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '📋  Add full set',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Weekly bounty card — fades in last
                    AnimatedBuilder(
                      animation: _entryCtrl,
                      builder: (_, child) => Opacity(
                        opacity: CurvedAnimation(
                          parent: _entryCtrl,
                          curve: const Interval(0.5, 1.0),
                        ).value,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.violet, AppColors.pink]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 32)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Weekly Bounty',
                                          style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white)),
                                      Text(
                                        '${questList.where((q) => q.isCompleted).length} of ${questList.length} done · +50 bonus XP',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: questList.isEmpty
                                    ? 0
                                    : questList.where((q) => q.isCompleted).length /
                                        questList.length,
                                minHeight: 8,
                                backgroundColor: Colors.black.withOpacity(.3),
                                color: AppColors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Toast
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showReward ? 30 : -80,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showReward ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      _rewardMsg,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(.7))),
          ],
        ),
      ),
    );
  }
}

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
