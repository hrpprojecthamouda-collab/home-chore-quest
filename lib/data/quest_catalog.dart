// Catalog of suggested quests, organised by category and ranked easiest →
// hardest. The category screens use this to populate their suggestion
// sheets (the + button on each category opens a picker over this list).
//
// XP tiers map to the existing tier scheme used by the add-quest dialog:
//   • Tiny  = 5  XP →  0 coins
//   • Easy  = 10 XP →  2 coins
//   • Solid = 20 XP →  5 coins
//   • Boss  = 50 XP → 10 coins
//
// The clean-room special quest is NOT in this catalog — it lives in its
// own special-quest scheduler (50 coins on completion). Quests created via
// the quest-board free-form add are also not in this catalog.

import '../models/quest.dart';

/// One catalog entry — a suggested chore the user can tap to add to their
/// pending quest list.
class CatalogQuest {
  final String name;
  final int xpReward;
  final QuestCategory category;
  const CatalogQuest(this.name, this.xpReward, this.category);
}

/// Coins awarded on completion, derived from the quest's XP tier.
/// Returns 0 for the clean-room special tier (50 coins handled separately
/// in runQuestCompletion).
int coinsForTier(int xpReward) => switch (xpReward) {
      5 => 0,    // Tiny
      10 => 2,   // Easy
      20 => 5,   // Solid
      50 => 10,  // Boss
      _ => 0,    // Free-form / unknown tier — no coin reward by default
    };

/// Master suggestion catalog. Within each category, items are ranked
/// easiest (lowest XP) → hardest (highest XP).
const kQuestCatalog = <CatalogQuest>[
  // ── 🍳 Kitchen ─────────────────────────────────────────────────
  CatalogQuest('Take out the trash',           5,  QuestCategory.kitchen),
  CatalogQuest('Wash the dishes',              10, QuestCategory.kitchen),
  CatalogQuest('Restock pantry & groceries',   10, QuestCategory.kitchen),
  CatalogQuest('Wipe counters & stovetop',     20, QuestCategory.kitchen),
  CatalogQuest('Deep-clean the microwave & oven', 50, QuestCategory.kitchen),

  // ── 🧹 Living Areas ────────────────────────────────────────────
  CatalogQuest('Collect stray items & put them away', 5,  QuestCategory.livingAreas),
  CatalogQuest('Wipe surfaces (TV stand, tables)',    10, QuestCategory.livingAreas),
  CatalogQuest('Dust the furniture',                  10, QuestCategory.livingAreas),
  CatalogQuest('Vacuum / sweep the floors',           20, QuestCategory.livingAreas),

  // ── 🛁 Bathroom ────────────────────────────────────────────────
  CatalogQuest('Restock toiletries (soap, paper, etc.)', 5,  QuestCategory.bathroom),
  CatalogQuest('Replace & wash towels',                  10, QuestCategory.bathroom),
  CatalogQuest('Clean the sink & faucet',                20, QuestCategory.bathroom),

  // ── 🛏️ Bedroom ────────────────────────────────────────────────
  CatalogQuest('Make the bed',              5,  QuestCategory.bedroom),
  CatalogQuest('Tidy the nightstand',       5,  QuestCategory.bedroom),
  CatalogQuest('Organize the wardrobe',     20, QuestCategory.bedroom),
  CatalogQuest('Change sheets & pillowcases', 50, QuestCategory.bedroom),

  // ── 👕 Laundry ─────────────────────────────────────────────────
  CatalogQuest('Put folded clothes away',  10, QuestCategory.laundry),
  CatalogQuest('Wash, dry & fold',         20, QuestCategory.laundry),

  // ── 📋 Admin / Upkeep ─────────────────────────────────────────
  CatalogQuest('Restock household supplies',                       5,  QuestCategory.admin),
  CatalogQuest('Pay a bill',                                       10, QuestCategory.admin),
  CatalogQuest('Handle one admin task (appointment, paperwork, renewal)', 20, QuestCategory.admin),
  CatalogQuest('Weekly budget review',                             50, QuestCategory.admin),
];

/// Returns the suggestion list for [cat], ranked easiest → hardest.
/// The catalog is already pre-sorted; this is a simple filter.
List<CatalogQuest> catalogFor(QuestCategory cat) =>
    kQuestCatalog.where((q) => q.category == cat).toList();
