import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../providers/audio_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/bathroom_scene.dart';
import '../widgets/bedroom_scene.dart';
import '../widgets/chilling_sheet.dart';
import '../widgets/flat_room_scene.dart';
import '../animation/reward_choreographer.dart';
import '../animation/reward_controllers.dart';
import '../widgets/reward_overlay_header.dart';
import 'all_quests_screen.dart';
import 'category_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showReward  = false;
  String _rewardMsg = '';
  // Reward animation controllers + orchestrator.
  final PipController _pipCtrl = PipController();
  final CoinChipController _coinCtrl = CoinChipController();
  final XpBarController _xpCtrl = XpBarController();
  late final RewardChoreographer _choreographer;

  // Swipe between the three rooms. 0 = Bedroom, 1 = Living (default), 2 = Bathroom.
  late final PageController _pageCtrl;
  int _currentRoom = 1;
  // True while the home screen is the topmost route. Flipped false the
  // instant we push a category / all-quests / shop route, restored when we
  // come back. Drives the `active` flag on each room scene so off-screen
  // rooms don't burn the frame budget during transitions.
  bool _homeOnTop = true;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 1);
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page;
      if (p == null) return;
      final r = p.round();
      if (r != _currentRoom) {
        setState(() => _currentRoom = r);
      }
    });
    _choreographer = RewardChoreographer(
      pip: _pipCtrl,
      coin: _coinCtrl,
      xp: _xpCtrl,
      sound: ref.read(soundServiceProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(audioSettingsProvider).musicMuted) {
        ref.read(soundServiceProvider).playSonicLogoThenMusic(MusicTrack.lobby);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _choreographer.cancel();
    ref.read(soundServiceProvider).stopMusic();
    super.dispose();
  }


  // Reserved for future toast cues; currently the reward choreography
  // communicates gains through Pip + counter + bar animations.
  // ignore: unused_element
  void _showToast(String msg) {
    setState(() { _rewardMsg = msg; _showReward = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showReward = false);
    });
  }

  void _navigateToCategory(QuestCategory cat, Rect sourceRect) {
    final soundType = switch (cat) {
      QuestCategory.laundry     => SoundType.menuLaundry,
      QuestCategory.livingAreas => SoundType.menuLivingAreas,  // broom sweep
      QuestCategory.kitchen     => SoundType.menuKitchen,      // sizzling pan
      QuestCategory.bedroom     => SoundType.menuBedroom,      // bed-making rustle
      QuestCategory.admin       => SoundType.menuBills,        // legacy paperwork sfx
      // Bathroom keeps the legacy cleaning sound until a dedicated one exists.
      QuestCategory.bathroom    => SoundType.menuCleaning,
    };
    final sound = ref.read(soundServiceProvider);
    sound.duck();
    sound.playSound(soundType);
    // Pause all room animations the moment we open the sheet so the home
    // stops painting underneath the slide-up transition.
    setState(() => _homeOnTop = false);
    // Matches the chilling sheet's config exactly: no constraints (the sheet
    // sizes to its content so the slide-up and the visible content move in
    // lockstep), no useSafeArea, no extra wrappers.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => CategoryScreen(category: cat),
    ).then((_) {
      if (!mounted) return;
      ref.read(soundServiceProvider).unduck();
      setState(() => _homeOnTop = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioSettings>(audioSettingsProvider, (_, next) {
      ref.read(soundServiceProvider).applySettings(next);
    });

    final isClean      = ref.watch(roomCleanProvider);
    final currentLevel = ref.watch(levelProvider);
    final userName     = ref.watch(authStateProvider).value?.displayName ?? 'Adventurer';

    return Stack(
      children: [
        // Fixed top: header + XP bar; room fills the remaining space.
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(userName, currentLevel),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                child: RewardOverlayHeader(
                  xpController: _xpCtrl,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 4,
                  ),
                  child: _buildRoomCard(isClean),
                ),
              ),
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

      ],
    );
  }

  Widget _buildHeader(String name, int level) {
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
          RewardCoinChip(controller: _coinCtrl),
        ],
      ),
    );
  }


  Widget _buildRoomCard(bool isClean) {
    void openAllQuests() {
      ref.read(soundServiceProvider).playSound(SoundType.questDisplay);
      ref.read(soundServiceProvider).duck();
      setState(() => _homeOnTop = false);
      Navigator.of(context).push(
        SlidePageRoute(page: const AllQuestsScreen()),
      ).then((_) {
        if (!mounted) return;
        ref.read(soundServiceProvider).unduck();
        setState(() => _homeOnTop = true);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1030),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          children: [
            // Swipe between three rooms — Bedroom (0) · Living (1, default) · Bathroom (2).
            Positioned.fill(
              child: PageView(
                controller: _pageCtrl,
                physics: const PageScrollPhysics(),
                children: [
                  BedroomScene(
                    active: _homeOnTop && _currentRoom == 0,
                    messy: !isClean,
                    onCategoryTap: _navigateToCategory,
                    pipController: _pipCtrl,
                  ),
                  FlatRoomScene(
                    active: _homeOnTop && _currentRoom == 1,
                    messy: !isClean,
                    onCategoryTap: _navigateToCategory,
                    onQuestBoardTap: openAllQuests,
                    onChillingTap: () {
                      ref.read(soundServiceProvider).playSound(SoundType.menuChilling);
                      showChillingSheet(context);
                    },
                    pipController: _pipCtrl,
                  ),
                  BathroomScene(
                    active: _homeOnTop && _currentRoom == 2,
                    messy: !isClean,
                    onCategoryTap: _navigateToCategory,
                    pipController: _pipCtrl,
                  ),
                ],
              ),
            ),
            // Music speaker — always visible across all rooms.
            const Positioned(
              bottom: 22,
              left: 10,
              child: _MusicSpeakerOverlay(),
            ),
            // Three-dot page indicator at the bottom centre.
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(child: _RoomPageDots(current: _currentRoom)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page indicator: 3 dots, active dot is a wider pill ───────
class _RoomPageDots extends StatelessWidget {
  final int current;
  const _RoomPageDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
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

