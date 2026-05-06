import 'dart:math' as math;

enum QuestCategory {
  cleaning('🧹 Cleaning', 'Housekeeping & tidying'),
  groceries('🛒 Groceries', 'Shopping & food'),
  bills('📋 Bills', 'Payments & expenses'),
  laundry('👕 Laundry', 'Washing & clothes');

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
    return Quest(
      id: savedId.isNotEmpty ? savedId : Quest.newId(),
      name: json['name'] as String? ?? 'Unknown',
      xpReward: json['xpReward'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isOngoing: json['isOngoing'] as bool? ?? false,
      category: QuestCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuestCategory.cleaning,
      ),
    );
  }
}
