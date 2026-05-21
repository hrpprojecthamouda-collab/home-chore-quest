import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/furniture_skin.dart';
import '../providers/auth_providers.dart';
import '../providers/furniture_providers.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pip_mascot.dart';
import '../widgets/xp_bar.dart';
import 'logout_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName       = ref.watch(authStateProvider).value?.displayName ?? 'Adventurer';
    final level          = ref.watch(levelProvider);
    final xp             = ref.watch(xpProvider);
    final xpProgress     = ref.watch(xpProgressProvider);
    final xpToNext       = ref.watch(xpToNextLevelProvider);
    final streak         = ref.watch(loginStreakProvider);
    final coins          = ref.watch(coinProvider);
    final questList      = ref.watch(questListProvider);
    final equippedPip    = ref.watch(equippedPipProvider);

    final completedCount = questList.where((q) => q.isCompleted && !q.isCleanRoomQuest).length;
    final pendingCount   = questList.where((q) => !q.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                    Text('Profile',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Pip mascot ───────────────────────────────────
              PipWithItems(size: 120, equipped: equippedPip),

              const SizedBox(height: 16),

              // ── Level badge + name ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFC98AFF), AppColors.violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text('$level',
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(userName,
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ],
              ),

              const SizedBox(height: 20),

              // ── XP bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    XpBar(value: xpProgress, max: xpForLevel(level)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$xpProgress / ${xpForLevel(level)} XP',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted)),
                        Text('$xpToNext XP to LV ${level + 1} 🌟',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.yellow)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Stat tiles ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatTile(icon: '🔥', label: 'Streak', value: '$streak ${streak == 1 ? 'day' : 'days'}'),
                    const SizedBox(width: 10),
                    _StatTile(icon: '🪙', label: 'Coins', value: '$coins'),
                    const SizedBox(width: 10),
                    _StatTile(icon: '✅', label: 'Done', value: '$completedCount'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Info card ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoRow('Total XP earned', '$xp XP'),
                      const Divider(color: AppColors.border, height: 18),
                      _InfoRow('Pending quests',
                          '$pendingCount quest${pendingCount == 1 ? '' : 's'}'),
                      const Divider(color: AppColors.border, height: 18),
                      _InfoRow('Quests completed',
                          '$completedCount quest${completedCount == 1 ? '' : 's'}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Actions ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LogoutScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout,
                                color: AppColors.muted, size: 18),
                            const SizedBox(width: 8),
                            Text('Sign Out',
                                style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── DEV PANEL ────────────────────────────────────
              _DevPanel(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ── Dev panel ─────────────────────────────────────────────────
class _DevPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<_DevPanel> {
  bool _open = false;
  double _xpSlider  = 0;
  double _coinSlider = 0;

  @override
  void initState() {
    super.initState();
    // Defer so ref is available after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _xpSlider   = ref.read(xpProvider).toDouble().clamp(0, 30000);
        _coinSlider = ref.read(coinProvider).toDouble().clamp(0, 9999);
      });
    });
  }

  void _apply() {
    final uid   = ref.read(currentUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt('${uid}_xp',    _xpSlider.round());
    prefs.setInt('${uid}_coins', _coinSlider.round());
    ref.invalidate(xpProvider);
    ref.invalidate(coinProvider);
  }

  void _reinitialize() {
    final uid   = ref.read(currentUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    // Clear every per-user key
    for (final key in [
      '${uid}_xp',
      '${uid}_coins',
      '${uid}_quests',
      '${uid}_isRoomClean',
      '${uid}_cleanRoomNextDue',
      '${uid}_loginStreak',
      '${uid}_lastLoginDay',
      '${uid}_ownedItems',
      '${uid}_equippedPip',
      '${uid}_equippedRoom',
      ...FurnitureType.values.map((t) => '${uid}_fur_${t.name}'),
    ]) {
      prefs.remove(key);
    }

    // Invalidate all providers so the UI rebuilds from defaults
    ref.invalidate(xpProvider);
    ref.invalidate(coinProvider);
    ref.invalidate(questListProvider);
    ref.invalidate(roomCleanProvider);
    ref.invalidate(loginStreakProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(equippedPipProvider);
    ref.invalidate(equippedRoomProvider);
    ref.invalidate(equippedFurnitureProvider);

    // Reset sliders to match new state
    setState(() {
      _xpSlider   = 0;
      _coinSlider = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1030),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withValues(alpha: .4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🛠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Dev Tools',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.red)),
                  const Spacer(),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.muted, size: 18),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 14),
                // XP slider
                Text('XP  →  ${_xpSlider.round()}  (level ${levelFromXp(_xpSlider.round())})',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                Slider(
                  value: _xpSlider,
                  min: 0,
                  max: 30000,
                  divisions: 100,
                  activeColor: AppColors.violet,
                  inactiveColor: AppColors.surface2,
                  onChanged: (v) => setState(() => _xpSlider = v),
                ),
                const SizedBox(height: 4),
                // Coin slider
                Text('Coins  →  ${_coinSlider.round()}',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                Slider(
                  value: _coinSlider,
                  min: 0,
                  max: 9999,
                  divisions: 200,
                  activeColor: AppColors.yellow,
                  inactiveColor: AppColors.surface2,
                  onChanged: (v) => setState(() => _coinSlider = v),
                ),
                const SizedBox(height: 10),
                // Quick-set buttons
                Row(
                  children: [
                    for (final lvl in [1, 5, 10, 20, 30])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() =>
                              _xpSlider = xpThreshold(lvl).toDouble()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('L$lvl',
                                style: GoogleFonts.nunito(
                                    fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _coinSlider = 9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('MAX 🪙',
                            style: GoogleFonts.nunito(
                                fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _apply,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('APPLY',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _reinitialize,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.red.withValues(alpha: .5)),
                          ),
                          child: Text('RESET\nACCOUNT',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.red, letterSpacing: 0.3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted)),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ],
    );
  }
}
