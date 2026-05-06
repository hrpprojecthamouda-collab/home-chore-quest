import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import 'customize_screen.dart';
import 'home_screen.dart';
import 'shop_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 1; // 0 = Customize · 1 = Home · 2 = Shop

  static const _shopTab = 2;

  void _onTabTap(int i) {
    if (i == _tab) return; // no-op on same tab
    final sound = ref.read(soundServiceProvider);
    if (i == _shopTab) sound.duck();        // entering shop
    if (_tab == _shopTab) sound.unduck();   // leaving shop
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _tab,
        children: const [
          CustomizeScreen(),
          HomeScreen(),
          ShopScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onTap: _onTabTap,
      ),
    );
  }
}

// ── Custom bottom bar ─────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int index;
  final void Function(int) onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.palette_outlined,
                activeIcon: Icons.palette,
                label: 'Customize',
                active: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                active: index == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: 'Shop',
                active: index == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.yellow : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                active ? activeIcon : icon,
                color: color,
                size: 22,
                key: ValueKey(active),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
