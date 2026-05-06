import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../providers/audio_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/add_quest_dialog.dart';
import '../widgets/quest_detail_sheet.dart';
import '../widgets/flat_room_scene.dart';
import '../widgets/xp_bar.dart';
import 'all_quests_screen.dart';
import 'category_screen.dart';
import 'celebration_screen.dart';
import 'logout_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showReward  = false;
  String _rewardMsg = '';
  late DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(audioSettingsProvider).musicMuted) {
        ref.read(soundServiceProvider).playSonicLogoThenMusic(MusicTrack.lobby);
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    ref.read(soundServiceProvider).stopMusic();
    super.dispose();
  }

  void _signOut() {
    ref.read(soundServiceProvider).stopMusic();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LogoutScreen()),
    );
  }

  void _showToast(String msg) {
    setState(() { _rewardMsg = msg; _showReward = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showReward = false);
    });
  }

  Future<void> _completeQuest(int index, Quest quest) async {
    final sound    = ref.read(soundServiceProvider);
    final prevLvl  = levelFromXp(ref.read(xpProvider));

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
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CelebrationScreen(level: newLvl),
      ));
    } else if (quest.isCleanRoomQuest) {
      await sound.playSound(SoundType.questComplete);
      _showToast('+${quest.xpReward} XP · 🪙50 — Room cleaned!');
    } else {
      await sound.playSound(SoundType.questComplete);
      _showToast('+${quest.xpReward} XP — Quest done!');
    }
  }

  void _navigateToCategory(QuestCategory cat, Rect sourceRect) {
    final soundType = switch (cat) {
      QuestCategory.laundry   => SoundType.menuLaundry,
      QuestCategory.cleaning  => SoundType.menuCleaning,
      QuestCategory.groceries => SoundType.menuGroceries,
      QuestCategory.bills     => SoundType.menuBills,
    };
    final sound = ref.read(soundServiceProvider);
    sound.duck();
    sound.playSound(soundType);
    Navigator.of(context).push(
      FurnitureZoomRoute(
        page: CategoryScreen(category: cat),
        sourceRect: sourceRect,
        category: cat,
      ),
    ).then((_) {
      if (mounted) ref.read(soundServiceProvider).unduck();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioSettings>(audioSettingsProvider, (_, next) {
      ref.read(soundServiceProvider).applySettings(next);
    });

    final isClean      = ref.watch(roomCleanProvider);
    final currentLevel = ref.watch(levelProvider);
    final xpProgress   = ref.watch(xpProgressProvider);
    final xpToNext     = ref.watch(xpToNextLevelProvider);
    final questList    = ref.watch(questListProvider);
    final pendingCount = ref.watch(pendingQuestCountProvider);
    final userName     = ref.watch(authStateProvider).value?.displayName ?? 'Adventurer';
    final streak       = ref.watch(loginStreakProvider);
    final coins        = ref.watch(coinProvider);
    final pendingQuests = questList.where((q) => !q.isCompleted).toList();

    final mq        = MediaQuery.of(context);
    final screenH   = mq.size.height;
    final screenW   = mq.size.width;
    final safeTop   = mq.padding.top;

    // Compute how much screen sits below the room card (sheet must not exceed this).
    final roomCardH     = (screenW - 24) * kRoomCanvasH / kRoomCanvasW;
    final fixedH        = safeTop + 100.0 + roomCardH; // status bar + header + xp + room
    final belowRoomFrac = ((screenH - fixedH) / screenH).clamp(0.10, 0.88);

    // Collapsed: sheet header (56 px) + 1 full card + half card = 176 px,
    // capped so the sheet never rises above the room card bottom.
    final collapsedFrac = (176.0 / screenH).clamp(0.10, belowRoomFrac);
    // Expanded: ~4 cards + sheet header + bottom padding = 456 px.
    final expandedFrac  = (456.0 / screenH).clamp(collapsedFrac + 0.05, 0.88);

    return Stack(
      children: [
        // Fixed top: header + XP bar + room card
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(userName, currentLevel, pendingCount, streak, coins),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Column(
                  children: [
                    XpBar(value: xpProgress, max: xpForLevel(currentLevel)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xpProgress / ${xpForLevel(currentLevel)} XP',
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                        Text(
                          '$xpToNext XP to LV ${currentLevel + 1} 🌟',
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.yellow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildRoomCard(isClean),
              ),
            ],
          ),
        ),

        // Pull-up quest sheet
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: collapsedFrac,
          minChildSize: collapsedFrac,
          maxChildSize: expandedFrac,
          snap: true,
          snapSizes: [collapsedFrac, expandedFrac],
          builder: (ctx, scrollController) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle — tappable & draggable
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) {
                      if (!_sheetController.isAttached) return;
                      final delta = -(d.primaryDelta ?? 0) / screenH;
                      _sheetController.jumpTo(
                        (_sheetController.size + delta).clamp(collapsedFrac, expandedFrac),
                      );
                    },
                    onVerticalDragEnd: (d) {
                      if (!_sheetController.isAttached) return;
                      final velocity = d.primaryVelocity ?? 0;
                      final mid = (collapsedFrac + expandedFrac) / 2;
                      final goUp = velocity < -400 ||
                          (_sheetController.size >= mid && velocity <= 400);
                      _sheetController.animateTo(
                        goUp ? expandedFrac : collapsedFrac,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending quests',
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(soundServiceProvider).duck();
                            Navigator.of(context).push(
                              SlidePageRoute(page: const AllQuestsScreen()),
                            ).then((_) {
                              if (mounted) ref.read(soundServiceProvider).unduck();
                            });
                          },
                          child: Text(
                            'SEE ALL ›',
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quest list
                  Expanded(
                    child: pendingQuests.isEmpty
                        ? Center(
                            child: Text(
                              '✨ All clear! Pip is proud of you.',
                              style: GoogleFonts.nunito(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: pendingQuests.length,
                            itemBuilder: (ctx, i) {
                              final quest     = pendingQuests[i];
                              final realIndex = questList.indexOf(quest);
                              final canEdit   = !quest.isCleanRoomQuest && !quest.isOngoing && realIndex != -1;

                              final card = Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _QuestCard(
                                  quest: quest,
                                  onTapDetail: () {
                                    if (quest.isOngoing) {
                                      ref.read(soundServiceProvider).playSound(SoundType.buttonPress);
                                      ref.read(questListProvider.notifier).cancelQuest(realIndex);
                                    } else {
                                      ref.read(soundServiceProvider).playSound(SoundType.questDisplay);
                                      showQuestDetailSheet(
                                        context,
                                        quest: quest,
                                        onComplete: () => _completeQuest(realIndex, quest),
                                      );
                                    }
                                  },
                                  onStart: () {
                                    ref.read(soundServiceProvider).playSound(SoundType.ongoingQuest);
                                    ref.read(questListProvider.notifier).startQuest(realIndex);
                                  },
                                  onComplete: () => _completeQuest(realIndex, quest),
                                  onEdit: canEdit
                                      ? () {
                                          ref.read(soundServiceProvider).playSound(SoundType.questEdit);
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
                                onDismissed: (_) =>
                                    ref.read(questListProvider.notifier).deleteQuest(realIndex),
                                background: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                                  ),
                                ),
                                child: card,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),

        // Toast notification
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
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    _rewardMsg,
                    style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),

        // FAB
        Positioned(
          right: 18,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
          child: GestureDetector(
            onTap: () => showAddQuestBottomSheet(context),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0xFFA8125C), offset: Offset(0, 5)),
                  BoxShadow(color: Color(0x66FF4D8D), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name, int level, int pending, int streak, int coins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          // Avatar circle + name — tap to open profile
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              SlidePageRoute(page: const ProfileScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC98AFF), AppColors.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3))],
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: GoogleFonts.nunito(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(name, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          const Spacer(),
          _Chip(
            label: '🔥 $streak',
            color: AppColors.yellow,
            dark: true,
            onTap: () => _showStreakSheet(streak),
          ),
          const SizedBox(width: 6),
          _Chip(label: '🪙 $coins', color: const Color(0xFF7A5A00), dark: false),
          const SizedBox(width: 6),
          _Chip(label: '💎 $pending', color: AppColors.violet),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _signOut,
            child: const Icon(Icons.logout, color: AppColors.muted, size: 20),
          ),
        ],
      ),
    );
  }

  void _showStreakSheet(int streak) {
    final String title;
    final String subtitle;
    if (streak == 0) {
      title = 'No streak yet';
      subtitle = 'Log in every day to start your streak!';
    } else if (streak == 1) {
      title = '1 Day Streak!';
      subtitle = 'Day 1 — the hardest step is always the first. Keep it up!';
    } else if (streak < 7) {
      title = '$streak Day Streak!';
      subtitle = 'You\'re building momentum. Don\'t break the chain!';
    } else if (streak < 14) {
      title = '$streak Day Streak! 💪';
      subtitle = 'A full week strong. You\'re making this a habit!';
    } else if (streak < 30) {
      title = '$streak Day Streak! 🌟';
      subtitle = 'Incredible consistency. Pip is very proud of you!';
    } else {
      title = '$streak Day Streak! 👑';
      subtitle = 'Legendary dedication. You\'re unstoppable!';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🔥', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                ref.read(soundServiceProvider).playSound(SoundType.awesome);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFCC8800), offset: Offset(0, 3)),
                  ],
                ),
                child: Text('KEEP GOING!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.bgDeep)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(bool isClean) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;
        final ch = cw * kRoomCanvasH / kRoomCanvasW;

        return Container(
          height: ch,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF1A1030),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                FlatRoomScene(
                  messy: !isClean,
                  onCategoryTap: _navigateToCategory,
                ),
                const Positioned(
                  bottom: 22,
                  left: 10,
                  child: _MusicSpeakerOverlay(),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isClean ? AppColors.green : AppColors.red,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 2))],
                    ),
                    child: Text(
                      isClean ? '✨ TIDY' : '😬 MESSY',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isClean ? AppColors.bgDeep : Colors.white,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
                // Tap hint
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Tap furniture to open a category',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(.45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
                gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x33FFFFFF), offset: Offset(0, 2))],
              ),
              child: Center(child: Text(quest.category.glyph, style: const TextStyle(fontSize: 22))),
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
                          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+${quest.xpReward} XP',
                          style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.yellow),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        quest.category.label.split(' ').last,
                        style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ],
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
                      color: ongoing ? const Color(0xFFCC8800) : const Color(0xFF22894A),
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  ongoing ? 'DONE!' : 'START QUEST',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.bgDeep,
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

// ─── Music speaker overlay ─────────────────────────────────────
class _MusicSpeakerOverlay extends ConsumerStatefulWidget {
  const _MusicSpeakerOverlay();

  @override
  ConsumerState<_MusicSpeakerOverlay> createState() => _MusicSpeakerOverlayState();
}

class _MusicSpeakerOverlayState extends ConsumerState<_MusicSpeakerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (!ref.read(audioSettingsProvider).musicMuted) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioSettings>(audioSettingsProvider, (_, next) {
      if (!next.musicMuted) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
        _ctrl.reset();
      }
    });
    final enabled = !ref.watch(audioSettingsProvider).musicMuted;

    return GestureDetector(
      onTap: () => ref.read(audioSettingsProvider.notifier).toggleMusicMute(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;

          double noteOffset(double p) => p * 24;
          double noteOpacity(double p) {
            if (p < 0.15) return p / 0.15;
            if (p > 0.75) return (1.0 - p) / 0.25;
            return 1.0;
          }

          // Two staggered notes
          final p1 = t;
          final p2 = (t + 0.55) % 1.0;

          return SizedBox(
            width: 40,
            height: 58,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Speaker emoji
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      enabled ? '🔊' : '🔇',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                // Note 1 (♪, yellow, right side)
                if (enabled)
                  Positioned(
                    bottom: 24 + noteOffset(p1),
                    right: 2,
                    child: Opacity(
                      opacity: noteOpacity(p1).clamp(0.0, 1.0),
                      child: Text(
                        '♪',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.yellow,
                        ),
                      ),
                    ),
                  ),
                // Note 2 (♫, cyan, left side)
                if (enabled)
                  Positioned(
                    bottom: 24 + noteOffset(p2),
                    left: 2,
                    child: Opacity(
                      opacity: noteOpacity(p2).clamp(0.0, 1.0),
                      child: Text(
                        '♫',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;
  final VoidCallback? onTap;

  const _Chip({required this.label, required this.color, this.dark = false, this.onTap});

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0, 1)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: _darken(color, .2), offset: const Offset(0, 2))],
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: dark ? AppColors.bgDeep : Colors.white),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
