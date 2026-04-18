import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../services/persistence_service.dart';
import '../services/sound_service.dart';

// Persistence service provider
final persistenceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

class RoomCleanNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void cleanRoom() {
    state = true;
    // Save to device storage
    ref.read(persistenceProvider).saveRoomCleanStatus(true);
  }
}

final roomCleanProvider = NotifierProvider<RoomCleanNotifier, bool>(() {
  return RoomCleanNotifier();
});

class XpNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void addXp(int amount) {
    state = state + amount;
    // Save to device storage
    ref.read(persistenceProvider).saveXp(state);
  }
}

final xpProvider = NotifierProvider<XpNotifier, int>(() {
  return XpNotifier();
});

const int xpPerLevel = 100;

final levelProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return (xp ~/ xpPerLevel) + 1;
});

final xpProgressProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return xp % xpPerLevel;
});

final xpToNextLevelProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return xpPerLevel - (xp % xpPerLevel);
});

class QuestListNotifier extends Notifier<List<Quest>> {
  @override
  List<Quest> build() {
    return const [
      Quest(
        name: 'Clean the Fridge',
        xpReward: 50,
        category: QuestCategory.cleaning,
      ),
      Quest(
        name: 'Take out Trash',
        xpReward: 20,
        category: QuestCategory.cleaning,
      ),
      Quest(
        name: 'Buy milk & bread',
        xpReward: 30,
        category: QuestCategory.groceries,
      ),
      Quest(
        name: 'Pay electric bill',
        xpReward: 40,
        category: QuestCategory.bills,
      ),
      Quest(
        name: 'New couch',
        xpReward: 150,
        category: QuestCategory.upgrades,
      ),
    ];
  }

  void completeQuest(int index) {
    final updatedQuests = [...state];
    final currentQuest = updatedQuests[index];

    updatedQuests[index] = currentQuest.copyWith(isCompleted: true);
    state = updatedQuests;
  }

  void addQuest(String name, int reward, QuestCategory category) {
    final newQuest = Quest(
      name: name,
      xpReward: reward,
      category: category,
    );
    state = [...state, newQuest];
  }
}

final questListProvider = NotifierProvider<QuestListNotifier, List<Quest>>(() {
  return QuestListNotifier();
});

final pendingQuestCountProvider = Provider<int>((ref) {
  final quests = ref.watch(questListProvider);
  return quests.where((quest) => !quest.isCompleted).length;
});

final questsByCategory = Provider.family<List<Quest>, QuestCategory>((ref, category) {
  final quests = ref.watch(questListProvider);
  return quests.where((quest) => quest.category == category).toList();
});

final pendingQuestsByCategory = Provider.family<List<Quest>, QuestCategory>((ref, category) {
  final quests = ref.watch(questsByCategory(category));
  return quests.where((quest) => !quest.isCompleted).toList();
});

final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
});
