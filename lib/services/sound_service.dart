import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AudioSettings {
  static const kMusicVol  = 'audio_musicVolume';
  static const kSfxVol    = 'audio_sfxVolume';
  static const kMusicMute = 'audio_musicMuted';
  static const kSfxMute   = 'audio_sfxMuted';

  final double musicVolume;
  final double sfxVolume;
  final bool   musicMuted;
  final bool   sfxMuted;

  const AudioSettings({
    this.musicVolume = 1.0,
    this.sfxVolume   = 1.0,
    this.musicMuted  = false,
    this.sfxMuted    = false,
  });

  AudioSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool?   musicMuted,
    bool?   sfxMuted,
  }) => AudioSettings(
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume:   sfxVolume   ?? this.sfxVolume,
    musicMuted:  musicMuted  ?? this.musicMuted,
    sfxMuted:    sfxMuted    ?? this.sfxMuted,
  );
}

enum SoundType {
  // navTap randomly picks left/center/right for natural variety
  navTap,
  navTapLeft,
  navTapCenter,
  navTapRight,
  buttonPress,
  questComplete,
  levelUp,
  purchaseSuccess,
  saveConfirm,
  actionError,
  shopTabSwitch,
  itemSwitchTick,    // debounced
  tabSwitchCustomize,
  questDisplay,
  questEdit,
  addQuest,
  ongoingQuest,    // played when "DO IT" is tapped
  awesome,         // played on "Awesome!" / streak confirmation
  // Menu-open category sounds — all trigger ducking from the caller
  menuCleaning,
  menuGroceries,
  menuBills,
  menuLaundry,
  sonicLogo,
}

enum MusicTrack { lobby }

class SoundService with WidgetsBindingObserver {
  final AudioPlayer _sfx  = AudioPlayer();
  final AudioPlayer _bg   = AudioPlayer();
  final AudioPlayer _logo = AudioPlayer();

  // dB-to-linear conversion
  static double _db(double db) => math.pow(10, db / 20).toDouble();

  static final double _lvlNavTap    = _db(-18);
  static final double _lvlButton    = _db(-15);
  static final double _lvlConfirm   = _db(-12);
  static final double _lvlLevelUp   = _db(-6);
  static final double _lvlMenuOpen    = _db(-12);
  static final double _lvlMenuOpenLow = _db(-18); // half amplitude of _lvlMenuOpen
  static final double _lvlMusicFull = _db(-6);  // ~50% — audible base level

  AudioSettings _settings  = const AudioSettings();
  bool   _bgActive         = false;
  int    _duckCounter      = 0;
  double _currentBgVol     = 0.0;
  bool   _appPaused        = false;
  bool   _sonicLogoDone    = false;
  Timer? _fadeTimer;
  Timer? _debounce;

  SoundService([AudioSettings? initialSettings]) {
    if (initialSettings != null) _settings = initialSettings;
    _sfx.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── Settings ────────────────────────────────────────────────

  void applySettings(AudioSettings settings) {
    final wasMuted = _settings.musicMuted;
    _settings = settings;
    if (!_bgActive) return;
    if (!wasMuted && settings.musicMuted) {
      _fadeBg(0.0, 700);
    } else if (wasMuted && !settings.musicMuted) {
      _fadeBg(_targetMusicVol(), 800);
    } else {
      _fadeTimer?.cancel();
      final t = _targetMusicVol();
      _currentBgVol = t;
      _bg.setVolume(t);
    }
  }

  double _targetMusicVol() {
    if (_settings.musicMuted) return 0.0;
    final base = _settings.musicVolume * _lvlMusicFull;
    return _duckCounter > 0 ? base * 0.30 : base; // duck to 30% of full
  }

  // ─── App lifecycle ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_bgActive && !_appPaused) {
          _appPaused = true;
          _bg.pause();
        }
      case AppLifecycleState.resumed:
        if (_bgActive && _appPaused) {
          _appPaused = false;
          _bg.resume();
        }
      default:
    }
  }

  // ─── Music ───────────────────────────────────────────────────

  Future<void> playMusicTrack(MusicTrack track) async {
    final file = switch (track) {
      MusicTrack.lobby => 'main_menu_theme.mp3',
    };
    _bgActive     = true;
    _appPaused    = false;
    _duckCounter  = 0;
    _currentBgVol = 0.0;
    await _bg.setVolume(0.0);
    await _bg.setReleaseMode(ReleaseMode.loop);
    await _bg.play(AssetSource('audio/$file'));
    _fadeBg(_targetMusicVol(), 1200);
  }

  Future<void> stopMusic({bool fade = true}) async {
    _bgActive = false;
    if (fade) {
      _fadeBg(0.0, 700, onComplete: () => _bg.stop());
    } else {
      _fadeTimer?.cancel();
      _currentBgVol = 0.0;
      await _bg.stop();
    }
  }

  /// Plays the sonic logo once per session, then starts the music track.
  /// Falls back to music immediately if the asset is missing or fails.
  Future<void> playSonicLogoThenMusic(MusicTrack track) async {
    if (_sonicLogoDone) {
      await playMusicTrack(track);
      return;
    }
    _sonicLogoDone = true;

    // Probe the asset bundle first — if the file isn't bundled, skip straight
    // to music. This prevents the player from hanging with no completion event.
    bool hasLogo = false;
    try {
      await rootBundle.load('assets/audio/sonic_logo.mp3');
      hasLogo = true;
    } catch (_) {}

    if (!hasLogo) {
      await playMusicTrack(track);
      return;
    }

    try {
      await _logo.play(AssetSource('audio/sonic_logo.mp3'));
      _logo.onPlayerComplete.first.then((_) => playMusicTrack(track));
    } catch (_) {
      await playMusicTrack(track);
    }
  }

  // ─── Duck / Unduck ───────────────────────────────────────────

  /// Call when entering a category screen. Counter-based so nested menus
  /// don't double-duck or unduck prematurely.
  void duck() {
    _duckCounter++;
    if (_bgActive && _duckCounter == 1) _fadeBg(_targetMusicVol(), 250);
  }

  /// Call when leaving a category screen.
  void unduck() {
    if (_duckCounter > 0) _duckCounter--;
    if (_bgActive && _duckCounter == 0) _fadeBg(_targetMusicVol(), 400);
  }

  // ─── SFX ─────────────────────────────────────────────────────

  static const _kNavTapVariants = [
    SoundType.navTapLeft,
    SoundType.navTapCenter,
    SoundType.navTapRight,
  ];
  static const _kDebounced = {
    SoundType.navTapLeft,
    SoundType.navTapCenter,
    SoundType.navTapRight,
    SoundType.buttonPress,
    SoundType.itemSwitchTick,
  };

  Future<void> playSound(SoundType type) async {
    if (_settings.sfxMuted) return;

    // navTap randomly picks a positional variant for natural variety
    final t = type == SoundType.navTap
        ? _kNavTapVariants[math.Random().nextInt(3)]
        : type;

    final (file, lvl) = _sfxAsset(t);
    if (file == null) return;

    // Anti-spam debounce for quick repetitive UI sounds
    if (_kDebounced.contains(t)) {
      if (_debounce?.isActive ?? false) return;
      _debounce = Timer(
        Duration(milliseconds: t == SoundType.itemSwitchTick ? 80 : 50),
        () {},
      );
    }

    final vol = (_settings.sfxVolume * lvl).clamp(0.0, 1.0);
    await _sfx.stop();
    await _sfx.setVolume(vol);
    await _sfx.play(AssetSource('audio/$file'));
  }

  (String?, double) _sfxAsset(SoundType type) => switch (type) {
    SoundType.navTap             => (null,                         _lvlNavTap),
    SoundType.navTapLeft         => ('nav_tap_left.wav',           _lvlNavTap),
    SoundType.navTapCenter       => ('nav_tap_center.wav',         _lvlNavTap),
    SoundType.navTapRight        => ('nav_tap_right.wav',          _lvlNavTap),
    SoundType.buttonPress        => ('button_press.wav',           _lvlButton),
    SoundType.questComplete      => ('quest_done.wav',             _lvlConfirm),
    SoundType.levelUp            => ('levelup_newV2.wav',          _lvlLevelUp),
    SoundType.purchaseSuccess    => ('purchase.wav',               _lvlConfirm),
    SoundType.saveConfirm        => ('save.wav',                   _lvlConfirm),
    SoundType.actionError        => (null,                         _lvlButton),
    SoundType.shopTabSwitch      => ('store_tab_switch.wav',       _lvlNavTap),
    SoundType.itemSwitchTick     => ('item_switch_tick.wav',       _lvlNavTap),
    SoundType.tabSwitchCustomize => ('tab_switch_customize.wav',   _lvlNavTap),
    SoundType.questDisplay       => ('quest_display.wav',          _lvlButton),
    SoundType.questEdit          => ('quest_edit.wav',             _lvlButton),
    SoundType.addQuest           => ('add_quest.wav',              _lvlConfirm),
    SoundType.ongoingQuest       => ('ongoing_quest.wav',          _lvlConfirm),
    SoundType.awesome            => ('awesome.wav',                _lvlConfirm),
    SoundType.menuCleaning       => ('menu_open_cleaning.wav',     _lvlMenuOpenLow),
    SoundType.menuGroceries      => ('menu_open_groceries.wav',    _lvlMenuOpen),
    SoundType.menuBills          => ('menu_open_bills.wav',        _lvlMenuOpenLow),
    SoundType.menuLaundry        => ('laundry_category.wav',       _lvlMenuOpenLow),
    SoundType.sonicLogo          => (null,                         _lvlConfirm),
  };

  // ─── Internal ────────────────────────────────────────────────

  void _fadeBg(double target, int durationMs, {void Function()? onComplete}) {
    _fadeTimer?.cancel();
    final from = _currentBgVol;
    const steps = 24;
    final stepMs = (durationMs / steps).round().clamp(4, 200);
    var step = 0;

    _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      step++;
      final vol = (from + (target - from) * step / steps).clamp(0.0, 1.0);
      _currentBgVol = vol;
      _bg.setVolume(vol);
      if (step >= steps) {
        timer.cancel();
        _fadeTimer = null;
        onComplete?.call();
      }
    });
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _fadeTimer?.cancel();
    _debounce?.cancel();
    await _sfx.dispose();
    await _bg.dispose();
    await _logo.dispose();
  }
}
