import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest.dart';
import '../services/sound_service.dart';
import 'auth_providers.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class RoomCleanNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid  = ref.watch(currentUserIdProvider);
    final nextDue = prefs.getInt('${uid}_cleanRoomNextDue') ?? 0;
    // If the 48 h window has closed, room is messy regardless of stored flag
    if (nextDue > 0 && DateTime.now().millisecondsSinceEpoch >= nextDue) {
      return false;
    }
    return prefs.getBool('${uid}_isRoomClean') ?? false;
  }

  void cleanRoom() {
    final uid   = ref.read(currentUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final nextDue = DateTime.now()
        .add(const Duration(hours: 48))
        .millisecondsSinceEpoch;
    prefs.setInt('${uid}_cleanRoomNextDue', nextDue);
    prefs.setBool('${uid}_isRoomClean', true);
    state = true;
  }
}

final roomCleanProvider = NotifierProvider<RoomCleanNotifier, bool>(() {
  return RoomCleanNotifier();
});

class XpNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid  = ref.watch(currentUserIdProvider);
    return prefs.getInt('${uid}_xp') ?? 0;
  }

  void addXp(int amount) {
    final uid = ref.read(currentUserIdProvider);
    state = state + amount;
    ref.read(sharedPreferencesProvider).setInt('${uid}_xp', state);
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
  static const _cleanRoomQuest = Quest(
    name: '🏠 Deep Clean the Room',
    xpReward: 80,
    category: QuestCategory.cleaning,
    isCleanRoomQuest: true,
  );

  static const _defaultQuests = [
    Quest(name: 'Clean the Fridge',  xpReward: 50,  category: QuestCategory.cleaning),
    Quest(name: 'Take out Trash',    xpReward: 20,  category: QuestCategory.cleaning),
    Quest(name: 'Buy milk & bread',  xpReward: 30,  category: QuestCategory.groceries),
    Quest(name: 'Pay electric bill', xpReward: 40,  category: QuestCategory.bills),
    Quest(name: 'New couch',         xpReward: 150, category: QuestCategory.upgrades),
  ];

  @override
  List<Quest> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    final questsJson = prefs.getString('${uid}_quests');

    List<Quest> quests;
    if (questsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(questsJson);
        quests = decoded.map((json) => Quest.fromJson(json)).toList();
      } catch (e) {
        print('Error loading quests: $e');
        quests = List.of(_defaultQuests);
      }
    } else {
      quests = List.of(_defaultQuests);
    }

    // Inject the recurring clean-room quest when its 48 h window has elapsed
    final nextDue = prefs.getInt('${uid}_cleanRoomNextDue') ?? 0;
    final isDue = nextDue == 0 ||
        DateTime.now().millisecondsSinceEpoch >= nextDue;
    if (isDue) {
      quests = [_cleanRoomQuest, ...quests];
    }

    return quests;
  }

  void _saveQuests() {
    final uid   = ref.read(currentUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    // Never persist the clean-room quest — it is always injected fresh
    final questsJson = jsonEncode(
      state.where((q) => !q.isCleanRoomQuest).map((q) => q.toJson()).toList(),
    );
    prefs.setString('${uid}_quests', questsJson);
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
