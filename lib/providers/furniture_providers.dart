import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture_skin.dart';
import 'auth_providers.dart';
import 'game_providers.dart';

class EquippedFurnitureNotifier
    extends Notifier<Map<FurnitureType, String>> {
  static String _key(String uid, FurnitureType t) => '${uid}_fur_${t.name}';

  @override
  Map<FurnitureType, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid   = ref.watch(currentUserIdProvider);
    return {
      for (final t in FurnitureType.values)
        t: prefs.getString(_key(uid, t)) ?? kDefaultSkins[t]!.id,
    };
  }

  void equip(FurnitureType type, String skinId) {
    final prefs = ref.read(sharedPreferencesProvider);
    final uid   = ref.read(currentUserIdProvider);
    prefs.setString(_key(uid, type), skinId);
    state = {...state, type: skinId};
  }
}

final equippedFurnitureProvider =
    NotifierProvider<EquippedFurnitureNotifier, Map<FurnitureType, String>>(
  EquippedFurnitureNotifier.new,
);

final resolvedFurnitureSkinsProvider =
    Provider<Map<FurnitureType, FurnitureSkin>>((ref) {
  final equipped = ref.watch(equippedFurnitureProvider);
  return {for (final e in equipped.entries) e.key: skinById(e.value)};
});
