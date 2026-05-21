import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animation/reward_choreographer.dart';
import '../data/clean_home_facts.dart';
import '../data/quest_catalog.dart';
import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../providers/inventory_providers.dart';
import '../screens/celebration_screen.dart';

/// Serialization lock — only one quest completion runs end-to-end at a
/// time. Without this, tapping DONE on a second quest while the first is
/// still animating would let both calls snapshot the same stale
/// xpProvider value, both compute the same `levelUp` transition, and
/// both push the celebration screen even though only one actual
/// level-up happened.
Future<void> _completionLock = Future.value();

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
}) {
  // Chain this completion onto any in-flight one. A second tap during
  // an active animation now waits for the previous call to finish
  // (including its XP write) before snapshotting state. Errors in
  // earlier completions are swallowed here so they don't break the
  // chain for subsequent quests.
  // ignore: use_build_context_synchronously
  final next = _completionLock.catchError((_) {}).then((_) =>
      _runQuestCompletionInner(
        ref: ref,
        choreographer: choreographer,
        // ignore: use_build_context_synchronously
        context: context,
        index: index,
        quest: quest,
      ));
  _completionLock = next;
  return next;
}

Future<void> _runQuestCompletionInner({
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
      // Fires the instant the XP bar reaches 100 %, alongside the
      // level-up sound — celebration arrives with the cue, not after the
      // whole sequence has unwound.
      onLevelUpCue: levelUp
          ? () {
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CelebrationScreen(level: newLvl),
              ));
            }
          : null,
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

  // ── Pip clean-home fact trigger ────────────────────────────────────────
  // Pip speaks every Nth completed quest (cumulative across all sessions),
  // no other gating. If the bubble lands on the same completion as a
  // level-up, the celebration screen plays first and the bubble appears
  // when the player returns to home — natural sequencing, no skip needed.
  ref.read(completedQuestCountProvider.notifier).increment();
  final completed = ref.read(completedQuestCountProvider);
  if (completed % kPipFactEveryNQuests == 0) {
    final idx = ref.read(factIndexProvider);
    final fact = kCleanHomeFacts[idx % kCleanHomeFacts.length].text;
    ref.read(factIndexProvider.notifier).advance();
    ref.read(pendingPipSpeechProvider.notifier).show(fact);
  }
}

/// Pip surfaces a clean-home fact every Nth completed quest.
const int kPipFactEveryNQuests = 3;
