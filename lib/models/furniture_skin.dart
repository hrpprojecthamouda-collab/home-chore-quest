import 'package:flutter/material.dart';

// Every customisable piece of furniture across the three rooms.
//
// Living room:  vacuum, fridge, washer (washer is painted in the bathroom
//               scene but the type lives here for back-compat with prefs)
// Bedroom:      bed, desk, wardrobe
// Bathroom:     toilet, mirrorSink
enum FurnitureType {
  vacuum,
  fridge,
  washer,
  bed,
  desk,
  wardrobe,
  toilet,
  mirrorSink,
}

class FurnitureSkin {
  final String id;
  final String name;
  final String glyph;
  final int price;
  final FurnitureType type;
  final Color primary;
  final Color light;
  final Color dark;

  const FurnitureSkin({
    required this.id,
    required this.name,
    required this.glyph,
    required this.price,
    required this.type,
    required this.primary,
    required this.light,
    required this.dark,
  });

  bool get isFree => price == 0;
}

const kFurnitureSkins = <FurnitureSkin>[
  // ── Vacuum ────────────────────────────────────────────────────
  FurnitureSkin(id: 'vacuum_default',  name: 'Teal Dream',  glyph: '🫧', price: 0,   type: FurnitureType.vacuum, primary: Color(0xFF2dd4bf), light: Color(0xFFa3f3e6), dark: Color(0xFF0f766e)),
  FurnitureSkin(id: 'vacuum_sakura',   name: 'Sakura',      glyph: '🌸', price: 80,  type: FurnitureType.vacuum, primary: Color(0xFFf43f5e), light: Color(0xFFffd6e0), dark: Color(0xFF9f1239)),
  FurnitureSkin(id: 'vacuum_midnight', name: 'Midnight',    glyph: '🌑', price: 120, type: FurnitureType.vacuum, primary: Color(0xFF818cf8), light: Color(0xFFc7d2fe), dark: Color(0xFF3730a3)),
  FurnitureSkin(id: 'vacuum_sunburst', name: 'Sunburst',    glyph: '☀️', price: 100, type: FurnitureType.vacuum, primary: Color(0xFFf59e0b), light: Color(0xFFfef3c7), dark: Color(0xFF92400e)),
  // ── Fridge ────────────────────────────────────────────────────
  FurnitureSkin(id: 'fridge_default',  name: 'Warm Wood',   glyph: '🪵', price: 0,   type: FurnitureType.fridge, primary: Color(0xFFe8b478), light: Color(0xFFfde2bf), dark: Color(0xFF7c4a1c)),
  FurnitureSkin(id: 'fridge_arctic',   name: 'Arctic',      glyph: '🧊', price: 80,  type: FurnitureType.fridge, primary: Color(0xFF7dd3fc), light: Color(0xFFe0f2fe), dark: Color(0xFF075985)),
  FurnitureSkin(id: 'fridge_emerald',  name: 'Emerald',     glyph: '💚', price: 100, type: FurnitureType.fridge, primary: Color(0xFF34d399), light: Color(0xFFa7f3d0), dark: Color(0xFF065f46)),
  FurnitureSkin(id: 'fridge_rose',     name: 'Rose Gold',   glyph: '🌹', price: 150, type: FurnitureType.fridge, primary: Color(0xFFf9a8d4), light: Color(0xFFfce7f3), dark: Color(0xFF9d174d)),
  // ── Washer ────────────────────────────────────────────────────
  FurnitureSkin(id: 'washer_default',  name: 'Classic',     glyph: '🫧', price: 0,   type: FurnitureType.washer, primary: Color(0xFFaab1cc), light: Color(0xFFf4f6ff), dark: Color(0xFFa78bfa)),
  FurnitureSkin(id: 'washer_ocean',    name: 'Ocean',       glyph: '🌊', price: 80,  type: FurnitureType.washer, primary: Color(0xFF38bdf8), light: Color(0xFFe0f2fe), dark: Color(0xFF0369a1)),
  FurnitureSkin(id: 'washer_carbon',   name: 'Carbon',      glyph: '🖤', price: 120, type: FurnitureType.washer, primary: Color(0xFF4b5563), light: Color(0xFF9ca3af), dark: Color(0xFF111827)),
  FurnitureSkin(id: 'washer_neon',     name: 'Neon',        glyph: '💜', price: 150, type: FurnitureType.washer, primary: Color(0xFFe879f9), light: Color(0xFFfae8ff), dark: Color(0xFF86198f)),

  // ── Bed (bedroom) ─────────────────────────────────────────────
  // primary = duvet, light = mattress/sheet, dark = wood frame
  FurnitureSkin(id: 'bed_default',     name: 'Cozy Blue',   glyph: '🛏️', price: 0,   type: FurnitureType.bed,      primary: Color(0xFF7ab8ff), light: Color(0xFFf1ecff), dark: Color(0xFF5a3a1d)),
  FurnitureSkin(id: 'bed_rose',        name: 'Rose Velvet', glyph: '🌹', price: 90,  type: FurnitureType.bed,      primary: Color(0xFFf472b6), light: Color(0xFFfdf2f8), dark: Color(0xFF7a2d4a)),
  FurnitureSkin(id: 'bed_emerald',     name: 'Emerald',     glyph: '💚', price: 120, type: FurnitureType.bed,      primary: Color(0xFF34d399), light: Color(0xFFf0fdf4), dark: Color(0xFF065f46)),

  // ── Desk (bedroom) ────────────────────────────────────────────
  // primary = desktop, light = drawer face, dark = legs/cabinet
  FurnitureSkin(id: 'desk_default',    name: 'Walnut',      glyph: '🪵', price: 0,   type: FurnitureType.desk,     primary: Color(0xFFa86b3a), light: Color(0xFF5a3a1d), dark: Color(0xFF3a230f)),
  FurnitureSkin(id: 'desk_oak',        name: 'Light Oak',   glyph: '🌾', price: 80,  type: FurnitureType.desk,     primary: Color(0xFFd9b48a), light: Color(0xFFa8845a), dark: Color(0xFF6b4a2a)),
  FurnitureSkin(id: 'desk_mahogany',   name: 'Mahogany',    glyph: '🍷', price: 110, type: FurnitureType.desk,     primary: Color(0xFF7a2e2a), light: Color(0xFF541a1a), dark: Color(0xFF2a0808)),

  // ── Wardrobe (bedroom) ────────────────────────────────────────
  // primary = door face, light = body frame, dark = inset panels
  FurnitureSkin(id: 'wardrobe_default',name: 'Mahogany',    glyph: '🚪', price: 0,   type: FurnitureType.wardrobe, primary: Color(0xFF7a4520), light: Color(0xFF5a3a1d), dark: Color(0xFF3a230f)),
  FurnitureSkin(id: 'wardrobe_pine',   name: 'Pine',        glyph: '🌲', price: 80,  type: FurnitureType.wardrobe, primary: Color(0xFFc89a5e), light: Color(0xFFa07a3e), dark: Color(0xFF5e4520)),
  FurnitureSkin(id: 'wardrobe_lacquer',name: 'Black Lacquer',glyph: '✨', price: 130, type: FurnitureType.wardrobe, primary: Color(0xFF1a1a22), light: Color(0xFF2a2a3a), dark: Color(0xFF050508)),

  // ── Toilet (bathroom) ─────────────────────────────────────────
  // primary = ceramic shell, light = inner water/seat, dark = tank seam
  FurnitureSkin(id: 'toilet_default',  name: 'Porcelain',   glyph: '🚽', price: 0,   type: FurnitureType.toilet,   primary: Color(0xFFf3f1ff), light: Color(0xFFcbe7ff), dark: Color(0xFF6a7090)),
  FurnitureSkin(id: 'toilet_matte',    name: 'Matte Black', glyph: '⬛', price: 100, type: FurnitureType.toilet,   primary: Color(0xFF2a2a3a), light: Color(0xFF4a4a60), dark: Color(0xFF0e0e18)),
  FurnitureSkin(id: 'toilet_marble',   name: 'Marble',      glyph: '🪨', price: 140, type: FurnitureType.toilet,   primary: Color(0xFFede8de), light: Color(0xFFd9e6f0), dark: Color(0xFF5a4a3a)),

  // ── Mirror + sink (bathroom) ──────────────────────────────────
  // primary = frame, light = basin/water, dark = cabinet
  FurnitureSkin(id: 'mirror_default',  name: 'Warm Wood',   glyph: '🪞', price: 0,   type: FurnitureType.mirrorSink, primary: Color(0xFF5a3a1d), light: Color(0xFFcbe7ff), dark: Color(0xFF3a230f)),
  FurnitureSkin(id: 'mirror_brass',    name: 'Brass',       glyph: '✨', price: 90,  type: FurnitureType.mirrorSink, primary: Color(0xFFc9a64a), light: Color(0xFFf2e7c4), dark: Color(0xFF6e5020)),
  FurnitureSkin(id: 'mirror_chrome',   name: 'Chrome',      glyph: '🔩', price: 120, type: FurnitureType.mirrorSink, primary: Color(0xFFb8c0ca), light: Color(0xFFe2e8f0), dark: Color(0xFF4a525a)),
];

final kDefaultSkins = Map<FurnitureType, FurnitureSkin>.fromEntries(
  FurnitureType.values.map(
    (t) => MapEntry(t, kFurnitureSkins.firstWhere((s) => s.type == t && s.isFree)),
  ),
);

FurnitureSkin skinById(String id) =>
    kFurnitureSkins.firstWhere((s) => s.id == id,
        orElse: () => kDefaultSkins[FurnitureType.vacuum]!);
