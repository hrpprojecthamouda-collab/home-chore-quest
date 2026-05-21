import 'dart:math' as math;

enum QuestCategory {
  // Living-area cleaning — broom, vacuum, dust, sweep. Renamed from
  // `cleaning` to disambiguate from bathroom cleaning. Old persisted data
  // with category "cleaning" is migrated in Quest.fromJson below.
  livingAreas('🧹 Living Areas', 'Broom, vacuum, dust & sweep'),
  // Renamed from `groceries` — covers fridge + sink + dishes + cooking +
  // meal planning. Lives in the living room. Old persisted data with
  // category "groceries" is migrated below.
  kitchen('🍳 Kitchen', 'Cooking, dishes & food'),
  // Renamed from `bills` — covers paying bills, sorting paperwork,
  // scheduling appointments, budgeting. Lives in the bedroom (desk).
  // Old persisted data still uses the literal name "bills"; migrated below.
  admin('📋 Admin', 'Bills, paperwork & appointments'),
  laundry('👕 Laundry', 'Washing & clothes'),
  // Bathroom-specific cleaning — toilet, sink, tub, towels, toiletries.
  bathroom('🛁 Bathroom', 'Toilet, sink & tub'),
  // Bedroom — making the bed, sheets, wardrobe.
  bedroom('🛏️ Bedroom', 'Bed & wardrobe');

  final String label;
  final String description;

  const QuestCategory(this.label, this.description);
}

class Quest {
  final String id;   // stable unique key — used by Dismissible
  final String name;
  final int xpReward;
  final bool isCompleted;
  final bool isOngoing;   // DO IT tapped, waiting for DONE! confirmation
  final QuestCategory category;
  // Marks the recurring "clean the room" quest — managed by timer, never persisted
  final bool isCleanRoomQuest;

  const Quest({
    this.id = '',    // empty only for compile-time const declarations
    required this.name,
    required this.xpReward,
    required this.category,
    this.isCompleted = false,
    this.isOngoing = false,
    this.isCleanRoomQuest = false,
  });

  static String newId() {
    final r = math.Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(0xFFFF).toRadixString(16)}';
  }

  Quest copyWith({
    String? id,
    String? name,
    int? xpReward,
    bool? isCompleted,
    bool? isOngoing,
    QuestCategory? category,
    bool? isCleanRoomQuest,
  }) {
    return Quest(
      id: id ?? this.id,
      name: name ?? this.name,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      isOngoing: isOngoing ?? this.isOngoing,
      category: category ?? this.category,
      isCleanRoomQuest: isCleanRoomQuest ?? this.isCleanRoomQuest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'isOngoing': isOngoing,
      'category': category.name,
      // isCleanRoomQuest intentionally omitted — injected fresh each session
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    final savedId = json['id'] as String? ?? '';
    // Migrate old enum names so existing user data doesn't fall back to
    // the orElse arm:
    //   "bills"     → "admin"
    //   "groceries" → "kitchen"
    //   "cleaning"  → "livingAreas"
    final rawCategory = json['category'] as String?;
    final categoryName = switch (rawCategory) {
      'bills' => 'admin',
      'groceries' => 'kitchen',
      'cleaning' => 'livingAreas',
      _ => rawCategory,
    };
    return Quest(
      id: savedId.isNotEmpty ? savedId : Quest.newId(),
      name: json['name'] as String? ?? 'Unknown',
      xpReward: json['xpReward'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isOngoing: json['isOngoing'] as bool? ?? false,
      category: QuestCategory.values.firstWhere(
        (e) => e.name == categoryName,
        orElse: () => QuestCategory.livingAreas,
      ),
    );
  }
}
