import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins       = ref.watch(coinProvider);
    final ownedItems  = ref.watch(inventoryProvider);
    final currentLevel = ref.watch(levelProvider);

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(child: _ShopHeader(coins: coins)),
            SliverToBoxAdapter(child: _FeaturedDeal(coins: coins, ownedItems: ownedItems)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  onTap: (_) => ref.read(soundServiceProvider).playSound(SoundType.shopTabSwitch),
                  labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.pink,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: '🎩 Pip'),
                    Tab(text: '⚡ Boosts'),
                    Tab(text: '🔧 Skins'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ItemGrid(items: _pipItems,       coins: coins, ownedItems: ownedItems, currentLevel: currentLevel),
              _ItemGrid(items: _boostItems,     coins: coins, ownedItems: ownedItems, currentLevel: currentLevel),
              _ItemGrid(items: _furnitureItems, coins: coins, ownedItems: ownedItems, currentLevel: currentLevel),
            ],
          ),
        ),
    );
  }
}

// ── Item catalog ─────────────────────────────────────────────
typedef _ShopItem = ({
  String id,
  String name,
  String icon,
  int price,
  int? lockLevel,
});


const _pipItems = <_ShopItem>[
  // Hats — themed roofs
  (id: 'roof_tile_red',  name: 'Red Tile Roof',  icon: '🏠', price: 5,  lockLevel: null),
  (id: 'roof_tile_blue', name: 'Blue Tile Roof', icon: '🏘️', price: 5,  lockLevel: null),
  (id: 'roof_thatch',    name: 'Thatched Roof',  icon: '🌾', price: 6,  lockLevel: null),
  (id: 'roof_greek',     name: 'Greek Pediment', icon: '🏛️', price: 12, lockLevel: 5),
  (id: 'roof_japanese',  name: 'Pagoda Roof',    icon: '⛩️', price: 15, lockLevel: 10),
  // Costumes — architectural (SquarePants-style)
  (id: 'costume_brick',  name: 'Brick Wall',     icon: '🧱', price: 6,  lockLevel: null),
  (id: 'costume_wood',   name: 'Wood Cabin',     icon: '🪵', price: 6,  lockLevel: null),
  (id: 'costume_stone',  name: 'Stone Block',    icon: '🪨', price: 8,  lockLevel: 5),
  (id: 'costume_garden', name: 'Flower Garden',  icon: '🌷', price: 12, lockLevel: 12),
  // Costumes — clothing
  (id: 'costume_tuxedo',   name: 'Tuxedo',       icon: '🤵', price: 8,  lockLevel: null),
  (id: 'costume_overalls', name: 'Overalls',     icon: '👖', price: 6,  lockLevel: null),
  (id: 'costume_kimono',   name: 'Kimono',       icon: '👘', price: 12, lockLevel: 7),
  (id: 'costume_armor',    name: 'Knight Armor', icon: '🛡️', price: 15, lockLevel: 10),
];

const _boostItems = <_ShopItem>[
  (id: 'boost_2xp',    name: '2× XP · 1hr',  icon: '⚡', price: 5, lockLevel: null),
  (id: 'boost_shield', name: 'Streak Shield', icon: '🛡️', price: 5, lockLevel: null),
];

const _furnitureItems = <_ShopItem>[
  (id: 'vacuum_sakura',   name: 'Sakura Vacuum',    icon: '🌸', price: 80,  lockLevel: null),
  (id: 'vacuum_midnight', name: 'Midnight Vacuum',  icon: '🌑', price: 120, lockLevel: 3),
  (id: 'vacuum_sunburst', name: 'Sunburst Vacuum',  icon: '☀️', price: 100, lockLevel: null),
  (id: 'fridge_arctic',   name: 'Arctic Fridge',    icon: '🧊', price: 80,  lockLevel: null),
  (id: 'fridge_emerald',  name: 'Emerald Fridge',   icon: '💚', price: 100, lockLevel: null),
  (id: 'fridge_rose',     name: 'Rose Gold Fridge', icon: '🌹', price: 150, lockLevel: 5),
  (id: 'washer_ocean',    name: 'Ocean Washer',      icon: '🌊', price: 80,  lockLevel: null),
  (id: 'washer_carbon',   name: 'Carbon Washer',    icon: '🖤', price: 120, lockLevel: 3),
  (id: 'washer_neon',     name: 'Neon Washer',      icon: '💜', price: 150, lockLevel: 5),
];

// ── Header ───────────────────────────────────────────────────
class _ShopHeader extends StatelessWidget {
  final int coins;
  const _ShopHeader({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.surface2],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Pip's Stash",
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.yellow.withOpacity(.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CoinIcon(size: 16),
                const SizedBox(width: 5),
                Text(
                  '$coins',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.yellow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured deal ────────────────────────────────────────────
class _FeaturedDeal extends ConsumerWidget {
  final int coins;
  final Set<String> ownedItems;
  const _FeaturedDeal({required this.coins, required this.ownedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const featuredId = 'cosmic_wallpaper';
    final owned = ownedItems.contains(featuredId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.pink, AppColors.violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x669D5CFF), blurRadius: 20, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Text('🌌', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'FEATURED DEAL',
                      style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Cosmic Wallpaper', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  Row(
                    children: [
                      Text(
                        '10',
                        style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(.6),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white.withOpacity(.6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _CoinIcon(size: 13),
                      const SizedBox(width: 3),
                      Text('5', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                    ],
                  ),
                ],
              ),
            ),
            owned
                ? _OwnedBadge()
                : _BuyButton(id: featuredId, price: 5, coins: coins),
          ],
        ),
      ),
    );
  }
}

// ── Item grid ────────────────────────────────────────────────
class _ItemGrid extends StatelessWidget {
  final List<_ShopItem> items;
  final int coins;
  final Set<String> ownedItems;
  final int currentLevel;

  const _ItemGrid({
    required this.items,
    required this.coins,
    required this.ownedItems,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemCard(
        item: items[i],
        coins: coins,
        owned: ownedItems.contains(items[i].id),
        locked: items[i].lockLevel != null && currentLevel < items[i].lockLevel!,
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final _ShopItem item;
  final int coins;
  final bool owned;
  final bool locked;

  const _ItemCard({required this.item, required this.coins, required this.owned, required this.locked});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (owned) {
      borderColor = AppColors.green;
    } else if (locked) {
      borderColor = Colors.white.withOpacity(.06);
    } else {
      borderColor = Colors.white.withOpacity(.10);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: owned ? 2 : 1),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 34)),
            const Spacer(),
            Text(
              item.name,
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: locked ? AppColors.muted : Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (owned)
              _OwnedBadge()
            else if (locked)
              _LockedBadge(level: item.lockLevel!)
            else
              _BuyButton(id: item.id, price: item.price, coins: coins, compact: true),
          ],
        ),
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(.4)),
      ),
      child: Text('✓ OWNED', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.green)),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  final int level;
  const _LockedBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Text('🔒 LV$level', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.muted)),
    );
  }
}

void _showNotEnoughCoinsDialog(BuildContext context, int have, int need) {
  final deficit = need - have;
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0xAA000000), blurRadius: 40),
            BoxShadow(color: Color(0x44FF4D8D), blurRadius: 30, spreadRadius: -4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              'Not enough coins!',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('You have', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text('$have', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Column(
                    children: [
                      Text('Item costs', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text('$need', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.pink)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Column(
                    children: [
                      Text('Missing', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text('$deficit', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.red)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Complete quests to earn more coins!',
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.violet, AppColors.pink]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x669D5CFF), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Text(
                  'GOT IT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BuyButton extends ConsumerWidget {
  final String id;
  final int price;
  final int coins;
  final bool compact;

  const _BuyButton({required this.id, required this.price, required this.coins, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAfford = coins >= price;

    return GestureDetector(
      onTap: canAfford
          ? () {
              final bought = ref.read(coinProvider.notifier).spend(price);
              if (bought) {
                ref.read(inventoryProvider.notifier).addItem(id);
                ref.read(soundServiceProvider).playSound(SoundType.purchaseSuccess);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Purchased! 🎉', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    backgroundColor: AppColors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          : () => _showNotEnoughCoinsDialog(context, coins, price),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16, vertical: compact ? 5 : 8),
        decoration: BoxDecoration(
          gradient: canAfford ? const LinearGradient(colors: [AppColors.pink, AppColors.violet]) : null,
          color: canAfford ? null : AppColors.bgDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: canAfford ? Colors.transparent : Colors.white.withOpacity(.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CoinIcon(size: 13),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: GoogleFonts.nunito(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w900,
                color: canAfford ? Colors.white : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinIcon extends StatelessWidget {
  final double size;
  const _CoinIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _CoinPainter()));
  }
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = AppColors.yellow);
    canvas.drawCircle(c, r * 0.72, Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.bg, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
