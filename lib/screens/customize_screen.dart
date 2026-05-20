import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bathroom_scene.dart';
import '../widgets/bedroom_scene.dart';
import '../widgets/flat_room_scene.dart';
import '../widgets/pip_mascot.dart';
import '../models/furniture_skin.dart';
import '../providers/furniture_providers.dart';

// ── Pip wardrobe catalog ──────────────────────────────────────
class _Item {
  final String id, name, glyph;
  final int? lockLevel;
  const _Item({required this.id, required this.name, required this.glyph, this.lockLevel});
}

const _wardrobe = <String, List<_Item>>{
  'hat': [
    _Item(id: 'none',           name: 'None',          glyph: '∅'),
    _Item(id: 'roof_tile_red',  name: 'Red Tile',      glyph: '🏠'),
    _Item(id: 'roof_tile_blue', name: 'Blue Tile',     glyph: '🏘️'),
    _Item(id: 'roof_thatch',    name: 'Thatched',      glyph: '🌾'),
    _Item(id: 'roof_greek',     name: 'Greek',         glyph: '🏛️', lockLevel: 5),
    _Item(id: 'roof_japanese',  name: 'Pagoda',        glyph: '⛩️',  lockLevel: 10),
  ],
  'costume': [
    _Item(id: 'none',             name: 'None',         glyph: '∅'),
    _Item(id: 'costume_brick',    name: 'Brick',        glyph: '🧱'),
    _Item(id: 'costume_wood',     name: 'Wood',         glyph: '🪵'),
    _Item(id: 'costume_stone',    name: 'Stone',        glyph: '🪨', lockLevel: 5),
    _Item(id: 'costume_garden',   name: 'Garden',       glyph: '🌷', lockLevel: 12),
    _Item(id: 'costume_tuxedo',   name: 'Tuxedo',       glyph: '🤵'),
    _Item(id: 'costume_overalls', name: 'Overalls',     glyph: '👖'),
    _Item(id: 'costume_kimono',   name: 'Kimono',       glyph: '👘', lockLevel: 7),
    _Item(id: 'costume_armor',    name: 'Armor',        glyph: '🛡️', lockLevel: 10),
  ],
};

const _slotInfo = <String, ({String label, String glyph})>{
  'hat':     (label: 'Hat',     glyph: '🏠'),
  'costume': (label: 'Costume', glyph: '👔'),
};

// ── Screen ────────────────────────────────────────────────────
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text('Customize', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.yellow.withOpacity(.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CoinIcon(size: 14),
                        const SizedBox(width: 4),
                        Text('$coins', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    _TabButton(label: '🎩 Pip',  active: _tabIndex == 0, onTap: () { ref.read(soundServiceProvider).playSound(SoundType.tabSwitchCustomize); setState(() => _tabIndex = 0); }),
                    _TabButton(label: '🛋️ Room', active: _tabIndex == 1, onTap: () { ref.read(soundServiceProvider).playSound(SoundType.tabSwitchCustomize); setState(() => _tabIndex = 1); }),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _tabIndex == 0 ? const _PipDressup() : const _RoomDecorator(),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.violet : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? [BoxShadow(color: _darken(AppColors.violet, 0.35), offset: const Offset(0, 2))] : null,
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w900,
              color: active ? Colors.white : AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIP DRESS-UP ──────────────────────────────────────────────
class _PipDressup extends ConsumerStatefulWidget {
  const _PipDressup();

  @override
  ConsumerState<_PipDressup> createState() => _PipDressupState();
}

class _PipDressupState extends ConsumerState<_PipDressup> {
  // Local draft; initialised from provider on first build
  Map<String, String>? _draft;
  String _slot = 'hat';

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final equippedPip = ref.watch(equippedPipProvider);
    final ownedItems  = ref.watch(inventoryProvider);
    final currentLevel = ref.watch(levelProvider);

    // Initialise draft from persisted state on first build (or after reset)
    _draft ??= Map.of(equippedPip);
    final draft = _draft!;

    final items = _wardrobe[_slot]!;

    return Column(
      children: [
        // Preview stage
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 0.8,
              colors: [AppColors.violet.withOpacity(.33), AppColors.bgDeep],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 18, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 160, height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              ...[
                (left: 18.0, top: 22.0),
                (left: 70.0, top: 14.0),
                (left: 270.0, top: 22.0),
                (left: 320.0, top: 14.0),
              ].map((sp) => Positioned(
                left: sp.left, top: sp.top,
                child: const Text('✨', style: TextStyle(fontSize: 14)),
              )),
              Positioned(
                bottom: 10, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('PREVIEW', style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
                ),
              ),
              Center(child: PipWithItems(equipped: draft, size: 130)),
            ],
          ),
        ),

        // Slot picker chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: _slotInfo.entries.map((entry) {
              final s    = entry.key;
              final info = entry.value;
              final active = _slot == s;
              final eqId = draft[s] ?? 'none';
              final eqItem = _wardrobe[s]!.firstWhere((i) => i.id == eqId, orElse: () => _wardrobe[s]!.first);
              return Expanded(
                child: GestureDetector(
                  onTap: () { ref.read(soundServiceProvider).playSound(SoundType.itemSwitchTick); setState(() => _slot = s); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.yellow.withOpacity(.13) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.yellow : AppColors.border, width: 2),
                      boxShadow: active ? [BoxShadow(color: _darken(AppColors.yellow, 0.4), offset: const Offset(0, 2))] : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(info.glyph, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(info.label.toUpperCase(), style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.muted, letterSpacing: 0.5)),
                        Text(eqItem.id != 'none' ? eqItem.name : '—', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Item grid (3-col)
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: items.map((it) {
              final isOwned  = it.id == 'none' || ownedItems.contains(it.id);
              final isLocked = it.lockLevel != null && currentLevel < it.lockLevel!;
              final disabled = isLocked || !isOwned;
              final isEq     = draft[_slot] == it.id;

              return GestureDetector(
                onTap: disabled ? null : () { ref.read(soundServiceProvider).playSound(SoundType.itemSwitchTick); setState(() => _draft = {...draft, _slot: it.id}); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (!isOwned && !isLocked) ? AppColors.bgDeep : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isEq ? AppColors.green : AppColors.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: isEq ? _darken(AppColors.green, 0.35) : Colors.black.withOpacity(.3),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Opacity(
                                opacity: (isLocked || (!isOwned && !isLocked)) ? 0.4 : 1.0,
                                child: Text(it.glyph, style: TextStyle(fontSize: it.id == 'none' ? 22 : 28, color: it.id == 'none' ? AppColors.muted : null)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(it.name.toUpperCase(), style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w900, color: disabled ? AppColors.muted : Colors.white, letterSpacing: 0.3), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      if (isEq)
                        Positioned(
                          top: -6, right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: _darken(AppColors.green, .35), offset: const Offset(0, 2))]),
                            child: Text('ON', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.bg, letterSpacing: 0.5)),
                          ),
                        ),
                      if (isLocked)
                        Positioned(
                          top: -6, right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
                            child: const Text('🔒', style: TextStyle(fontSize: 8)),
                          ),
                        ),
                      if (!isOwned && !isLocked)
                        Positioned(
                          top: -6, right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: _darken(AppColors.pink, .35), offset: const Offset(0, 2))]),
                            child: Text('BUY', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Save bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(color: AppColors.bgDeep, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _draft = {'hat': 'none', 'costume': 'none'}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 2)),
                    child: Text('RESET', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.muted, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    ref.read(soundServiceProvider).playSound(SoundType.saveConfirm);
                    final notifier = ref.read(equippedPipProvider.notifier);
                    for (final entry in draft.entries) {
                      notifier.equip(entry.key, entry.value);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Look saved! ✨', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: HSLColor.fromColor(AppColors.green).withLightness((HSLColor.fromColor(AppColors.green).lightness - .35).clamp(0, 1)).toColor(), offset: const Offset(0, 4))],
                    ),
                    child: Text('SAVE LOOK ✓', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.bg, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── ROOM DECORATOR ────────────────────────────────────────────
enum _PreviewRoom { living, bedroom, bathroom }

_PreviewRoom _roomForFurniture(FurnitureType t) => switch (t) {
      FurnitureType.vacuum     => _PreviewRoom.living,
      FurnitureType.fridge     => _PreviewRoom.living,
      FurnitureType.bed        => _PreviewRoom.bedroom,
      FurnitureType.desk       => _PreviewRoom.bedroom,
      FurnitureType.wardrobe   => _PreviewRoom.bedroom,
      FurnitureType.washer     => _PreviewRoom.bathroom,
      FurnitureType.toilet     => _PreviewRoom.bathroom,
      FurnitureType.mirrorSink => _PreviewRoom.bathroom,
    };

String _furnitureLabel(FurnitureType t) => switch (t) {
      FurnitureType.vacuum     => '🫧 Vacuum',
      FurnitureType.fridge     => '🧊 Fridge',
      FurnitureType.washer     => '🌀 Washer',
      FurnitureType.bed        => '🛏️ Bed',
      FurnitureType.desk       => '🪵 Desk',
      FurnitureType.wardrobe   => '🚪 Wardrobe',
      FurnitureType.toilet     => '🚽 Toilet',
      FurnitureType.mirrorSink => '🪞 Mirror',
    };

class _RoomDecorator extends ConsumerStatefulWidget {
  const _RoomDecorator();

  @override
  ConsumerState<_RoomDecorator> createState() => _RoomDecoratorState();
}

class _RoomDecoratorState extends ConsumerState<_RoomDecorator> {
  Map<FurnitureType, String>? _skinDraft;
  FurnitureType _selectedFurnitureType = FurnitureType.vacuum;

  Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final equippedFurniture = ref.watch(equippedFurnitureProvider);
    final ownedItems        = ref.watch(inventoryProvider);

    _skinDraft ??= Map.of(equippedFurniture);
    final skinDraft = _skinDraft!;

    final previewSkins = {
      for (final e in skinDraft.entries) e.key: skinById(e.value)
    };

    final cw    = MediaQuery.of(context).size.width - 24;
    final roomH = cw * kRoomCanvasH / kRoomCanvasW;

    // Which room the selected furniture lives in — drives the preview scene.
    final previewRoom = _roomForFurniture(_selectedFurnitureType);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Room canvas preview — auto-switches between living / bedroom / bathroom
                // based on which furniture type is currently selected.
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  height: roomH,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: switch (previewRoom) {
                          _PreviewRoom.living   => FlatRoomScene(messy: false, skinOverrides: previewSkins, showPip: false, showBadges: false),
                          _PreviewRoom.bedroom  => BedroomScene(messy: false, skinOverrides: previewSkins, showPip: false),
                          _PreviewRoom.bathroom => BathroomScene(messy: false, skinOverrides: previewSkins, showPip: false),
                        },
                      ),
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            switch (previewRoom) {
                              _PreviewRoom.living   => '🛋️ LIVING ROOM',
                              _PreviewRoom.bedroom  => '🛏️ BEDROOM',
                              _PreviewRoom.bathroom => '🛁 BATHROOM',
                            },
                            style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.yellow, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Furniture type chips — wrapped so all 8 types fit in two rows.
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: FurnitureType.values.map((t) {
                      final isActive = _selectedFurnitureType == t;
                      final label = _furnitureLabel(t);
                      return GestureDetector(
                        onTap: () {
                          ref.read(soundServiceProvider).playSound(SoundType.itemSwitchTick);
                          setState(() => _selectedFurnitureType = t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.violet.withValues(alpha: .25) : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isActive ? AppColors.violet : AppColors.border, width: isActive ? 2 : 1),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: isActive ? Colors.white : AppColors.muted),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Skin cards grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: kFurnitureSkins
                        .where((s) => s.type == _selectedFurnitureType)
                        .map((skin) {
                      final isOwned    = skin.isFree || ownedItems.contains(skin.id);
                      final isEquipped = skinDraft[skin.type] == skin.id;
                      return GestureDetector(
                        onTap: isOwned
                            ? () {
                                ref.read(soundServiceProvider).playSound(SoundType.itemSwitchTick);
                                setState(() => _skinDraft = {...skinDraft, skin.type: skin.id});
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isEquipped ? AppColors.green.withValues(alpha: .12) : (!isOwned ? AppColors.bgDeep : AppColors.surface),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEquipped ? AppColors.green : AppColors.border,
                              width: isEquipped ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Opacity(opacity: isOwned ? 1.0 : 0.4, child: Text(skin.glyph, style: const TextStyle(fontSize: 22))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      skin.name,
                                      style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, color: isOwned ? Colors.white : AppColors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isEquipped)
                                      Text('ON', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.green))
                                    else if (!isOwned)
                                      Text('🪙 ${skin.price}', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.yellow))
                                    else
                                      Text('Owned', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: skin.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: .25)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Save bar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(color: AppColors.bgDeep, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _skinDraft = {for (final t in FurnitureType.values) t: kDefaultSkins[t]!.id};
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 2)),
                    child: Text('RESET', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.muted, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    ref.read(soundServiceProvider).playSound(SoundType.saveConfirm);
                    final furNotifier = ref.read(equippedFurnitureProvider.notifier);
                    for (final entry in skinDraft.entries) {
                      furNotifier.equip(entry.key, entry.value);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Room saved! 🛋️', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _darken(AppColors.green, .35), offset: const Offset(0, 4))],
                    ),
                    child: Text('SAVE ROOM ✓', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.bg, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Coin icon ──────────────────────────────────────────────────
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
      ..color = const Color(0xFFA07000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18);
  }

  @override
  bool shouldRepaint(_) => false;
}
