import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_providers.dart';
import 'auth_providers.dart';

// ── Coin balance ───────────────────────────────────────────────

class CoinNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    return prefs.getInt('${uid}_coins') ?? 0;
  }

  void _persist() {
    final uid = ref.read(currentUserIdProvider);
    ref.read(sharedPreferencesProvider).setInt('${uid}_coins', state);
  }

  void addCoins(int amount) {
    state = state + amount;
    _persist();
  }

  bool spend(int amount) {
    if (state < amount) return false;
    state = state - amount;
    _persist();
    return true;
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(CoinNotifier.new);

// ── Owned item IDs ─────────────────────────────────────────────
// Nothing is owned by default — players buy everything from the shop
const _defaultOwned = <String>{'none'};

class InventoryNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    final json  = prefs.getString('${uid}_ownedItems');
    if (json == null) return Set.of(_defaultOwned);
    try {
      return Set<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return Set.of(_defaultOwned);
    }
  }

  void _persist() {
    final uid = ref.read(currentUserIdProvider);
    ref.read(sharedPreferencesProvider).setString(
      '${uid}_ownedItems',
      jsonEncode(state.toList()),
    );
  }

  void addItem(String itemId) {
    state = {...state, itemId};
    _persist();
  }

  bool owns(String itemId) => state.contains(itemId);
}

final inventoryProvider = NotifierProvider<InventoryNotifier, Set<String>>(
  InventoryNotifier.new,
);

// ── Equipped Pip accessories ────────────────────────────────────

const _defaultEquippedPip = <String, String>{
  'hat':     'none',
  'costume': 'none',
};

class EquippedPipNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    final json  = prefs.getString('${uid}_equippedPip');
    if (json == null) return Map.of(_defaultEquippedPip);
    try {
      // Migrate legacy face/neck/hand saves: keep hat if present, drop the rest.
      final loaded = Map<String, String>.from(jsonDecode(json) as Map);
      return {
        'hat':     loaded['hat']     ?? 'none',
        'costume': loaded['costume'] ?? 'none',
      };
    } catch (_) {
      return Map.of(_defaultEquippedPip);
    }
  }

  void _persist() {
    final uid = ref.read(currentUserIdProvider);
    ref.read(sharedPreferencesProvider).setString(
      '${uid}_equippedPip',
      jsonEncode(state),
    );
  }

  void equip(String slot, String itemId) {
    state = {...state, slot: itemId};
    _persist();
  }

  void resetAll() {
    state = Map.of(_defaultEquippedPip);
    _persist();
  }
}

final equippedPipProvider = NotifierProvider<EquippedPipNotifier, Map<String, String>>(
  EquippedPipNotifier.new,
);

// ── Equipped room slots ────────────────────────────────────────

const _defaultEquippedRoom = <String, String>{
  'wall_left':    'none',
  'wall_center':  'none',
  'wall_right':   'none',
  'floor_left':   'none',
  'floor_center': 'none',
  'floor_right':  'none',
};

class EquippedRoomNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    final json  = prefs.getString('${uid}_equippedRoom');
    if (json == null) return Map.of(_defaultEquippedRoom);
    try {
      return Map<String, String>.from(jsonDecode(json) as Map);
    } catch (_) {
      return Map.of(_defaultEquippedRoom);
    }
  }

  void _persist() {
    final uid = ref.read(currentUserIdProvider);
    ref.read(sharedPreferencesProvider).setString(
      '${uid}_equippedRoom',
      jsonEncode(state),
    );
  }

  void placeInSlot(String slotId, String itemId) {
    state = {...state, slotId: itemId};
    _persist();
  }

  void reset() {
    state = {
      'wall_left':    'none',
      'wall_center':  'none',
      'wall_right':   'none',
      'floor_left':   'none',
      'floor_center': 'none',
      'floor_right':  'none',
    };
    _persist();
  }
}

final equippedRoomProvider = NotifierProvider<EquippedRoomNotifier, Map<String, String>>(
  EquippedRoomNotifier.new,
);
