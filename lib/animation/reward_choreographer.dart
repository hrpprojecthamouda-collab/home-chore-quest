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
  Future<void> playSequence({
    required int xpBefore,
    required int prevCoins,
    required int xpDelta,
    required int coinsOnQuest,
    required int coinsOnLevelUp,
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

      // 1. DONE feedback: quest complete sfx + Pip happiness reaction.
      sound.playSound(SoundType.questComplete);
      // Fire-and-forget so the reaction overlaps with subsequent steps.
      pip.reactHappy();
      // Let Pip's reaction breathe before moving on (~half its duration).
      await _wait(200);
      if (_cancelled) return;

      // 2. Coins gained on the quest itself (clean room): glow → tick-up.
      if (coinsOnQuest > 0) {
        coin.highlight();
        sound.playSound(SoundType.glowCue);
        await _wait(400);
        if (_cancelled) return;
        await coin.countTo(prevCoins + coinsOnQuest);
        if (_cancelled) return;
        sound.playSound(SoundType.coinFinale);
      }

      // 3. Brief pause before the XP step.
      await _wait(250);
      if (_cancelled) return;

      // 4. XP bar highlight glow.
      xp.highlight();
      sound.playSound(SoundType.glowCue);
      await _wait(400);
      if (_cancelled) return;

      // 5. XP fill segment 1: full delta if no level-up, else fill to 100%.
      final firstXp = levelUp ? xpToLvlEnd : xpDelta;
      final firstDur = _durFor(firstXp);
      final firstTargetPct = levelUp
          ? 1.0
          : ((xpInPrevLvl + xpDelta) / prevLvlMax).clamp(0.0, 1.0);
      // Fire sweep sound and bar fill simultaneously — playSound is async
      // internally so calling it before fillTo would delay it by one frame.
      sound.playSound(_sweepFor(firstDur));
      await xp.fillTo(
        firstTargetPct,
        duration: Duration(milliseconds: firstDur),
      );
      if (_cancelled) return;

      // No level-up → done.
      if (!levelUp) return;

      // 6. Brief pause.
      await _wait(250);
      if (_cancelled) return;

      // 7. Snap bar to 0% of the new level silently.
      xp.snapTo(0.0, newMax: newLvlMax);

      // 8. Coins gained from leveling up: glow → tick-up.
      if (coinsOnLevelUp > 0) {
        coin.highlight();
        sound.playSound(SoundType.glowCue);
        await _wait(400);
        if (_cancelled) return;
        await coin.countTo(prevCoins + coinsOnQuest + coinsOnLevelUp);
        if (_cancelled) return;
        sound.playSound(SoundType.coinFinale);
        await _wait(250);
        if (_cancelled) return;
      }

      // 9. XP fill segment 2: remaining XP into the new level.
      final restXp = xpDelta - xpToLvlEnd;
      if (restXp > 0) {
        final restDur = _durFor(restXp);
        sound.playSound(_sweepFor(restDur));
        final restPct = (restXp / newLvlMax).clamp(0.0, 1.0);
        await xp.fillTo(restPct, duration: Duration(milliseconds: restDur));
        if (_cancelled) return;
      }

      // 10. Level-up sound fires here — right before returning — so the caller
      //     pushes CelebrationScreen in sync with the sound cue.
      sound.playSound(SoundType.levelUp);
    } finally {
      coin.active = false;
      xp.active = false;
    }
  }

  Future<void> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  int _durFor(int xp) => (400 + xp * 8).clamp(600, 2000);

  /// Picks the stepped XP sweep that best matches a fill duration. Each
  /// sweep rises continuously over its baked length, so matching length
  /// keeps the audio rise synced with the bar.
  SoundType _sweepFor(int durMs) {
    if (durMs <= 450)  return SoundType.xpSweep300;
    if (durMs <= 800)  return SoundType.xpSweep600;
    if (durMs <= 1250) return SoundType.xpSweep1000;
    if (durMs <= 1750) return SoundType.xpSweep1500;
    return SoundType.xpSweep2000;
  }
}
