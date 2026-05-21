import 'package:flutter/foundation.dart';

import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import 'reward_controllers.dart';

/// Sequences the quest-reward animation across Pip / coin chip / XP bar.
///
/// Lifecycle: instantiated by a screen in initState, [cancel] called in
/// dispose. The screen is responsible for applying the actual XP/coin
/// state changes to providers AFTER awaiting [playSequence] (so the bar
/// and counter are already at the right display values when providers
/// catch up).
class RewardChoreographer {
  final PipController pip;
  final CoinChipController coin;
  final XpBarController xp;
  final SoundService sound;

  bool _cancelled = false;

  RewardChoreographer({
    required this.pip,
    required this.coin,
    required this.xp,
    required this.sound,
  });

  void cancel() {
    _cancelled = true;
  }

  /// Plays the full reward sequence. Returns when finished or cancelled.
  ///
  /// Inputs are pre-computed by the caller from the quest + provider state
  /// at completion time. The choreographer does NOT mutate providers; it
  /// drives the controllers and plays sounds.
  ///
  /// [onLevelUpCue] is invoked the instant the XP bar reaches 100 %, in
  /// sync with the level-up sound. The caller uses it to push the
  /// CelebrationScreen so the animation appears with the sound cue rather
  /// than after the whole sequence finishes.
  Future<void> playSequence({
    required int xpBefore,
    required int prevCoins,
    required int xpDelta,
    required int coinsOnQuest,
    required int coinsOnLevelUp,
    VoidCallback? onLevelUpCue,
  }) async {
    // Activate controllers so their auto-react paths snap silently when the
    // caller writes to providers afterwards.
    coin.active = true;
    xp.active = true;

    try {
      final prevLvl = levelFromXp(xpBefore);
      final prevLvlMax = xpForLevel(prevLvl);
      final prevLvlStart = xpThreshold(prevLvl);
      final xpInPrevLvl = xpBefore - prevLvlStart;
      final xpToLvlEnd = prevLvlMax - xpInPrevLvl;
      final levelUp = xpDelta >= xpToLvlEnd;
      final newLvl = levelFromXp(xpBefore + xpDelta);
      final newLvlMax = xpForLevel(newLvl);
      final totalCoins = coinsOnQuest + coinsOnLevelUp;

      // 1. DONE feedback: quest complete sfx + Pip happiness reaction.
      sound.playSound(SoundType.questComplete);
      // Fire-and-forget so the reaction overlaps with subsequent steps.
      pip.reactHappy();
      // Let Pip's reaction breathe before moving on (~half its duration).
      await _wait(200);
      if (_cancelled) return;

      // 2. XP bar highlight glow — leads straight into the fill.
      xp.highlight();
      sound.playSound(SoundType.glowCue);
      await _wait(200);
      if (_cancelled) return;

      // 3. XP fill segment 1: full delta if no level-up, else fill to 100 %.
      //    Visual only — no sweep sound (the bar's visual fill carries it).
      final firstXp = levelUp ? xpToLvlEnd : xpDelta;
      final firstDur = _durFor(firstXp);
      final firstTargetPct = levelUp
          ? 1.0
          : ((xpInPrevLvl + xpDelta) / prevLvlMax).clamp(0.0, 1.0);
      await xp.fillTo(
        firstTargetPct,
        duration: Duration(milliseconds: firstDur),
      );
      if (_cancelled) return;

      // 4. Level-up branch — segment 1 just landed on 100 %. Fire the
      //    level-up sound AND the caller's CelebrationScreen push at the
      //    same instant so the animation arrives with the audio cue.
      //    Then snap the bar to 0 % of the new level and continue.
      if (levelUp) {
        sound.playSound(SoundType.levelUp);
        onLevelUpCue?.call();
        await _wait(350);
        if (_cancelled) return;
        xp.snapTo(0.0, newMax: newLvlMax);

        final restXp = xpDelta - xpToLvlEnd;
        if (restXp > 0) {
          final restDur = _durFor(restXp);
          final restPct = (restXp / newLvlMax).clamp(0.0, 1.0);
          await xp.fillTo(restPct, duration: Duration(milliseconds: restDur));
          if (_cancelled) return;
        }
      }

      // 5. Coins are the FINAL beat — single combined tick-up that includes
      //    both the quest coins and (if there was a level-up) the level-up
      //    bonus. Glow halo and tick-up start at the same moment — the
      //    glow plays as a visual cue underneath the running count, and the
      //    per-tick coin sounds are scheduled across the same duration as
      //    the number animation (see AnimatedCoinCounter._animateTo), so
      //    audio and visual ticks line up. No closing chime — the last
      //    per-tick coin sound is the natural ending.
      if (totalCoins > 0) {
        await _wait(250);
        if (_cancelled) return;
        coin.highlight();
        await coin.countTo(prevCoins + totalCoins);
        if (_cancelled) return;
      }
    } finally {
      coin.active = false;
      xp.active = false;
    }
  }

  Future<void> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  int _durFor(int xp) => (400 + xp * 8).clamp(600, 2000);
}
