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

/// Cumulative XP required to *reach* [level] (level 1 starts at 0).
/// Formula: 50 × n × (n-1)  →  L1=0, L2=100, L3=300, L4=600, L5=1000 …
int xpThreshold(int level) => 50 * level * (level - 1);

/// XP needed to complete level [level] (i.e. to advance to the next one).
/// Equals 100 × level: L1 needs 100, L2 needs 200, L3 needs 300 …
int xpForLevel(int level) => 100 * level;

/// Derive the current level from a raw [xp] total.
int levelFromXp(int xp) {
  var n = 1;
  while (xpThreshold(n + 1) <= xp) n++;
  return n;
}

final levelProvider = Provider<int>((ref) {
  return levelFromXp(ref.watch(xpProvider));
});

final xpProgressProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return xp - xpThreshold(levelFromXp(xp));
});

final xpToNextLevelProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return xpThreshold(levelFromXp(xp) + 1) - xp;
});

class QuestListNotifier extends Notifier<List<Quest>> {
  static const _cleanRoomQuest = Quest(
    name: '🏠 Deep Clean the Room',
    xpReward: 80,
    category: QuestCategory.livingAreas,
    isCleanRoomQuest: true,
  );

  static const _defaultQuests = [
    Quest(name: 'Clean the Fridge',  xpReward: 50,  category: QuestCategory.livingAreas),
    Quest(name: 'Take out Trash',    xpReward: 20,  category: QuestCategory.livingAreas),
    Quest(name: 'Buy milk & bread',  xpReward: 30,  category: QuestCategory.kitchen),
    Quest(name: 'Pay electric bill', xpReward: 40,  category: QuestCategory.admin),
    Quest(name: 'Do the laundry',    xpReward: 150, category: QuestCategory.laundry),
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

    // Ensure every quest has a stable ID (covers defaults and legacy saved data).
    quests = [for (final q in quests) q.id.isEmpty ? q.copyWith(id: Quest.newId()) : q];

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

  void startQuest(int index) {
    final updated = List.of(state);
    updated[index] = updated[index].copyWith(isOngoing: true);
    state = updated;
    _saveQuests();
  }

  void cancelQuest(int index) {
    final updated = List.of(state);
    updated[index] = updated[index].copyWith(isOngoing: false);
    state = updated;
    _saveQuests();
  }

  void completeQuest(int index) {
    // Quests vanish on completion — no in-list "history" view. (A future
    // profile screen may surface a long-term history; that will draw from
    // a separate event log, not from this active-quest list.)
    final updated = List.of(state);
    updated.removeAt(index);
    state = updated;
    _saveQuests();
  }

  void addQuest(String name, int reward, QuestCategory category) {
    state = [...state, Quest(id: Quest.newId(), name: name, xpReward: reward, category: category)];
    _saveQuests();
  }

  void editQuest(int index, String name, int xpReward, QuestCategory category) {
    final updated = List.of(state);
    updated[index] = updated[index].copyWith(
      name: name,
      xpReward: xpReward,
      category: category,
    );
    state = updated;
    _saveQuests();
  }

  void deleteQuest(int index) {
    final updated = List.of(state);
    updated.removeAt(index);
    state = updated;
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
  final prefs = ref.read(sharedPreferencesProvider);
  final service = SoundService(AudioSettings(
    musicVolume: prefs.getDouble(AudioSettings.kMusicVol) ?? 1.0,
    sfxVolume:   prefs.getDouble(AudioSettings.kSfxVol)   ?? 1.0,
    musicMuted:  prefs.getBool(AudioSettings.kMusicMute)  ?? false,
    sfxMuted:    prefs.getBool(AudioSettings.kSfxMute)    ?? false,
  ));
  ref.onDispose(service.dispose);
  return service;
});

// ─── Login streak ──────────────────────────────────────────────
class LoginStreakNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    if (uid == 'anonymous') return 0;

    final stored   = prefs.getInt('${uid}_loginStreak') ?? 0;
    final storedDay = prefs.getString('${uid}_lastLoginDay');
    final today     = _dayStr(DateTime.now());

    if (storedDay == today) return stored.clamp(1, 9999);

    // Compute what streak WILL be after today's login is recorded
    final yesterday = _dayStr(DateTime.now().subtract(const Duration(days: 1)));
    return storedDay == yesterday ? stored + 1 : 1;
  }

  /// Persist today's login. Call once when the welcome flow is shown.
  void recordLogin() {
    final prefs = ref.read(sharedPreferencesProvider);
    final uid   = ref.read(currentUserIdProvider);
    if (uid == 'anonymous') return;

    final today  = _dayStr(DateTime.now());
    final dayKey = '${uid}_lastLoginDay';
    if (prefs.getString(dayKey) == today) return; // already recorded

    prefs.setString(dayKey, today);
    prefs.setInt('${uid}_loginStreak', state);
  }

  static String _dayStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final loginStreakProvider = NotifierProvider<LoginStreakNotifier, int>(
  LoginStreakNotifier.new,
);

// ─── Clean-home facts (Pip speech bubble) ─────────────────────────────────
//
// `factIndexProvider` is a rolling pointer into `kCleanHomeFacts` — every
// time Pip speaks, it advances by 1 (wrapping at the catalog's length).
// `lastFactLevelProvider` records the player's level the LAST time Pip
// spoke; the trigger in runQuestCompletion only fires when the current
// level is different from that record (so Pip speaks once per level
// transition, plus once for a brand-new account where it's still -1).

class FactIndexNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    return prefs.getInt('${uid}_factIndex') ?? 0;
  }

  void advance() {
    final uid = ref.read(currentUserIdProvider);
    state = state + 1;
    ref.read(sharedPreferencesProvider).setInt('${uid}_factIndex', state);
  }
}

final factIndexProvider = NotifierProvider<FactIndexNotifier, int>(
  FactIndexNotifier.new,
);

/// Cumulative count of quests the user has ever completed. Drives Pip's
/// fact-dialogue cadence — she speaks every Nth quest (see
/// `kPipFactEveryNQuests` in runQuestCompletion). Persisted per-user so
/// the cadence survives app restarts.
class CompletedQuestCountNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    return prefs.getInt('${uid}_completedQuestCount') ?? 0;
  }

  void increment() {
    final uid = ref.read(currentUserIdProvider);
    state = state + 1;
    ref.read(sharedPreferencesProvider)
        .setInt('${uid}_completedQuestCount', state);
  }
}

final completedQuestCountProvider =
    NotifierProvider<CompletedQuestCountNotifier, int>(
  CompletedQuestCountNotifier.new,
);

/// Holds the next fact string Pip should display. The home screen watches
/// this; setting it to a non-null value makes the speech bubble appear,
/// setting it back to null tears it down. Transient (not persisted) —
/// it's purely a UI hand-off from runQuestCompletion to the home stack.
class PendingPipSpeechNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void show(String fact) => state = fact;
  void clear() => state = null;
}

final pendingPipSpeechProvider =
    NotifierProvider<PendingPipSpeechNotifier, String?>(
  PendingPipSpeechNotifier.new,
);
