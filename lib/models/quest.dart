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

  const Quest({
    required this.name,
    required this.xpReward,
    required this.category,
    this.isCompleted = false,
  });

  Quest copyWith({
    String? name,
    int? xpReward,
    bool? isCompleted,
    QuestCategory? category,
  }) {
    return Quest(
      name: name ?? this.name,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }
}
