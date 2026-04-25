import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest.dart';
import '../services/sound_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class RoomCleanNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isRoomClean') ?? false;
  }

  void cleanRoom() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool('isRoomClean', true);
  }
}

final roomCleanProvider = NotifierProvider<RoomCleanNotifier, bool>(() {
  return RoomCleanNotifier();
});

class XpNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('xp') ?? 0;
  }

  void addXp(int amount) {
    state = state + amount;
    ref.read(sharedPreferencesProvider).setInt('xp', state);
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
    final prefs = ref.watch(sharedPreferencesProvider);
    final questsJson = prefs.getString('quests');
    
    if (questsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(questsJson);
        return decoded.map((json) => Quest.fromJson(json)).toList();
      } catch (e) {
        print('Error loading quests: $e');
      }
    }
    
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

  void _saveQuests() {
    final prefs = ref.read(sharedPreferencesProvider);
    final questsJson = jsonEncode(state.map((q) => q.toJson()).toList());
    prefs.setString('quests', questsJson);
  }

  void completeQuest(int index) {
    final updatedQuests = [...state];
    final currentQuest = updatedQuests[index];

    updatedQuests[index] = currentQuest.copyWith(isCompleted: true);
    state = updatedQuests;
    _saveQuests();
  }

  void addQuest(String name, int reward, QuestCategory category) {
    final newQuest = Quest(
      name: name,
      xpReward: reward,
      category: category,
    );
    state = [...state, newQuest];
    _saveQuests();
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
