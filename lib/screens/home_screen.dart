import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../providers/auth_providers.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/add_quest_dialog.dart';
import '../widgets/room_scene.dart';
import '../widgets/xp_bar.dart';
import 'category_screen.dart';
import 'celebration_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showReward  = false;
  String _rewardMsg = '';

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out?', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Pip will miss you 💜', style: GoogleFonts.nunito(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out', style: GoogleFonts.nunito(color: AppColors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log out: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  void _showToast(String msg) {
    setState(() { _rewardMsg = msg; _showReward = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showReward = false);
    });
  }

  Future<void> _completeQuest(int index, Quest quest) async {
    final sound = ref.read(soundServiceProvider);
    final prevXp  = ref.read(xpProvider);
    final prevLvl = (prevXp ~/ xpPerLevel) + 1;

    ref.read(questListProvider.notifier).completeQuest(index);
    ref.read(xpProvider.notifier).addXp(quest.xpReward);
    if (quest.isCleanRoomQuest) ref.read(roomCleanProvider.notifier).cleanRoom();
    await sound.playSound(SoundType.questComplete);

    final newXp  = ref.read(xpProvider);
    final newLvl = (newXp ~/ xpPerLevel) + 1;

    if (newLvl > prevLvl) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await sound.playSound(SoundType.levelUp);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CelebrationScreen(level: newLvl),
      ));
    } else {
      _showToast('+${quest.xpReward} XP — Quest done!');
    }
  }

  void _navigateToCategory(QuestCategory cat, Rect sourceRect) {
    Navigator.of(context).push(
      FurnitureZoomRoute(
        page: CategoryScreen(category: cat),
        sourceRect: sourceRect,
        category: cat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClean        = ref.watch(roomCleanProvider);
    final currentXp      = ref.watch(xpProvider);
    final currentLevel   = ref.watch(levelProvider);
    final xpProgress     = ref.watch(xpProgressProvider);
    final xpToNext       = ref.watch(xpToNextLevelProvider);
    final questList      = ref.watch(questListProvider);
    final pendingCount   = ref.watch(pendingQuestCountProvider);
    final userName       = ref.watch(authStateProvider).value?.displayName ?? 'Adventurer';

    final pendingQuests  = questList.where((q) => !q.isCompleted).toList();
    final badgeCounts = {
      QuestCategory.cleaning:  ref.watch(pendingQuestsByCategory(QuestCategory.cleaning)).length,
      QuestCategory.groceries: ref.watch(pendingQuestsByCategory(QuestCategory.groceries)).length,
      QuestCategory.bills:     ref.watch(pendingQuestsByCategory(QuestCategory.bills)).length,
      QuestCategory.upgrades:  ref.watch(pendingQuestsByCategory(QuestCategory.upgrades)).length,
    };

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(userName, currentLevel, pendingCount)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Column(
                      children: [
                        XpBar(value: xpProgress, max: xpPerLevel),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$xpProgress / $xpPerLevel XP',
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
                ),
                // Room scene
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildRoomCard(isClean, badgeCounts),
                  ),
                ),
                // Today's quests header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's quests",
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            SlidePageRoute(page: const CategoryScreen(category: QuestCategory.cleaning)),
                          ),
                          child: Text(
                            'SEE ALL ›',
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Quest list
                pendingQuests.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              '✨ All clear! Pip is proud of you.',
                              style: GoogleFonts.nunito(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final quest = pendingQuests[i];
                            final realIndex = questList.indexOf(quest);
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _QuestCard(
                                quest: quest,
                                onComplete: () => _completeQuest(realIndex, quest),
                              ),
                            );
                          },
                          childCount: pendingQuests.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
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
            bottom: 18,
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
      ),
    );
  }

  Widget _buildHeader(String name, int level, int pending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Avatar circle
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
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $name!', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
              Text('Level $level adventurer', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ],
          ),
          const Spacer(),
          _Chip(label: '🔥 0', color: AppColors.yellow, dark: true),
          const SizedBox(width: 8),
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

  Widget _buildRoomCard(bool isClean, Map<QuestCategory, int> badgeCounts) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface2, AppColors.bgDeep],
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            RoomScene(
              messy: !isClean,
              onCategoryTap: _navigateToCategory,
              badgeCounts: badgeCounts,
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
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const _QuestCard({required this.quest, required this.onComplete});

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0, 1)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final c1 = quest.category.color1;
    final c2 = quest.category.color2;
    final green = AppColors.green;
    final greenDark = const Color(0xFF22894A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
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
                Text(
                  quest.name,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
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
          // DO IT button
          GestureDetector(
            onTap: onComplete,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: greenDark, offset: const Offset(0, 3))],
              ),
              child: Text(
                'DO IT',
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
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;

  const _Chip({required this.label, required this.color, this.dark = false});

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0, 1)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}
