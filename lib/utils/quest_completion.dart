import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animation/reward_choreographer.dart';
import '../data/quest_catalog.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../screens/celebration_screen.dart';

/// Shared quest-completion flow.
///
/// 1. Snapshots pre-completion state (XP, coins, level).
/// 2. Marks the quest done so the list updates immediately.
/// 3. Awaits the choreographer's reward sequence.
/// 4. Writes the actual XP/coin gains to providers (widgets snap silently
///    because they were already at the right display values).
/// 5. Pushes [CelebrationScreen] if a level-up occurred.
Future<void> runQuestCompletion({
  required WidgetRef ref,
  required RewardChoreographer choreographer,
  required BuildContext context,
  required int index,
  required Quest quest,
}) async {
  final xpBefore     = ref.read(xpProvider);
  final prevCoins    = ref.read(coinProvider);
  // Clean-room special quest keeps its 50-coin bounty.
  // All other quests pay coins based on their XP tier (catalog suggestions
  // map to 0/2/5/10 coins for Tiny/Easy/Solid/Boss). Free-form quests with
  // arbitrary XP fall back to 0.
  final coinsOnQuest = quest.isCleanRoomQuest ? 50 : coinsForTier(quest.xpReward);
  final delta        = quest.xpReward;
  final prevLvl      = levelFromXp(xpBefore);
  final newLvl       = levelFromXp(xpBefore + delta);
  final levelUp      = newLvl > prevLvl;
  final coinsOnLevelUp = levelUp ? 50 : 0;

  // Apply quest-list / room state up-front so the UI reflects completion
  // immediately (the quest card flips to "done" while reward plays).
  ref.read(questListProvider.notifier).completeQuest(index);
  if (quest.isCleanRoomQuest) ref.read(roomCleanProvider.notifier).cleanRoom();

  try {
    await choreographer.playSequence(
      xpBefore: xpBefore,
      prevCoins: prevCoins,
      xpDelta: delta,
      coinsOnQuest: coinsOnQuest,
      coinsOnLevelUp: coinsOnLevelUp,
    );
  } catch (_) {
    // Even if the choreography hits an error mid-sequence, ensure XP/coin
    // state is still applied so the user doesn't lose progress.
  }

  // Apply state regardless of context state — these are pure provider
  // writes, no widget tree access required. Widgets are at the right
  // display values; their auto-react listeners are gated off (the bar
  // and counter in imperative mode snap on prop change anyway).
  ref.read(xpProvider.notifier).addXp(delta);
  ref.read(coinProvider.notifier).addCoins(coinsOnQuest + coinsOnLevelUp);

  if (levelUp && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CelebrationScreen(level: newLvl),
    ));
  }
}
