import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sound_service.dart';
import 'game_providers.dart';

class AudioSettingsNotifier extends Notifier<AudioSettings> {
  @override
  AudioSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AudioSettings(
      musicVolume: prefs.getDouble(AudioSettings.kMusicVol) ?? 1.0,
      sfxVolume:   prefs.getDouble(AudioSettings.kSfxVol)   ?? 1.0,
      musicMuted:  prefs.getBool(AudioSettings.kMusicMute)  ?? false,
      sfxMuted:    prefs.getBool(AudioSettings.kSfxMute)    ?? false,
    );
  }

  void _update(AudioSettings next) {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setDouble(AudioSettings.kMusicVol,  next.musicVolume);
    prefs.setDouble(AudioSettings.kSfxVol,    next.sfxVolume);
    prefs.setBool(AudioSettings.kMusicMute,   next.musicMuted);
    prefs.setBool(AudioSettings.kSfxMute,     next.sfxMuted);
    ref.read(soundServiceProvider).applySettings(next);
  }

  void toggleMusicMute() => _update(state.copyWith(musicMuted: !state.musicMuted));
  void toggleSfxMute()   => _update(state.copyWith(sfxMuted: !state.sfxMuted));
  void setMusicVolume(double v) => _update(state.copyWith(musicVolume: v.clamp(0.0, 1.0)));
  void setSfxVolume(double v)   => _update(state.copyWith(sfxVolume: v.clamp(0.0, 1.0)));
}

final audioSettingsProvider = NotifierProvider<AudioSettingsNotifier, AudioSettings>(
  AudioSettingsNotifier.new,
);
