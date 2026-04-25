enum QuestCategory {
  cleaning('🧹 Cleaning', 'Housekeeping & tidying'),
  groceries('🛒 Groceries', 'Shopping & food'),
  bills('📋 Bills', 'Payments & expenses'),
  upgrades('🏠 Upgrades', 'Home improvements');

  final String label;
  final String description;

  const QuestCategory(this.label, this.description);
}

class Quest {
  final String name;
  final int xpReward;
  final bool isCompleted;
  final QuestCategory category;
  // Marks the recurring "clean the room" quest — managed by timer, never persisted
  final bool isCleanRoomQuest;

  const Quest({
    required this.name,
    required this.xpReward,
    required this.category,
    this.isCompleted = false,
    this.isCleanRoomQuest = false,
  });

  Quest copyWith({
    String? name,
    int? xpReward,
    bool? isCompleted,
    QuestCategory? category,
    bool? isCleanRoomQuest,
  }) {
    return Quest(
      name: name ?? this.name,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      isCleanRoomQuest: isCleanRoomQuest ?? this.isCleanRoomQuest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'category': category.name,
      // isCleanRoomQuest intentionally omitted — injected fresh each session
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      name: json['name'] as String? ?? 'Unknown',
      xpReward: json['xpReward'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: QuestCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuestCategory.cleaning,
      ),
    );
  }
}
