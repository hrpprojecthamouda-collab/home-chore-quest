import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest.dart';

/// Service for persisting game data to device storage
class PersistenceService {
  late SharedPreferences _prefs;
  
  static const String _xpKey = 'player_xp';
  static const String _questsKey = 'game_quests';
  static const String _roomCleanKey = 'room_clean_status';

  /// Initialize the persistence service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save current XP to device storage
  Future<void> saveXp(int xp) async {
    await _prefs.setInt(_xpKey, xp);
  }

  /// Load saved XP from device storage
  int loadXp() {
    return _prefs.getInt(_xpKey) ?? 0;
  }

  /// Save room clean status
  Future<void> saveRoomCleanStatus(bool isClean) async {
    await _prefs.setBool(_roomCleanKey, isClean);
  }

  /// Load room clean status
  bool loadRoomCleanStatus() {
    return _prefs.getBool(_roomCleanKey) ?? false;
  }

  /// Clear all saved data
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  /// Save a single quest (for future expansion)
  Future<void> saveQuest(Quest quest, int index) async {
    final quests = _prefs.getStringList(_questsKey) ?? [];
    quests.add(quest.toString());
    await _prefs.setStringList(_questsKey, quests);
  }

  /// Load all quests (for future expansion)
  List<String> loadQuests() {
    return _prefs.getStringList(_questsKey) ?? [];
  }
}