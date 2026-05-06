import 'package:flutter/material.dart';

enum FurnitureType { vacuum, fridge, washer }

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
];

final kDefaultSkins = Map<FurnitureType, FurnitureSkin>.fromEntries(
  FurnitureType.values.map(
    (t) => MapEntry(t, kFurnitureSkins.firstWhere((s) => s.type == t && s.isFree)),
  ),
);

FurnitureSkin skinById(String id) =>
    kFurnitureSkins.firstWhere((s) => s.id == id,
        orElse: () => kDefaultSkins[FurnitureType.vacuum]!);
